defmodule InvitationComponent do
  use FunkyABXWeb, :live_component

  alias FunkyABX.{Test, Invitations, Invitation}
  alias FunkyABX.Accounts.User

  @email_regex ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i

  attr :test, Test, required: true
  attr :user, User, required: false, default: nil

  def render(assigns) do
    ~H"""
    <div>
      <div class="input-group mt-1">
        <input type="text" class="form-control w-25" placeholder="Name or email" aria-label="Send to this email" aria-describedby="button--name_or_email"
          phx-keyup="name_or_email_text" phx-target={@myself}>
        <button class={"btn btn-secondary#{if @name_or_email == "", do: " disabled"}"} id="button-name_or_email" type="button"
          phx-click="name_or_email_submit" phx-target={@myself}>Send</button>
      </div>
      <div class="form-text">An email will be sent if you enter a valid address, otherwise an invitation link will be generated. Use , to separate multiple name/address.</div>
      <hr>
      <table class="table table-sm table-borderless" :if={length(@test.invitations) > 0}>
        <thead class="text-center">
          <tr>
            <th>Name or email</th>
            <th class="w-15">Link</th>
            <th class="w-15">Clicked</th>
            <th class="w-15">Taken</th>
          </tr>
        </thead>
        <tbody class="table-group-divider">
          <tr :for={invitation <- @test.invitations}>
            <td><%= invitation.name_or_email %></td>
            <td class="text-center">
              <a href={Routes.test_public_url(@socket, FunkyABXWeb.TestLive, @test.slug, i: invitation.id)}><i class="bi bi-share"></i></a>
            </td>
            <td class="text-center">
              <%= if invitation.clicked == true do %>
                <i class="bi bi-check"></i>
              <% else %>
                <span class="text-muted">-</span>
              <% end %>
            </td>
            <td class="text-center">
              <%= if invitation.test_taken == true do %>
                <i class="bi bi-check"></i>
              <% else %>
                <span class="text-muted">-</span>
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
      <div :if={length(@test.invitations) == 0}>No invitation sent yet.</div>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     assign(socket, %{
      name_or_email: ""
     })}
  end

  def handle_event("name_or_email_text", %{"value" => value}, socket) do
    {:noreply, assign(socket, %{name_or_email: value})}
  end

  def handle_event("name_or_email_submit", _params, socket) when socket.assigns.name_or_email == "" do
    {:noreply, socket}
  end

  def handle_event("name_or_email_submit", _params, socket) do
    socket.assigns.name_or_email
    |> String.split(",")
    |> Enum.each(fn name_or_email ->
      with %Invitation{} = invitation <- Invitations.add(socket.assigns.test, name_or_email) do
        if Regex.run(@email_regex , invitation.name_or_email) != nil do
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
