defmodule FunkyABX.Tracks do
  alias FunkyABX.{Test, Track, Files, Download}

  # ---------- EXPORT ----------

  def to_json(tracks, %Test{} = test) do
    tracks
    |> Enum.map(fn t ->
      %{
        id: t.id,
        url: get_media_url(t, test),
        hash: t.hash,
        local: t.local
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
    |> Enum.map(&prep_track/1)
  end

  def prep_track(%Track{} = track) do
    fake_id = :rand.uniform(1_000_000)

    %{
      track
      | fake_id: fake_id,
        hash: get_track_hash(track, fake_id)
    }
  end

  def get_track_hash(%Track{} = track, fake_id \\ nil) do
    track_fake_id = Map.get(track, :fake_id) || fake_id

    :md5
    |> :crypto.hash(track.id <> track.filename <> Integer.to_string(track_fake_id))
    |> Base.encode16()
  end

  def get_track_url(track_id, %Test{} = test) do
    track_id
    |> find_track(test.tracks)
    |> get_media_url(test)
  end

  def get_media_url(%Track{} = track, %Test{} = test) do
    Application.fetch_env!(:funkyabx, :cdn_prefix) <> test.id <> "/" <> track.filename
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

  def import_track_url(track, test_id, normalization) do
    task = Task.Supervisor.async(FunkyABX.TaskSupervisor, Download, :from_url, [track["url"]])
    result = Task.await(task)

    case result do
      {original_filename, download_path} ->
        filename_dest =
          track
          |> Map.get("url")
          |> Files.get_destination_filename()
          |> (&Path.join([test_id, &1])).()

        final_filename_dest = Files.save(download_path, filename_dest, normalization)
        File.rm(download_path)

        Map.merge(track, %{
          "url" => track["url"],
          "filename" => final_filename_dest,
          "original_filename" => original_filename,
          "title" => url_to_title(track["url"], Map.get(track, "title"))
        })

      _ ->
        track
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
