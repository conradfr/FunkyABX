defmodule FunkyABXWeb.PageView do
  use FunkyABXWeb, :view
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test

  defp get_tests_total() do
    query =
      from(t in Test,
        select: count(t.id)
      )

    Repo.one(query)
  end

  defp format_date(datetime) do
    {:ok, date_string} = Cldr.DateTime.to_string(datetime, format: :short)
    date_string
  end
end
