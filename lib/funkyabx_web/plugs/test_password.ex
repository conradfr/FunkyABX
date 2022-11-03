defmodule FunkyABXWeb.Plugs.TestPassword do
  import Plug.Conn
  alias FunkyABXWeb.Router.Helpers, as: Routes
  alias FunkyABX.Tests

  @cookie_prefix "token_test_"

  def init(options), do: options

  def call(conn, _opts) do
    test = Tests.get_by_slug(conn.params["slug"])
    current_user_id = get_session(conn, "current_user_id")

    password_token =
      cond do
        test == nil ->
          nil

        Map.get(conn.cookies, @cookie_prefix <> test.id) != nil ->
          Base.decode64!(Map.get(conn.cookies, @cookie_prefix <> test.id))

        get_session(conn, @cookie_prefix <> test.id) != nil ->
          Base.decode64!(get_session(conn, @cookie_prefix <> test.id))

        true ->
          nil
      end

    case test do
      # not found
      test when is_nil(test) or not is_nil(test.deleted_at) ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.put_view(FunkyABXWeb.ErrorView)
        |> Phoenix.Controller.render(:"404")
        |> halt()

      # no password or already given
      test when test.password_enabled == false or password_token == test.password ->
        conn

      test when test.user_id != nil and current_user_id == test.user_id ->
        conn

      # password needed, redirect
      _ ->
        conn
        |> Phoenix.Controller.redirect(to: Routes.test_path(conn, :password, test.slug))
        |> halt()
    end
  end
end
