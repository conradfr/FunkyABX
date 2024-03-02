defmodule FunkyABXWeb.TestResultRankComponent do
  use FunkyABXWeb, :live_component

  alias Phoenix.LiveView.JS
  alias FunkyABX.{Tracks, Ranks, Tests}
  alias FunkyABX.Test

  @sort [{:average, "By average score"}, {:top, "By top score"}]
  @default_sort :average

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
          <h4 class="mt-3 header-neon"><%= dgettext("test", "Ranking") %></h4>
        </div>
        <div :if={@test.local == false} class="pe-3">
          <button
            class="btn btn-sm link-underline-light text-body-secondary btn-link dropdown-toggle link-no-decoration"
            type="button"
            data-bs-toggle="dropdown"
            id="sortDropdown"
            aria-expanded="false"
          >
            <% {_sort_key, sort_value} = get_current_sort(@sort) %>
            <%= Gettext.dgettext(FunkyABXWeb.Gettext, "test", sort_value) %>
          </button>

          <ul class="dropdown-menu" aria-labelledby="sortDropdown">
            <%= for {sort_key, sort_value} <- get_rest_sort(@sort) do %>
              <li>
                <a
                  class="dropdown-item"
                  phx-click="sort_change"
                  phx-value-sort={sort_key}
                  phx-target={@myself}
                >
                  <%= Gettext.dgettext(FunkyABXWeb.Gettext, "test", sort_value) %>
                </a>
              </li>
            <% end %>
          </ul>
        </div>
        <div :if={@test.local == false} class="view-details justify-content-end text-end pt-4">
          <%= if @ranks_detail == false do %>
            <span
              class="fs-8 cursor-link text-body-secondary"
              phx-click="toggle_detail"
              phx-target={@myself}
            >
              <%= dgettext("test", "View details") %>&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i>
            </span>
          <% else %>
            <span
              class="fs-8 mt-2 cursor-link text-body-secondary"
              phx-click="toggle_detail"
              phx-target={@myself}
            >
              <%= dgettext("test", "Hide details") %>&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i>
            </span>
          <% end %>
        </div>
      </div>
      <div class="tracks my-2 mb-4 track-results results">
        <div :if={Kernel.length(@ranks) == 0} class="alert alert-info alert-thin">
          <%= dgettext("test", "No ranking done ... yet!") %>
        </div>
        <%= for rank <- @ranks do %>
          <div
            class="track my-1 d-flex flex-wrap justify-content-between align-items-center"
            phx-click={
              JS.dispatch(
                if @play_track_id == rank.track_id do
                  "stop_result"
                else
                  "play_result"
                end,
                to: "body",
                detail: %{
                  "track_id" => rank.track_id,
                  "track_url" => Tracks.get_track_url(rank.track_id, @test)
                }
              )
            }
          >
            <TestResultTrackHeaderComponent.display
              playing={@play_track_id == rank.track_id}
              rank={rank.rank}
              test={@test}
              track_id={rank.track_id}
              title={rank.track_title}
              tracks_order={@tracks_order}
            />

            <div class="d-flex flex-grow-1 justify-content-end align-items-center">
              <div
                :if={@test.local == false and Map.has_key?(@visitor_ranked, rank.track_id) == true}
                class="p-3 flex-grow-1 text-sm-end text-start pe-5"
              >
                <small>
                  <%= if @is_another_session == true do %>
                    <%= dgettext("test", "This track was ranked:") %>
                  <% else %>
                    <%= dgettext("test", "You ranked this track:") %>
                  <% end %>
                  &nbsp;#<%= @visitor_ranked[rank.track_id] %>
                </small>
              </div>
              <div class="p-3 ps-0 text-end">
                <%= if @test.local == false do %>
                  <% {rank_display, count_display} =
                    Ranks.pick_rank_to_display(rank.ranks, rank.rank, @sort) %>
                  <%= dgettext("test", "%{count} votes as #%{rank}",
                    count: count_display,
                    rank: rank_display
                  ) %>
                <% else %>
                  <%= raw(
                    dgettext("test", "<small>You ranked this track:</small> %{rank}", rank: rank.rank)
                  ) %>
                <% end %>
              </div>
            </div>
          </div>

          <%= if @ranks_detail == true do %>
            <div class="mb-3">
              <%= if Map.get(rank, :ranks, nil) == nil do %>
                <div class="my-2 text-end text-body-secondary">
                  <small><%= dgettext("test", "No other ranking") %></small>
                </div>
              <% else %>
                <%= for other_rank <- Map.get(rank, :ranks, []) do %>
                  <div class="my-2 d-flex flex-wrap align-items-center justify-content-end">
                    <small>
                      <%= dgettext("test", "%{count} votes as #%{rank}",
                        count: other_rank["count"],
                        rank: other_rank["rank"]
                      ) %>
                    </small>
                  </div>
                <% end %>
              <% end %>
            </div>
          <% end %>
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
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:sort, fn -> @default_sort end)
     |> assign_new(:ranks, fn s ->
       Ranks.get_ranks(assigns.test, assigns.visitor_choices, s.sort)
     end)
     |> assign_new(:reference_track, fn -> Tests.get_reference_track(assigns.test) end)
     |> assign_new(:ranks_detail, fn -> false end)}
  end

  @impl true
  def handle_event("toggle_detail", _value, socket) do
    toggle = !socket.assigns.ranks_detail

    {:noreply, assign(socket, ranks_detail: toggle)}
  end

  @impl true
  def handle_event("sort_change", %{"sort" => value}, socket) do
    value_atom = String.to_atom(value)
    ranks = Ranks.get_ranks(socket.assigns.test, socket.assigns.visitor_choices, value_atom)

    {:noreply,
     assign(socket,
       sort: value_atom,
       ranks: ranks
     )}
  end

  def get_current_sort(assign_sort) do
    List.keyfind(@sort, assign_sort, 0)
  end

  def get_rest_sort(assign_sort) do
    {_, rest} = List.keytake(@sort, assign_sort, 0)
    rest
  end
end
