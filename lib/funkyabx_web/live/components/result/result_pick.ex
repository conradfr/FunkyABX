defmodule FunkyABXWeb.TestResultPickComponent do
  use FunkyABXWeb, :live_component
  alias Phoenix.LiveView.JS
  alias FunkyABX.{Tracks, Picks, Tests}
  alias FunkyABX.Test

  # attr is not supported by live components, just act as docs here

  attr :test, Test, required: true
  attr :visitor_choices, :any, required: true
  attr :is_another_session, :boolean, required: true
  attr :track_id, :string, required: true
  attr :test_taken_times, :integer, required: true
  attr :tracks_order, :any, required: false, default: nil

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
                  "stop_result"
                else
                  "play_result"
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
              trophy={@test.local == false or @test.hide_global_results == true}
              tracks_order={@tracks_order}
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
                <div :if={@test.hide_global_results == false} class="p-3 ps-0 text-end">
                  <%= dngettext("test", "Picked %{count} time", "Picked %{count} times", pick.picked) %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
        <div
          :if={@reference_track != nil}
          class="track track-reference my-1 d-flex flex-wrap justify-content-between align-items-center"
          phx-click={
            JS.dispatch(
              if @play_track_id == @reference_track.id do
                "stop_result"
              else
                "play_result"
              end,
              to: "body",
              detail: %{
                "track_id" => @reference_track.id,
                "track_url" => Tracks.get_track_url(@reference_track.id, @test)
              }
            )
          }
        >
          <TestResultTrackHeaderComponent.display
            playing={@play_track_id == @reference_track.id}
            rank={0}
            test={@test}
            track_id={@reference_track.id}
            title={@reference_track.title}
            trophy={false}
            tracks_order={@tracks_order}
            is_reference_track={true}
          />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    # special case, mostly for online tests w/ hide_global_results == true,
    # as we need to re-rank the tracks once the JS hooks sends the visitor choices
    if Map.get(assigns, :visitor_choices) != nil and
         Map.get(socket.assigns, :visitor_choices, %{}) != Map.get(assigns, :visitor_choices) do
      send_update_after(
        __MODULE__,
        [
          id: assigns.id,
          picks:
            Picks.get_picks(
              Map.get(assigns, :test),
              Map.get(assigns, :visitor_choices, %{})
            )
        ],
        250
      )
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:picks, fn -> Picks.get_picks(assigns.test, assigns.visitor_choices) end)
     |> assign_new(:reference_track, fn -> Tests.get_reference_track(assigns.test) end)}
  end
end
