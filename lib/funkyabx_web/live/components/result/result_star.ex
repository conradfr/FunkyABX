defmodule FunkyABXWeb.TestResultStarComponent do
  use FunkyABXWeb, :live_component
  alias Phoenix.LiveView.JS
  alias FunkyABX.Tracks
  alias FunkyABX.Stars

  @impl true
  def render(assigns) do
    assigns =
      case Map.get(assigns, :visitor_starred, %{}) do
        %{} ->
          assign(assigns, :visitor_starred, Map.get(assigns.visitor_choices, "star", %{}))

        _ ->
          assigns
      end

    ~H"""
      <div>
        <h4 class="mt-3 header-neon">Rating</h4>
        <div class="tracks my-2 mb-4 track-results results">
          <%= if Kernel.length(@stars) == 0 do %>
            <div class="alert alert-info alert-thin">No rating done ... yet!</div>
          <% end %>
          <%= for {star, i} <- @stars |> Enum.with_index(1) do %>
            <div class="track my-1 d-flex flex-wrap justify-content-between align-items-center" phx-click={JS.dispatch(if @play_track_id == star.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => star.track_id, "track_url" => Tracks.get_track_url(star.track_id, @test)})}>

              <TestResultTrackHeaderComponent.display playing={@play_track_id == star.track_id} rank={i} title={star.track_title} />

              <div class="d-flex flex-grow-1 flex-no-wrap justify-content-between justify-content-sm-end align-items-center">
                <%= if Map.has_key?(@visitor_starred, star.track_id) == true do %>
                  <div class="p-3 text-sm-end text-start pe-2 pe-sm-4">
                    <div class="d-flex flex-wrap flex-grow-1">
                      <div class="pe-2"><small>You rated this track:</small></div>
                      <div><small>
                        <%= for star_nb <- 1..@visitor_starred[star.track_id] do %>
                          <i title={star.star} class="bi bi-star-fill"></i>
                        <% end %>
                      </small></div>
                    </div>
                  </div>
                <% end %>
                <div class="p-3 ps-0 text-end test-starring">
                  <%= for star_nb <- 1..5 do %>
                    <i title={star.star} class={"bi bi-star#{if star.star >= star_nb, do: "-fill"}"}></i>
                  <% end %>
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
     |> assign_new(:stars, fn -> Stars.get_stars(assigns.test) end)}
  end
end
