defmodule FunkyABXWeb.Plugs.EmbedTest do
  use FunkyABXWeb.ConnCase

  describe "embed query option" do
    test "embed is in session", %{conn: conn} do
      conn = get(conn, "/?embed=1")

      assert conn.state == :sent
      assert get_session(conn, "embed") == true
    end

    test "embed is not in session", %{conn: conn} do
      conn = get(conn, "/")

      assert conn.state == :sent
      assert get_session(conn, "embed") == nil
    end
  end
end
