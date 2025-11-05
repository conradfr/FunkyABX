defmodule FunkyABXWeb.UserLive.Settings do
  use FunkyABXWeb, :live_view

  on_mount {FunkyABXWeb.UserAuth, :require_sudo_mode}

  alias FunkyABX.Repo
  alias FunkyABX.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h2 class="mb-4 mt-0 header-chemyretro">{dgettext("user", "Account Settings")}</h2>

      <div class="row">
        <div class="col-12 col-sm-6">
          <h5 class="mb-3 mt-0 header-chemyretro">{dgettext("user", "Change email")}</h5>

          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <div class="mb-3">
              <.input
                field={@email_form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
              />
            </div>
            <div class="mb-3">
              <.button variant="primary" phx-disable-with="Changing...">Change Email</.button>
            </div>
          </.form>

          <hr class="mt-4 mb-3" />

          <h5 class="mb-3 mt-0 header-chemyretro">{dgettext("user", "Change password")}</h5>

          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/update-password"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <div class="mb-3">
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
            </div>
            <div class="mb-3">
              <.input
                field={@password_form[:password]}
                type="password"
                label="New password"
                autocomplete="new-password"
                required
              />
            </div>
            <div class="mb-3">
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Confirm new password"
                autocomplete="new-password"
              />
            </div>
            <div class="mb-3">
              <.button variant="primary" phx-disable-with="Saving...">
                Save Password
              </.button>
            </div>
          </.form>

          <hr class="mt-4 mb-3" />

          <h5 class="mb-3 mt-0 header-chemyretro">{dgettext("user", "Delete account")}</h5>

          <div class="alert alert-warning" role="alert">
            <i class="bi bi-info-circle"></i>&nbsp;&nbsp;{dgettext(
              "user",
              "All your tests, results and audio files will be deleted."
            )}
          </div>

          <button
            type="button"
            class="btn btn-danger"
            data-confirm={
              dgettext(
                "user",
                "Are you sure you want to delete your account and all data associated with?"
              )
            }
            phx-click="delete_account"
          >
            <i class="bi bi-x-circle"></i>&nbsp;&nbsp;{dgettext("test", "Delete account")}
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        case Repo.update(changeset) do
          {:ok, _user} ->
            {:noreply,
             socket
             |> put_flash(:success, dgettext("user", "Your email address has been updated."))}

          {:error, _} ->
            {:noreply,
             socket
             |> put_flash(
               :error,
               dgettext("user", "An error occurred. Your email address has NOT been updated.")
             )}
        end

      changeset ->
        {:noreply,
         socket
         |> assign(:email_form, to_form(changeset, action: :insert))
         |> put_flash(
           :error,
           dgettext("user", "An error occurred. Your email address has NOT been updated.")
         )}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end

  @impl true
  def handle_event("delete_account", _params, socket) do
    %{id: socket.assigns.current_scope.user.id}
    |> FunkyABX.DeleteUserWorker.new()
    |> Oban.insert()

    {:noreply,
     socket
     |> push_navigate(to: ~p"/users/log-out?delete=1")}
  end
end
