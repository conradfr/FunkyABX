defmodule FunkyABXWeb.Plugs.TestTaken do
  import Plug.Conn
  alias FunkyABX.Tests

  @cookie_prefix "test_taken_"

  def init(options), do: options

  def call(conn, _opts) do
    test = Tests.get_by_slug(conn.params["slug"])

    case test do
      nil ->
        # todo check layout
        conn
        |> Phoenix.Controller.render(FunkyABXWeb.ErrorView, :"404")
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
