defmodule FunkyABXWeb.Plugs.Ip do
  import Plug.Conn
  alias FunkyABX.Utils

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> put_session("visitor_ip", Utils.get_ip_as_binary(conn.remote_ip))
  end
end
