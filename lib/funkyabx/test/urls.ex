defmodule FunkyABX.Urls do
  @parsers ["gearspace_thread", "other_url"]
  @headers ["gearspace_headers", "other_headers"]

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
         {"User-Agent",
          "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:109.0) Gecko/20100101 Firefox/116.0"},
         {"Accept",
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"},
         {"Accept-Language", "fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3"},
         {"Alt-Used", "gearspace.com"},
         {"Connection", "keep-alive"},
         {"Cookie",
          "__cf_bm=E4vsZNxORSkodOVtEHJV1ejTCloDUWoLYklp4MX1.fU-1710697793-1.0.1.1-.H.0Wg6XmJuWFx3MvlCPK_IZCMkCXPPxNa2CYYSh2siahcpjss__bzLnP9oGu4R6kozoKred1TglnRxn1WGBtA; PHPSESSID=clvajt6mf5b4fhv2ggd6vrlp33; bbsessionhash=08c0cba7f3127e529501f78bfc00c9ff; bblastvisit=1710697795; bblastactivity=0"},
         {"Upgrade-Insecure-Requests", "1"},
         {"Sec-Fetch-Dest", "document"},
         {"Sec-Fetch-Mode", "navigate"},
         {"Sec-Fetch-Site", "none"},
         {"Sec-Fetch-User", "?1"},
         {"Cache-Control", "no-cache"},
         {"Pragma", "no-cache"},
         {"Referer", "https://gearspace.com/"}
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
        url,
        get_headers_for_url(url),
        hackney: [:insecure]
      )
      |> Map.get(:body, "")
      |> Floki.parse_document!()
      |> Floki.find("p > a")
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
      _ -> nil
    end
  end
end
