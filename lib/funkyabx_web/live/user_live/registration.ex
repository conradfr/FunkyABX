defmodule FunkyABXWeb.UserLive.Registration do
  use FunkyABXWeb, :live_view

  alias FunkyABX.Accounts
  alias FunkyABX.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app_alert flash={@flash}>
      <h2 class="header-chemyretro mb-3">{dgettext("user", "Sign in")}</h2>
      <p class="mb-3">
        {dgettext("user", "Already registered?")}
        <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
          {dgettext("user", "Log in to your account now.")}
        </.link>
      </p>

      <div class="row">
        <div class="col-12 col-sm-6">
          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <div class="mb-3">
              <.input
                field={@form[:email]}
                type="email"
                label={dgettext("user", "Email")}
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
              />
            </div>
            <div class="mb-3">
              <.input
                field={@form[:password]}
                type="password"
                label={dgettext("user", "Password")}
                autocomplete="username"
                required
              />
            </div>
            <div class="mb-3">
              <.input
                field={@form[:password_confirmation]}
                type="password"
                label={dgettext("user", "Confirm password")}
                autocomplete="username"
                required
              />
            </div>

            <div class="mb-3">
              <.button phx-disable-with="Creating account..." class="btn btn-primary">
                {dgettext("user", "Create an account")}
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app_alert>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: FunkyABXWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Your account has been registered"
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
