defmodule FunkyABXWeb.TestController do
  require Logger
  use FunkyABXWeb, :controller

  alias FunkyABX.{Tests, Files}
  alias FunkyABX.Test
  alias FunkyABX.Tests.Image

  @cookie_prefix "token_test_"

  def password(conn, %{"slug" => slug}) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         false <- is_nil(test.password),
         nil <- test.deleted_at do
      render(conn, :password, test: test)
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
        render(conn, :password, test: test, error_message: "Wrong password :(")
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

  def image(conn, %{"filename" => filename} = _paramss) do
    with session_short_id <- Path.basename(filename, ".png"),
         session_id when is_binary(session_id) <- Tests.parse_session_id(session_short_id),
         %Test{} = test <- Tests.find_from_session_id(session_id) do
      dest_path = Image.get_path_of_img(test, session_id, filename)

      unless Image.exists?(test, session_id, filename) do
        img_path = Image.generate(test, session_id)
        Files.save(img_path, dest_path, [{:content_type, "image/png"}])
        File.rm(img_path)
      end

      img_url = Path.join([Application.fetch_env!(:funkyabx, :cdn_prefix), dest_path])
      redirect(conn, external: img_url)
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
