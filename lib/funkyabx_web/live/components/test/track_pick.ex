defmodule FunkyABXWeb.TestTrackPickComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.Tests

  @impl true
  def render(assigns) do
    assigns =
      assign_new(assigns, :picked, fn ->
        Tests.assign_new(assigns.choices_taken, assigns.round, :pick, nil)
      end)

    ~H"""
    <div class="p-2 text-center flex-grow-1 flex-sm-grow-0" style="min-width: 220px">
      <%= if @picked == @track.id do %>
        <span class="test-pick-chosen">
          <i class="bi bi-check-lg"></i>&nbsp;&nbsp;{dgettext("test", "This track is my favorite")}
        </span>
      <% else %>
        <button
          class="btn btn-secondary"
          name="pick"
          phx-click="pick_track"
          phx-value-track_id={@track.id}
          phx-target={@myself}
          disabled={@test_already_taken == true}
        >
          {dgettext("test", "Pick this track as favorite")}
        </button>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event(
        "pick_track",
        _picking_params,
        %{assigns: %{test_already_taken: true}} = socket
      ),
      do: {:noreply, socket}

  @impl true
  def handle_event("pick_track", %{"track_id" => track_id} = _picking_params, socket) do
    send(self(), {:update_choices_taken, socket.assigns.round, %{pick: track_id}})
    {:noreply, socket}
  end
end
