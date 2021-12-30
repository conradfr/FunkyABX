defmodule FunkyABXWeb.TestTrackPickComponent do
  use FunkyABXWeb, :live_component

  @impl true
  def render(assigns) do
    assigns = assign_new(assigns, :picked, fn -> Map.get(assigns.choices_taken, :pick, nil) end)

    ~H"""
      <div class="p-2 text-center flex-grow-1 flex-sm-grow-0" style="min-width: 220px">
        <%= if @picked == @track.id do %>
          <span class="test-pick-chosen"><i class="bi bi-check-lg"></i>&nbsp;&nbsp;This track is my favorite</span>
        <% else %>
          <button class="btn btn-secondary" name="pick" phx-click="pick_track" phx-value-track_id={@track.id} phx-target={@myself}>Pick this track as favorite</button>
        <% end %>
      </div>
    """
  end

  @impl true
  def handle_event("pick_track", %{"track_id" => track_id} = _picking_params, socket) do
    send(self(), {:update_choices_taken, %{pick: track_id}})
    {:noreply, socket}
  end
end
