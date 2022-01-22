defmodule FunkyABXWeb.TestController do
  use FunkyABXWeb, :controller
  alias FunkyABX.Tests

  @cookie_prefix "token_test_"

  def password(conn, %{"slug" => slug}) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         false <- is_nil(test.password),
         nil <- test.deleted_at do
      render(conn, "password.html", test: test)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.put_view(FunkyABXWeb.ErrorView)
        |> Phoenix.Controller.render(:"404")
        |> halt()
    end
  end

  def password_verify(
        conn,
        %{"slug" => slug, "password" => password, "referer" => referer} = _params
      ) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         false <- is_nil(test.password),
         nil <- test.deleted_at do
      if Pbkdf2.verify_pass(password, test.password) do
        conn
        |> put_session(@cookie_prefix <> test.id, Base.encode64(test.password))
        |> put_resp_cookie(@cookie_prefix <> test.id, Base.encode64(test.password))
        |> redirect(to: referer)
      else
        render(conn, "password.html", test: test, error_message: "Wrong password :(")
      end
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> Phoenix.Controller.put_view(FunkyABXWeb.ErrorView)
        |> Phoenix.Controller.render(:"404")
        |> halt()
    end
  end

  #      if user = Accounts.get_user_by_email_and_password(email, password) do
  #        UserAuth.log_in_user(conn, user, user_params)
  #      else
  #        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
  #        render(conn, "new.html", error_message: "Invalid email or password")
  #      end
end
