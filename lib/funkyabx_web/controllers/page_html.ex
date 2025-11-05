defmodule FunkyABXWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use FunkyABXWeb, :html
  use PhoenixHTMLHelpers

  import Ecto.Query, only: [from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.{Test, Stats}

  @default_max_length 150

  embed_templates "page_html/*"

  defp get_tests_total() do
    query =
      from(t in Test,
        select: count(t.id)
      )

    test_count = Repo.one(query)

    local_query =
      from(s in Stats,
        select: s.counter,
        where: s.name == "local_test"
      )

    local_test_count =
      case Repo.one(local_query) do
        nil -> 0
        count -> count
      end

    {test_count, local_test_count, test_count + local_test_count}
  end

  defp text_max_length(text, max_length \\ @default_max_length) when is_binary(text) do
    unless String.length(text) < max_length do
      String.slice(text, 0, max_length) <> " (…)"
    else
      text
    end
  end
end
