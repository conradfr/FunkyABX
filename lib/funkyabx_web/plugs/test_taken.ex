defmodule FunkyABXWeb.Plugs.TestTaken do
  import Plug.Conn
  alias FunkyABX.Tests

  @cookie_prefix "taken_"

  def init(options), do: options

  def call(conn, _opts) do
    test = Tests.get_by_slug(conn.params["slug"])

    case test do
      test when is_nil(test) or not is_nil(test.deleted_at) ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.put_view(FunkyABXWeb.ErrorHTML)
        |> Phoenix.Controller.render(:"404")
        |> halt()

      _ ->
        test_taken =
          conn.cookies
          |> Enum.any?(fn {key, _c} ->
            String.ends_with?(key, @cookie_prefix <> test.id)
          end)

        conn
        |> put_session("test_taken_" <> test.slug, test_taken)
    end
  end
end
