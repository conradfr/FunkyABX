defmodule FunkyABX.Download do
  require Logger
  alias Ecto.UUID

  @timeout 300_000

  def from_url(url, original_url \\ nil) when is_binary(url) do
    Logger.debug("downloading from url: #{url}")

    file_path = local_path(original_url || url)

    {:ok, fd} = File.open(file_path, [:write, :binary])

    try do
      resp =
        url
        |> filter()
        |> URI.decode()
        |> URI.encode()
        |> HTTPoison.get!(%{},
          stream_to: self(),
          async: :once,
          timeout: @timeout,
          recv_timeout: @timeout,
          hackney: [
            # Couldn't get the redirect to work with async so we manage it "manually" below
            # follow_redirect: true,
            # force_redirect: true,
            pool: :checker,
            insecure: true
          ]
        )

      async_download = fn resp, fd, download_fn ->
        resp_id = resp.id

        receive do
          %HTTPoison.AsyncStatus{code: _status_code, id: ^resp_id} ->
            HTTPoison.stream_next(resp)
            download_fn.(resp, fd, download_fn)

          %HTTPoison.AsyncHeaders{headers: headers, id: ^resp_id} ->
            headers_location =
              headers
              |> Map.new()
              |> Map.get("Location")

            case headers_location do
              location when is_binary(location) ->
                File.close(fd)
                File.rm(file_path)

                url
                |> URI.parse()
                |> URI.merge(location)
                |> URI.to_string()
                |> from_url(original_url || url)

              _ ->
                HTTPoison.stream_next(resp)
                download_fn.(resp, fd, download_fn)
            end

          %HTTPoison.AsyncChunk{chunk: chunk, id: ^resp_id} ->
            IO.binwrite(fd, chunk)
            HTTPoison.stream_next(resp)
            download_fn.(resp, fd, download_fn)

          %HTTPoison.AsyncEnd{id: ^resp_id} ->
            File.close(fd)

            {Path.basename(original_url || url), file_path}
        end
      end

      async_download.(resp, fd, async_download)
    rescue
      e in HTTPoison.Error ->
        case e.reason do
          reason when is_binary(reason) ->
            Logger.warn("Error (#{url}): #{e.reason}")

          reason when reason == :checkout_timeout ->
            Logger.warn("Error (#{url}): checkout_timeout - restarting pool ...")

            :hackney_pool.stop_pool(:checker)

          reason when is_tuple(reason) and tuple_size(reason) == 2 ->
            {_error, {_error2, error_message}} = reason
            Logger.warn("Error (#{url}): #{to_string(error_message)}")
        end

        File.close(fd)
        File.rm(file_path)
        nil
    end
  end

  defp local_path(url) when is_binary(url) do
    with %URI{} = url_parsed <- URI.parse(url) do
      url_parsed
      |> Map.get(:path, url)
      |> local_path_compose()
    else
      _ ->
        url
        |> local_path_compose()
    end
  end

  defp local_path_compose(path) do
    path
    |> Path.basename()
    |> (&Path.join([Application.fetch_env!(:funkyabx, :temp_folder), UUID.generate() <> &1])).()
  end

  def clean_url(url) do
    with %URI{} = url_parsed <- URI.parse(url) do
      url_parsed
      |> Map.get(:path, url)
    else
      _ -> url
    end
  end

  def filter(url) do
    url
    |> dropbox()
  end

  defp dropbox(url) do
    cond do
      String.contains?(url, "dropbox.com") === false -> url
      String.contains?(url, "dl=1") === true -> url
      String.contains?(url, "dl=0") === true -> String.replace(url, "dl=0", "dl=1")
      String.contains?(url, "?") === true -> url <> "&dl=1"
      true -> url <> "?dl=1"
    end
  end
end
