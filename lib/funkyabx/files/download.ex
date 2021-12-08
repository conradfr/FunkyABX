defmodule FunkyABX.Download do
  require Logger

  @timeout 300_000

  def from_url(url) do
    file_path = local_path(url)
    {:ok, fd} = File.open(file_path , [:write, :binary])

    try do
      resp = url
      |> HTTPoison.get!(%{},
        stream_to: self(),
        async: :once,
        timeout: @timeout,
        recv_timeout: @timeout,
        hackney: [pool: :checker, insecure: true]
      )

      async_download = fn(resp, fd, download_fn) ->
        resp_id = resp.id

        receive do
          %HTTPoison.AsyncStatus{code: status_code, id: ^resp_id} ->
            HTTPoison.stream_next(resp)
            download_fn.(resp, fd, download_fn)

          %HTTPoison.AsyncHeaders{headers: headers, id: ^resp_id} ->
            HTTPoison.stream_next(resp)
            download_fn.(resp, fd, download_fn)

          %HTTPoison.AsyncChunk{chunk: chunk, id: ^resp_id} ->
            IO.binwrite(fd, chunk)
            HTTPoison.stream_next(resp)
            download_fn.(resp, fd, download_fn)

          %HTTPoison.AsyncEnd{id: ^resp_id} ->
            File.close(fd)
            {Path.basename(url), file_path}
        end
      end

      async_download.(resp, fd, async_download)
    rescue
      e in HTTPoison.Error ->
        case e.reason do
          reason when is_binary(reason) ->
            Logger.warn("Error (#{url}): #{e.reason}")

          reason when reason == :checkout_timeout ->
            Logger.warn(
              "Error (#{url}): checkout_timeout - restarting pool ..."
            )

            :hackney_pool.stop_pool(:checker)

          reason when is_tuple(reason) ->
            {_error, {_error2, error_message}} = reason
            Logger.warn("Error (#{url}): #{to_string(error_message)}")
        end

        File.close(fd)
        File.rm(file_path)
        nil
    end
  end

  defp local_path(url) do
    url
    |> Path.basename()
    |> (&(Path.join([Application.fetch_env!(:funkyabx, :temp_folder), &1]))).()
  end
end
