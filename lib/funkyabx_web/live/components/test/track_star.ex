defmodule FunkyABXWeb.TestTrackStarComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.Tests

  @impl true
  def render(assigns) do
    assigns =
      assign_new(assigns, :starred, fn ->
        Tests.assign_new(assigns.choices_taken, assigns.round, :star)
      end)

    ~H"""
    <div class="p-2 d-flex flex-row align-items-center flex-grow-1 flex-md-grow-0 test-starring">
      <div class="me-auto flex-grow-1 flex-md-grow-0">
        <span class="me-3 text-muted small"><%= dgettext("test", "I rate this track ...") %></span>
      </div>
      <div class=" p-0 p-md-3 flex-fill">
        <%= for star <- 1..5 do %>
          <i
            title={star}
            class={"bi bi-star#{if Map.get(@starred, @track.id, 0) >= star, do: "-fill"}"}
            phx-click="star_track"
            phx-value-track_id={@track.id}
            phx-value-star={star}
            phx-target={@myself}
          >
          </i>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "star_track",
        %{"track_id" => track_id, "star" => star} = _picking_params,
        socket
      ) do
    star_updated =
      socket.assigns.choices_taken
      |> Map.get(socket.assigns.round, %{})
      |> Map.get(:star, %{})
      |> Map.merge(%{track_id => String.to_integer(star)})

    send(self(), {:update_choices_taken, socket.assigns.round, %{star: star_updated}})
    {:noreply, socket}
  end
end
