defmodule FunkyABX.Urls do
  @parsers ["gearspace_thread", "other_url"]
  @headers ["gearspace_headers", "other_headers"]
  @timeout 300_000

  # ---------- URLS ----------

  def parse_url_tracks(url) do
    with true <- valid_url?(url) do
      Enum.reduce_while(@parsers, nil, fn parser, _acc ->
        parser
        |> String.to_atom()
        |> (&Kernel.apply(__MODULE__, &1, [url])).()
      end)
    else
      _ -> nil
    end
  end

  def gearspace_thread(url) do
    if String.starts_with?(url, "https://gearspace.com/board/showpost.php") do
      {:halt, gearspace_thread_to_urls(url)}
    else
      {:cont, url}
    end
  end

  def other_url(url) do
    {:halt, url}
  end

  # ---------- HEADERS ----------

  def get_headers_for_url(url) do
    Enum.reduce_while(@headers, nil, fn parser, _acc ->
      parser
      |> String.to_atom()
      |> (&Kernel.apply(__MODULE__, &1, [url])).()
    end)
  end

  def gearspace_headers(url) do
    if String.starts_with?(url, "https://gearspace.com/") do
      {:halt,
       [
         {"Authorization", "Bearer " <> Application.fetch_env!(:funkyabx, :fetcher_token)}
       ]}
    else
      {:cont, url}
    end
  end

  def other_headers(url) do
    {:halt,
     [
       {"Cache-Control", "no-cache"},
       {"Pragma", "no-cache"},
       {"Referer", url},
       {"Accept-Language", "fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3"},
       {"User-Agent",
        "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0"}
     ]}
  end

  # ---------- INTERNAL ----------

  defp valid_url?(url) when is_binary(url) do
    url_parsed =
      url
      |> URI.encode()
      |> URI.new()

    case url_parsed do
      {:error, _} -> false
      _ -> true
    end
  end

  defp valid_url?(_url), do: false

  defp gearspace_thread_to_urls(url) do
    try do
      HTTPoison.get!(
        Application.fetch_env!(:funkyabx, :fetcher_url) <> "/fetch-html?url=" <> URI.encode(url),
        get_headers_for_url(url),
        timeout: @timeout,
        recv_timeout: @timeout,
        hackney: [:insecure]
      )
      |> IO.inspect()
      |> Map.get(:body, "")
      |> IO.inspect()
      |> Floki.parse_document!()
      |> Floki.find("p > a")
      |> IO.inspect()
      |> Enum.map(fn x ->
        file =
          x
          |> elem(1)
          |> hd()
          |> elem(1)

        title =
          x
          |> elem(2)
          |> hd()

        {title, "https://gearspace.com/" <> file}
      end)
    rescue
      e -> nil
    end
  end
end
