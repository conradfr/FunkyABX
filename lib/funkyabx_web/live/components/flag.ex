defmodule TestFlagComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.Repo
  alias FunkyABX.Flag

  def render(assigns) do
    ~H"""
        <div class="text-end">
          <span class="fs-9 text-muted cursor-link" phx-target={@myself} phx-click="flag_toggle" title="Flag this test"><i class="bi bi-flag"></i></span>
          <%= if @flag_display === true do %>
          <div class="input-group mt-1">
            <input type="text" class="form-control w-25" placeholder="Enter the reason" aria-label="Enter the reason" aria-describedby="button-flag" phx-keyup="flag_text" phx-target={@myself}>
            <button class={"btn btn-secondary#{if @flag_text == "", do: " disabled"}"} type="button" id="button-flag" phx-target={@myself} phx-click="flag_submit" >Flag</button>
        </div>
        <% end %>
      </div>
    """
  end

  def mount(socket) do
    {:ok,
     assign(socket, %{
       flagging_done: false,
       flag_display: false,
       flag_text: ""
     })}
  end

  def handle_event("flag_toggle", _params, socket) do
    {:noreply, assign(socket, %{flag_display: !socket.assigns.flag_display})}
  end

  def handle_event("flag_text", %{"value" => value} = _params, socket) do
    {:noreply, assign(socket, %{flag_text: value})}
  end

  def handle_event("flag_submit", _params, socket) do
    insert =
      %Flag{}
      |> Flag.changeset(%{test: socket.assigns.test, reason: socket.assigns.flag_text})
      |> Repo.insert()

    case insert do
      {:ok, _} -> send(self(), {:flash, {:success, "You have flagged this test."}})
      _ -> send(self(), {:flash, {:error, "An error occurred, please try again later."}})
    end

    {:noreply, assign(socket, %{flag_display: !socket.assigns.flag_display, flag_text: ""})}
  end
end
