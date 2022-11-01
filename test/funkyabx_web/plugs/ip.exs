defmodule FunkyABXWeb.Plugs.IpTest do
  use FunkyABXWeb.ConnCase

  describe "ip address in session" do
    test "ip address is in session", %{conn: conn} do
      conn = get(conn, "/")

      assert conn.state == :sent
      assert get_session(conn, "visitor_ip") == "127.0.0.1"
    end
  end
end
