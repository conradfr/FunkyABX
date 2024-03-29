defmodule FunkyABXWeb.PageHTML do
  use FunkyABXWeb, :html

  import Ecto.Query, only: [from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.{Test, Stats}
  alias FunkyABX.Tests

  @default_max_length 150

  embed_templates "page_html/*"

  defp is_test_closed?(%Test{} = test) do
    Tests.is_closed?(test)
  end

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
