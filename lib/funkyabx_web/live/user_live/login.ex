defmodule FunkyABXWeb.UserLive.Login do
  use FunkyABXWeb, :live_view

  alias FunkyABX.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app_alert flash={@flash}>
      <h2 class="header-chemyretro">{dgettext("user", "Log in")}</h2>

      <div :if={local_mail_adapter?()} class="alert alert-info">
        <.icon name="hero-information-circle" class="size-6 shrink-0" />
        <div>
          <p>You are running the local mail adapter.</p>
          <p>
            To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
          </p>
        </div>
      </div>

      <div class="row">
        <div class="col-12 col-sm-6">
          <.form
            :let={f}
            for={@form}
            id="login_form_password"
            action={~p"/users/log-in"}
            phx-submit="submit_password"
            phx-trigger-action={@trigger_submit}
          >
            <div class="mb-3">
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label={dgettext("user", "Email")}
                autocomplete="username"
                required
              />
            </div>
            <div class="mb-3">
              <.input
                field={@form[:password]}
                type="password"
                label={dgettext("user", "Password")}
                autocomplete="current-password"
              />
            </div>
            <div class="mb-3">
              <.input
                field={f[:remember_me]}
                type="checkbox"
                label={dgettext("user", "Remember me")}
              />
            </div>
            <div class="mb-3">
              <.button class="btn btn-primary">
                {dgettext("user", "Log in")}
              </.button>
            </div>
          </.form>

          <hr class="mt-4 mb-3" />

          <.form
            :let={f}
            for={@form}
            id="login_form_magic"
            action={~p"/users/log-in"}
            phx-submit="submit_magic"
          >
            <div class="mb-3">
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label={dgettext("site", "Email")}
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
              />
            </div>
            <.button class="btn btn-primary w-full">
              {dgettext("user", "Log in with link in email")} <span aria-hidden="true">→</span>
            </.button>
          </.form>

          <p class="mt-5">
            <.link href={~p"/users/register"}>
              {dgettext("user", "Don't have an account? Register here")}
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app_alert>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(
       :success,
       dgettext(
         "user",
         "If your email is in our system, you will receive instructions for logging in shortly"
       )
     )
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:funkyabx, FunkyABX.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
