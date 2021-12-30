defmodule FunkyABXWeb.TestResultPickComponent do
  use FunkyABXWeb, :live_component
  alias Phoenix.LiveView.JS
  alias FunkyABX.Tracks
  alias FunkyABX.Picks

  @impl true
  def render(assigns) do
    assigns =
      case Map.get(assigns, :visitor_picked, nil) do
        nil ->
          assign(assigns, :visitor_picked, Map.get(assigns.visitor_choices, "pick", nil))

        _ ->
          assigns
      end

    ~H"""
      <div>
        <h4 class="mt-3 header-neon">Picking</h4>
        <div class="tracks my-2 mb-4 track-results results">
          <%= if Kernel.length(@picks) == 0 do %>
            <div class="alert alert-info alert-thin">No track picked done ... yet!</div>
          <% end %>
          <%= for {pick, i} <- @picks |> Enum.with_index(1) do %>
            <div class="track my-1 d-flex flex-wrap justify-content-between align-items-center" phx-click={JS.dispatch(if @play_track_id == pick.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => pick.track_id, "track_url" => Tracks.get_track_url(pick.track_id, @test)})}>

              <TestResultTrackHeaderComponent.display playing={@play_track_id == pick.track_id} rank={i} title={pick.track_title} />

              <div class="d-flex flex-grow-1 justify-content-end align-items-center">
              <%= if @visitor_picked == pick.track_id do %>
                <div class="p-3 flex-grow-1 text-sm-end text-start pe-5"><small>You picked this track</small></div>
              <% end %>
              <div class="p-3 ps-0 text-end">
                Picked <%= pick.picked %> times
              </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:picks, fn -> Picks.get_picks(assigns.test) end)}
  end
end
