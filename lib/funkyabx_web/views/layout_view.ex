defmodule FunkyABXWeb.LayoutView do
  use FunkyABXWeb, :view
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test
  alias FunkyABX.Tests

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  @limit 11

  defp get_tests(%{assigns: %{current_user: current_user}} = _conn)
       when not is_nil(current_user) do
    Tests.get_of_user(current_user, @limit)
  end

  # todo move the query in another module and cache it
  defp get_tests(conn) do
    ids =
      conn.cookies
      |> Enum.reduce([], fn {k, c}, acc ->
        case String.starts_with?(k, "test_") do
          true -> [String.slice(k, 5, 36) | [c | acc]]
          false -> acc
        end
      end)

    test_ids = Enum.take_every(ids, 2)
    access_key_ids = ids -- test_ids

    query =
      from(t in Test,
        where: t.id in ^test_ids and t.access_key in ^access_key_ids and is_nil(t.deleted_at),
        order_by: [desc: t.inserted_at],
        limit: @limit,
        select: t
      )

    Repo.all(query)
  end
end
