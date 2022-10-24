defmodule FunkyABXWeb.TestResultRankComponent do
  use FunkyABXWeb, :live_component

  alias Phoenix.LiveView.JS
  alias FunkyABX.{Tracks, Ranks, Test}

  attr :test, Test, required: true
  attr :visitor_choices, :any, required: true
  attr :is_another_session, :boolean, required: true
  attr :track_id, :string, required: true
  attr :test_taken_times, :integer, required: true

  @impl true
  def render(assigns) do
    assigns =
      case Map.get(assigns, :visitor_ranked, %{}) do
        %{} ->
          assign(assigns, :visitor_ranked, Map.get(assigns.visitor_choices, "rank", %{}))

        _ ->
          assigns
      end

    ~H"""
      <div>
        <h4 class="mt-3 header-neon">Ranking</h4>
        <div class="tracks my-2 mb-4 track-results results">
          <div :if={Kernel.length(@ranks) == 0} class="alert alert-info alert-thin">No ranking done ... yet!</div>
          <%= for rank <- @ranks do %>
            <div class="track my-1 d-flex flex-wrap justify-content-between align-items-center" phx-click={JS.dispatch(if @play_track_id == rank.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => rank.track_id, "track_url" => Tracks.get_track_url(rank.track_id, @test)})}>

              <TestResultTrackHeaderComponent.display playing={@play_track_id == rank.track_id} rank={rank.rank} test={@test} track_id={rank.track_id} title={rank.track_title} />

              <div class="d-flex flex-grow-1 justify-content-end align-items-center">
                <div :if={@test.local == false and Map.has_key?(@visitor_ranked, rank.track_id) == true} class="p-3 flex-grow-1 text-sm-end text-start pe-5">
                  <small>
                    <%= if @is_another_session == true do %>
                      This track was ranked:
                    <% else %>
                      You ranked this track:
                    <% end %>
                    &nbsp;#<%= @visitor_ranked[rank.track_id] %>
                  </small>
                </div>
                <div class="p-3 ps-0 text-end">
                  <%= if @test.local == false do %>
                    <%= rank.count %> votes as #<%= rank.rank %>
                  <% else %>
                    <small>You ranked this track:</small> #<%= rank.rank %>
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
     |> assign_new(:ranks, fn -> Ranks.get_ranks(assigns.test, assigns.visitor_choices) end)}
  end
end
