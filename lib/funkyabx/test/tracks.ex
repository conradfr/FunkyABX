defmodule FunkyABX.Tracks do
  require Logger

  alias FunkyABX.{Test, Track}
  alias FunkyABX.{Files, Download}

  @download_task_timeout 300_000
  @download_flor_local_expiration_days 1

  # ---------- EXPORT ----------

  def to_json(tracks, %Test{} = test) do
    tracks
    |> Enum.map(fn t ->
      %{
        id: t.id,
        url: get_media_url(t, test),
        hash: t.hash,
        local: t.local,
        reference_track: t.reference_track
      }
      # keep id only for local tests (to avoid cheating)
      |> Kernel.then(fn
        t when t.local == true -> t
        t -> Map.drop(t, [:id])
      end)
    end)
    |> Jason.encode!()
  end

  # ---------- UTILS ----------

  def prep_tracks(tracks, _test) when is_list(tracks) do
    tracks
    |> Enum.map(&prep_track(&1))
  end

  # from result page
  def prep_tracks(tracks, _test, _tracks_order) when is_list(tracks) do
    tracks
    |> Enum.map(&prep_track(&1, true))
  end

  def prep_track(%Track{} = track, no_fake_id \\ false) do
    fake_id =
      if no_fake_id == true do
        track.id
      else
        :rand.uniform(1_000_000)
      end

    %{
      track
      | fake_id: fake_id,
        hash: get_track_hash(track, fake_id)
    }
  end

  def get_track_hash(%Track{} = track, fake_id \\ nil) do
    track_fake_id =
      (Map.get(track, :fake_id) || fake_id)
      |> case do
        fake_id when is_binary(fake_id) -> fake_id
        fake_id when is_integer(fake_id) -> Integer.to_string(fake_id)
        nil -> ""
      end

    :md5
    |> :crypto.hash(track.id <> track.filename <> track_fake_id)
    |> Base.encode16()
  end

  def get_track_url(track_id, %Test{} = test) do
    track_id
    |> find_track(test.tracks)
    |> get_media_url(test)
  end

  def get_media_url(%Track{} = track, %Test{} = _test) when track.local_url == true do
    Path.join([
      Application.fetch_env!(:funkyabx, :cdn_prefix),
      Application.fetch_env!(:funkyabx, :local_url_folder),
      track.filename
    ])
  end

  def get_media_url(%Track{} = track, %Test{} = test) do
    Path.join([
      Application.fetch_env!(:funkyabx, :cdn_prefix),
      test.id,
      track.filename
    ])
  end

  def find_track(track_id, tracks) when is_list(tracks) do
    Enum.find(tracks, fn t ->
      t.id == track_id
    end)
  end

  def find_track_id_from_fake_id(fake_id, tracks) when is_list(tracks) do
    tracks
    |> Enum.find(fn x -> x.fake_id == fake_id end)
    |> Map.get(:id)
  end

  def find_fake_id_from_track_id(track_id, tracks) when is_list(tracks) do
    tracks
    |> Enum.find(fn x -> x.id == track_id end)
    |> Map.get(:fake_id)
  end

  def url_to_title(url, initial_value \\ nil)

  def url_to_title(_url, initial_value) when is_binary(initial_value) and initial_value != "",
    do: initial_value

  def url_to_title(url, _initial_value) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> URI.decode()
    |> Path.basename()
    |> filename_to_title()
  end

  def filename_to_title(filename, initial_value \\ nil)

  def filename_to_title(_filename, initial_value)
      when is_binary(initial_value) and initial_value != "",
      do: initial_value

  def filename_to_title(filename, _initial_value) when is_binary(filename) do
    filename
    |> String.replace_suffix(Path.extname(filename), "")
    |> String.replace("_", " ")
    |> :string.titlecase()
  end

  def import_url_for_local(track) do
    final_filename =
      track
      |> Map.get("original_filename")
      |> Download.clean_url()
      |> Files.filename_to_flac_if_needed()
      |> Files.get_destination_filename_for_local_url()

    filename_dest =
      final_filename
      |> (&Path.join([Application.fetch_env!(:funkyabx, :local_url_folder), &1])).()

    if Files.is_cached?(final_filename) do
      Logger.info("File is cached")

      Map.merge(track, %{
        "url" => track["url"],
        "filename" => final_filename,
        "title" => url_to_title(track["url"], Map.get(track, "title"))
      })
    else
      try do
        task =
          Task.Supervisor.async(FunkyABX.TaskSupervisor, Download, :from_url, [
            track["original_filename"]
          ])

        result = Task.await(task, @download_task_timeout)

        case result do
          {original_filename, download_path} ->
            final_filename_dest =
              Files.save(download_path, filename_dest,
                expires: @download_flor_local_expiration_days
              )

            File.rm(download_path)

            Map.merge(track, %{
              "url" => track["url"],
              "filename" => final_filename_dest,
              "original_filename" => original_filename,
              "title" => url_to_title(track["url"], Map.get(track, "title"))
            })

          _ ->
            :error
        end
      rescue
        _ ->
          Logger.warning("Download task error: #{track["original_filename"]}")
          :error
      catch
        :exit, _ ->
          Logger.warning("Download task error: #{track["original_filename"]}")
          :error
      end
    end
  end

  def import_track_url(track, test_id, normalization) do
    try do
      task = Task.Supervisor.async(FunkyABX.TaskSupervisor, Download, :from_url, [track["url"]])
      result = Task.await(task, @download_task_timeout)

      case result do
        {original_filename, download_path} ->
          filename_dest =
            track
            |> Map.get("url")
            |> Download.clean_url()
            |> Files.get_destination_filename()
            |> (&Path.join([test_id, &1])).()

          final_filename_dest = Files.save(download_path, filename_dest, [], normalization)
          File.rm(download_path)

          Map.merge(track, %{
            "url" => track["url"],
            "filename" => final_filename_dest,
            "original_filename" => original_filename,
            "title" => url_to_title(track["url"], Map.get(track, "title"))
          })

        _ ->
          :error
      end
    rescue
      _ ->
        Logger.warning("Download task error: #{track["url"]}")
        :error
    catch
      :exit, _ ->
        Logger.warning("Download task error: #{track["url"]}")
        :error
    end
  end

  # tracks with base64 data
  def parse_and_import_tracks_from_api(
        %{"data" => data, "filename" => filename} = track_params,
        test_id,
        normalization
      )
      when is_binary(data) and is_binary(filename) do
    {:ok, track_data} = Base.decode64(data)

    temp_path = Path.join([Application.fetch_env!(:funkyabx, :temp_folder), filename])

    {:ok, file} = File.open(temp_path, [:write, :binary])
    IO.binwrite(file, track_data)
    File.close(file)

    filename_dest = Files.get_destination_filename(filename)

    final_filename_dest =
      Files.save(
        temp_path,
        Path.join([test_id, filename_dest]),
        [],
        normalization
      )

    File.rm(temp_path)

    Map.merge(track_params, %{
      "filename" => final_filename_dest,
      "original_filename" => filename,
      "title" => filename_to_title(filename, Map.get(track_params, "title"))
    })
  end

  # tracks with url
  def parse_and_import_tracks_from_api(
        %{"url" => url, "filename" => filename} = track_params,
        test_id,
        normalization
      )
      when is_binary(url) and is_binary(filename) do
    track_params
    |> import_track_url(test_id, normalization)
  end
end
