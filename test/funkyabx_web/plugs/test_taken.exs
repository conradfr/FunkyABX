defmodule FunkyABXWeb.Plugs.IpTest do
  use FunkyABXWeb.ConnCase
  import FunkyABX.Factory

  describe "test already taken or not" do
    test "test does not exist", %{conn: conn} do
      conn = get(conn, "/test/stupid-slug")

      assert conn.state == :sent
      assert html_response(conn, 404) =~ "deleted"
    end

    test "test exists and not taken", %{conn: conn} do
      test = insert(:test, tracks: [])
      conn = get(conn, "/test/#{test.slug}")

      assert conn.state == :sent
      assert html_response(conn, 200)
      assert get_session(conn, "test_taken_" <> test.slug) == false
    end

    test "test exists and taken", %{conn: conn} do
      test = insert(:test, tracks: [])
      conn =
        conn
        |> put_req_cookie("funkyabx_test_taken_" <> test.id, "true")
        |> get("/test/#{test.slug}")

      assert conn.state == :sent
      assert html_response(conn, 200)
      assert get_session(conn, "test_taken_" <> test.slug) == true
    end
  end
end
