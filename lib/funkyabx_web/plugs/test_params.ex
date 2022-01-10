defmodule FunkyABXWeb.Plugs.TestParams do
  import Plug.Conn

  @cookie_author "funkyabx_test_author"

  def init(options), do: options

  def call(conn, _opts) do
    case Map.get(conn.cookies, @cookie_author, nil) do
      nil -> conn
      name -> put_session(conn, "author", name)
    end
  end
end
