defmodule FunkyABXWeb.Plugs.TestParams do
  import Plug.Conn

  @cookie_author "author"

  # TODO better generic code

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> then(fn conn ->
      case Map.get(conn.cookies, @cookie_author, nil) do
        nil -> conn
        name -> put_session(conn, "author", name)
      end
    end)
    |> then(fn conn ->
      case Map.get(conn.cookies, "identification", nil) do
        value when value in ["true", "false"] ->
          put_session(conn, "identification", value == "true")

        _ ->
          conn
      end
    end)
    |> then(fn conn ->
      case Map.get(conn.cookies, "rating", nil) do
        value when value in ["true", "false"] -> put_session(conn, "rating", value == "true")
        _ -> conn
      end
    end)
    |> then(fn conn ->
      case Map.get(conn.cookies, "regular_type", nil) do
        value when is_binary(value) -> put_session(conn, "regular_type", String.to_atom(value))
        _ -> conn
      end
    end)
  end
end
