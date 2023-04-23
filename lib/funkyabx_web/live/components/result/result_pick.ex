defmodule FunkyABXWeb.TestResultPickComponent do
  use FunkyABXWeb, :live_component
  alias Phoenix.LiveView.JS
  alias FunkyABX.{Tracks, Picks, Test}

  attr :test, Test, required: true
  attr :visitor_choices, :any, required: true
  attr :is_another_session, :boolean, required: true
  attr :track_id, :string, required: true
  attr :test_taken_times, :integer, required: true

  @impl true
  def render(assigns) do
    assigns =
      case Map.get(assigns, :visitor_picked, nil) do
        nil when assigns.test.local == true ->
          assign(assigns, :visitor_picked, nil)

        nil ->
          assign(assigns, :visitor_picked, Map.get(assigns.visitor_choices, "pick", nil))

        _ ->
          assigns
      end

    ~H"""
    <div>
      <h4 class="mt-3 header-neon"><%= dgettext("test", "Picking") %></h4>
      <div class="tracks my-2 mb-4 track-results results">
        <div :if={Kernel.length(@picks) == 0} class="alert alert-info alert-thin">
          <%= dgettext("test", "No track picked ... yet!") %>
        </div>
        <%= for {pick, i} <- @picks |> Enum.with_index(1) do %>
          <div
            class="track my-1 d-flex flex-wrap justify-content-between align-items-center"
            phx-click={
              JS.dispatch(
                if @play_track_id == pick.track_id do
                  "stop"
                else
                  "play"
                end,
                to: "body",
                detail: %{
                  "track_id" => pick.track_id,
                  "track_url" => Tracks.get_track_url(pick.track_id, @test)
                }
              )
            }
          >
            <TestResultTrackHeaderComponent.display
              playing={@play_track_id == pick.track_id}
              rank={i}
              test={@test}
              track_id={pick.track_id}
              title={pick.track_title}
              trophy={@test.local == false}
            />

            <div class="d-flex flex-grow-1 justify-content-end align-items-center">
              <%= if @test.local == true do %>
                <%= if pick.picked == 1 do %>
                  <div class="p-3 ps-0 text-end">
                    <%= dgettext("test", "You picked this track") %>
                  </div>
                <% else %>
                  <div class="p-3 ps-0"></div>
                <% end %>
              <% else %>
                <div
                  :if={@visitor_picked == pick.track_id}
                  class="p-3 flex-grow-1 text-sm-end text-start pe-5"
                >
                  <small>
                    <%= if @is_another_session == true do %>
                      <%= dgettext("test", "This track was picked") %>
                    <% else %>
                      <%= dgettext("test", "You picked this track") %>
                    <% end %>
                  </small>
                </div>
                <div class="p-3 ps-0 text-end">
                  <%= dngettext("test", "Picked %{count} time", "Picked %{count} times", pick.picked) %>
                </div>
              <% end %>
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
     |> assign_new(:picks, fn -> Picks.get_picks(assigns.test, assigns.visitor_choices) end)}
  end
end
