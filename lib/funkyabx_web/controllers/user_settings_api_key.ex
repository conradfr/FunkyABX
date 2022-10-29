defmodule FunkyABXWeb.UserSettingsApiKeyController do
  use FunkyABXWeb, :controller
  import Ecto.Query, warn: false, only: [from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.ApiKey
  alias FunkyABX.Accounts

  def index(conn, _params) do
    user = conn.assigns.current_user
    api_keys = Accounts.get_api_keys_of_user(user)
    changeset = ApiKey.changeset(%ApiKey{}, %{})

    render(conn, :index,
      changeset: changeset,
      api_keys: api_keys
    )
  end

  def generate(conn, _params) do
    user = conn.assigns.current_user

    insert =
      %ApiKey{user: user}
      |> ApiKey.changeset()
      |> Repo.insert()

    case insert do
      {:ok, _} ->
        conn
        |> put_flash(:info, "An new api key has been added to your account.")

      _ ->
        conn
        |> put_flash(:error, "An error occurred, please try again.")
    end
    |> redirect(to: "/users/settings/api_key")
  end

  def delete(conn, %{"key" => api_key} = _params) do
    user = conn.assigns.current_user

    delete =
      ApiKey
      |> Repo.get_by(id: api_key, user_id: user.id)
      |> Repo.delete()

    case delete do
      {:ok, _} ->
        conn
        |> put_flash(:info, "This key has been deleted.")

      _ ->
        conn
        |> put_flash(:error, "An error occurred, please try again.")
    end
    |> redirect(to: "/users/settings/api_key")
  end
end
