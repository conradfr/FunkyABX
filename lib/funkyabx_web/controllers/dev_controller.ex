defmodule FunkyABXWeb.DevController do
  use FunkyABXWeb, :controller

  # TODO cors for dev on cloud
  # Edit: done but not used yet

  def redirect_file(conn, %{"part1" => part1, "part2" => part2} = _params) do
    Plug.Conn.send_file(conn, 200, "priv/static/uploads/#{part1}/#{part2}")
  end
end
