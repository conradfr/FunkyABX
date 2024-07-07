defmodule FunkyABXWeb.Plugs.Embed do
  import Plug.Conn
  alias Phoenix.Controller

  def init(options), do: options

  # put a barebone layout if embed parameter is passed
  def call(conn, _opts) do
    case Map.get(conn.params, "embed", nil) do
      "1" ->
        conn
        |> Controller.put_root_layout({FunkyABXWeb.Layouts, "embed.html"})
        |> delete_resp_header("x-frame-options")
        |> put_resp_header("content-security-policy", "frame-ancestors *")

      _ ->
        conn
    end
  end
end
