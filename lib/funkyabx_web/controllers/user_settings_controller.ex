defmodule FunkyABXWeb.UserSettingsController do
  use FunkyABXWeb, :controller

  alias FunkyABXWeb.Router.Helpers, as: Routes

  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.{Accounts, Files}
  alias FunkyABX.Accounts.UserNotifier
  alias FunkyABXWeb.UserAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, ~p"/users/settings")
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "delete_account"} = _params) do
    old_email = conn.assigns.current_user.email
    # Anonymize the account
    case Accounts.delete_account(conn.assigns.current_user, %{"email" => UUID.generate()}) do
      {:ok, user} ->
        UserNotifier.deliver_account_deleted(old_email)
        # Delete audio tracks
        user = Repo.preload(user, :tests)

        user.tests
        |> Enum.filter(fn t -> t.deleted_at == nil end)
        |> Enum.each(fn t ->
          Files.delete_all(t.id)
        end)

        conn
        |> put_flash(:info, "Your account has been successfully deleted.")
        |> UserAuth.log_out_user()
        |> redirect(~p"/")

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:delete_changeset, Accounts.change_delete_account(user))
  end
end
