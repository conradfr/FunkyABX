defmodule FunkyABX.Download do
  require Logger
  alias Ecto.UUID
  alias FunkyABX.Urls

  @timeout 300_000

  def from_url(url) when is_binary(url) do
    Logger.debug("downloading from url: #{url}")

    file_path = local_path(url)

    clean_url =
      url
      |> filter()
      |> URI.decode()
      |> URI.encode()

    headers = Urls.get_headers_for_url(clean_url)

    clean_url
    |> Req.get(
      headers: headers,
      into: File.stream!(file_path),
      # Retrying would append to the partially written file
      retry: false,
      receive_timeout: @timeout,
      connect_options: [
        timeout: @timeout,
        transport_opts: [verify: :verify_none]
      ]
    )
    |> case do
      {:ok, _resp} ->
        {Path.basename(url), file_path}

      {:error, exception} ->
        Logger.warning("Error (#{url}): #{Exception.message(exception)}")
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
