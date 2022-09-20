defmodule FunkyABXWeb.PageView do
  use FunkyABXWeb, :view
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test

  @default_max_length 150

  defp get_tests_total() do
    query =
      from(t in Test,
        select: count(t.id)
      )

    Repo.one(query)
  end

  defp text_max_length(text, max_length \\ @default_max_length) when is_binary(text) do
    unless String.length(text) < max_length do
      String.slice(text, 0, max_length) <> " (…)"
    else
      text
    end
  end
end
