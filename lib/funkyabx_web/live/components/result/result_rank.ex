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
        <div class="d-flex flex-row align-items-end">
          <div class="me-auto">
            <h4 class="mt-3 header-neon"><%= dgettext "test", "Ranking" %></h4>
          </div>
          <div :if={@test.local == false} class="justify-content-end text-end pt-4">
            <%= if @ranks_detail == false do %>
              <span class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_detail" phx-target={@myself}><%= dgettext "test", "View details" %>&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></span>
            <% else %>
              <span class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_detail" phx-target={@myself}><%= dgettext "test", "Hide details" %>&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></span>
            <% end %>
          </div>
        </div>
        <div class="tracks my-2 mb-4 track-results results">
          <div :if={Kernel.length(@ranks) == 0} class="alert alert-info alert-thin"><%= dgettext "test", "No ranking done ... yet!" %></div>
          <%= for rank <- @ranks do %>
            <div class="track my-1 d-flex flex-wrap justify-content-between align-items-center" phx-click={JS.dispatch(if @play_track_id == rank.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => rank.track_id, "track_url" => Tracks.get_track_url(rank.track_id, @test)})}>

              <TestResultTrackHeaderComponent.display playing={@play_track_id == rank.track_id} rank={rank.rank} test={@test} track_id={rank.track_id} title={rank.track_title} />

              <div class="d-flex flex-grow-1 justify-content-end align-items-center">
                <div :if={@test.local == false and Map.has_key?(@visitor_ranked, rank.track_id) == true} class="p-3 flex-grow-1 text-sm-end text-start pe-5">
                  <small>
                    <%= if @is_another_session == true do %>
                      <%= dgettext "test", "This track was ranked:" %>
                    <% else %>
                      <%= dgettext "test", "You ranked this track:" %>
                    <% end %>
                    &nbsp;#<%= @visitor_ranked[rank.track_id] %>
                  </small>
                </div>
                <div class="p-3 ps-0 text-end">
                  <%= if @test.local == false do %>
                    <%= rank.count %> votes as #<%= rank.rank %>
                    <%= dgettext "test", "%{count}votes as %{rank}", count: rank.count, rank: rank.rank %>
                  <% else %>
                    <small>You ranked this track:</small> #<%= rank.rank %>
                    <%= raw dgettext "test", "<small>You ranked this track:</small> %{rank}", rank: rank.rank %>
                  <% end %>
                </div>
              </div>
            </div>

            <%= if @ranks_detail == true do %>
              <div class="mb-3">
                <%= if Map.get(rank, :other_ranks, nil) == nil do %>
                  <div class="my-2 text-end text-muted"><small><%= dgettext "test", "No other ranking" %></small></div>
                <% else %>
                  <%= for other_rank <- Map.get(rank, :other_ranks, []) do %>
                    <div class="my-2 d-flex flex-wrap align-items-center justify-content-end">
                      <small><%= dgettext "test", "%{count} votes as #%{rank}", count: other_rank.count, rank: other_rank.rank %></small>
                    </div>
                  <% end %>
                <% end %>
              </div>
            <% end %>
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
     |> assign_new(:ranks, fn -> Ranks.get_ranks(assigns.test, assigns.visitor_choices) end)
     |> assign_new(:ranks_detail, fn -> false end)}
  end

  @impl true
  def handle_event("toggle_detail", _value, socket) do
    toggle = !socket.assigns.ranks_detail

    {:noreply, assign(socket, ranks_detail: toggle)}
  end
end
