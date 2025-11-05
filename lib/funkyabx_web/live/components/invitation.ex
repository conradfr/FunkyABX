defmodule InvitationComponent do
  use FunkyABXWeb, :live_component

  alias FunkyABX.{Test, Invitations, Invitation}
  alias FunkyABX.Accounts.User

  @email_regex ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i

  attr :test, Test, required: true
  attr :user, User, required: false, default: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="input-group mt-1">
        <input
          type="text"
          class="form-control w-25"
          placeholder={
            if @user == nil, do: dgettext("site", "Name"), else: dgettext("site", "Name or email")
          }
          aria-label={
            if @user == nil, do: dgettext("site", "Name"), else: dgettext("site", "Name or email")
          }
          aria-describedby="button--name_or_email"
          phx-keyup="name_or_email_text"
          phx-target={@myself}
        />
        <button
          class={["btn", "btn-secondary", @name_or_email == "" && "disabled"]}
          id="button-name_or_email"
          type="button"
          phx-click="name_or_email_submit"
          phx-target={@myself}
        >
          {dgettext("test", "Generate invitation")}
        </button>
      </div>
      <div :if={@user != nil} class="form-text">
        {dgettext(
          "test",
          "An email will be sent if you enter a valid address, otherwise an invitation link will be generated. Use \",\" to separate multiple names/addresses."
        )}
      </div>
      <div :if={@user == nil} class="form-text">
        {dgettext(
          "test",
          "An invitation link will be generated. Use \",\" to separate multiple names."
        )}
      </div>
      <hr />
      <table
        :if={length(@test.invitations) > 0}
        class="table table-sm mb-0 align-middle table-borderless bg-transparent"
      >
        <thead class="text-center">
          <tr>
            <th :if={@user != nil}>{dgettext("test", "Name or email")}</th>
            <th :if={@user == nil}>{dgettext("test", "Name")}</th>
            <th class="w-15">{dgettext("test", "Link")}</th>
            <th class="w-15">{dgettext("test", "Clicked")}</th>
            <th :if={@test.type != :listening} class="w-15">{dgettext("test", "Taken")}</th>
          </tr>
        </thead>
        <tbody class="table-group-divider">
          <tr :for={invitation <- @test.invitations}>
            <td>{invitation.name_or_email}</td>
            <td class="text-center">
              <button
                class="btn btn-sm btn-info cursor-link"
                title={dgettext("site", "Copy to clipboard")}
                phx-click="clipboard"
                phx-value-text={FunkyABXWeb.Endpoint.url() <> ~p"/test/#{@test.slug}?i=#{ShortUUID.encode!(invitation.id)}"}
              >
                <i class="bi bi-clipboard"></i>
              </button>
            </td>
            <td class="text-center">
              <%= if invitation.clicked == true do %>
                <i class="bi bi-check"></i>
              <% else %>
                <span class="text-body-secondary">-</span>
              <% end %>
            </td>
            <td :if={@test.type != :listening} class="text-center">
              <%= if invitation.test_taken == true do %>
                <a
                  class="btn btn-sm btn-light"
                  target="_blank"
                  title={dgettext("site", "Check results")}
                  href={~p"/results/#{@test.slug}?s=#{invitation.id}"}
                >
                  <i class="bi bi-eye"></i>
                </a>
              <% else %>
                <span class="text-body-secondary">-</span>
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
      <div :if={length(@test.invitations) == 0}>
        {dgettext("test", "No invitation sent yet.")}
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket, %{
       name_or_email: ""
     })}
  end

  @impl true
  def handle_event("name_or_email_text", %{"value" => value}, socket) do
    {:noreply, assign(socket, %{name_or_email: value})}
  end

  @impl true
  def handle_event("name_or_email_submit", _params, socket)
      when socket.assigns.name_or_email == "" do
    {:noreply, socket}
  end

  @impl true
  def handle_event("name_or_email_submit", _params, socket) do
    socket.assigns.name_or_email
    |> String.split(",")
    |> Enum.each(fn name_or_email ->
      with %Invitation{} = invitation <- Invitations.add(socket.assigns.test, name_or_email) do
        if socket.assigns.user != nil and Regex.run(@email_regex, invitation.name_or_email) != nil do
          spawn(fn -> Invitations.send(invitation, socket) end)
        end

        send(self(), :invitations_updated)
        :ok
      else
        _ -> :error
      end
    end)

    {:noreply, assign(socket, %{name_or_email: ""})}
  end
end
