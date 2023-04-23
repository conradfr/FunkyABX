defmodule FunkyABXWeb.TestResultStarComponent do
  use FunkyABXWeb, :live_component
  alias Phoenix.LiveView.JS
  alias FunkyABX.{Tracks, Stars, Test}

  attr :test, Test, required: true
  attr :visitor_choices, :any, required: true
  attr :is_another_session, :boolean, required: true
  attr :track_id, :string, required: true
  attr :test_taken_times, :integer, required: true

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
      <div class="d-flex flex-row align-items-end">
        <div class="me-auto">
          <h4 class="mt-3 header-neon"><%= dgettext("test", "Rating") %></h4>
        </div>
        <div :if={@test.local == false} class="justify-content-end text-end pt-4">
          <%= if @star_detail == false do %>
            <span
              class="fs-8 mt-2 cursor-link text-muted"
              phx-click="toggle_detail"
              phx-target={@myself}
            >
              <%= dgettext("test", "View details") %>&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i>
            </span>
          <% else %>
            <span
              class="fs-8 mt-2 cursor-link text-muted"
              phx-click="toggle_detail"
              phx-target={@myself}
            >
              <%= dgettext("test", "Hide details") %>&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i>
            </span>
          <% end %>
        </div>
      </div>
      <div class="tracks my-1 mb-4 track-results results">
        <div :if={Kernel.length(@stars) == 0} class="alert alert-info alert-thin">
          <%= dgettext("test", "No rating done ... yet!") %>
        </div>
        <%= for {star, i} <- @stars |> Enum.with_index(1) do %>
          <div class={"#{if @star_detail == true, do: "mb-3"}"}>
            <div
              class="track my-1 d-flex flex-wrap justify-content-between align-items-center"
              phx-click={
                JS.dispatch(
                  if @play_track_id == star.track_id do
                    "stop"
                  else
                    "play"
                  end,
                  to: "body",
                  detail: %{
                    "track_id" => star.track_id,
                    "track_url" => Tracks.get_track_url(star.track_id, @test)
                  }
                )
              }
            >
              <TestResultTrackHeaderComponent.display
                playing={@play_track_id == star.track_id}
                rank={i}
                test={@test}
                track_id={star.track_id}
                title={star.track_title}
              />

              <div class="d-flex flex-grow-1 flex-no-wrap justify-content-between justify-content-sm-end align-items-center">
                <div
                  :if={@test.local == false and Map.has_key?(@visitor_starred, star.track_id) == true}
                  class="p-3 text-sm-end text-start pe-2 pe-sm-4"
                >
                  <div class="d-flex flex-wrap flex-grow-1">
                    <div class="pe-2">
                      <small>
                        <%= if @is_another_session == true do %>
                          <%= dgettext("test", "This track was rated:") %>
                        <% else %>
                          <%= dgettext("test", "You rated this track:") %>
                        <% end %>
                      </small>
                    </div>
                    <div>
                      <small>
                        <%= for _star_nb <- 1..@visitor_starred[star.track_id] do %>
                          <i title={@visitor_starred[star.track_id]} class="bi bi-star-fill"></i>
                        <% end %>
                      </small>
                    </div>
                  </div>
                </div>
                <div class="p-3 ps-0 text-end test-starring-result">
                  <%= for star_nb <- 1..5 do %>
                    <i title={star.rank} class={"bi bi-star#{if star.rank >= star_nb, do: "-fill"}"}>
                    </i>
                  <% end %>
                </div>
              </div>
            </div>

            <%= if @star_detail == true do %>
              <%= for star_nb_sub <- 5..1 do %>
                <div
                  :if={star[String.to_atom("total_star_#{star_nb_sub}")] != 0}
                  class="d-flex align-items-center justify-content-end"
                >
                  <div class="p-1 ps-0 text-end text-muted">
                    <small>
                      <%= for _star_nb <- 1..star_nb_sub do %>
                        <i title={star_nb_sub} class="bi bi-star-fill"></i>
                      <% end %>
                    </small>
                  </div>
                  <div class="p-1 ps-2 text-end text-muted">
                    <small>
                      <%= dngettext(
                        "test",
                        "%{count} time",
                        "%{count} times",
                        star[String.to_atom("total_star_#{star_nb_sub}")]
                      ) %>
                    </small>
                  </div>
                </div>
              <% end %>
            <% end %>
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
     |> assign_new(:stars, fn -> Stars.get_stars(assigns.test, assigns.visitor_choices) end)
     |> assign_new(:star_detail, fn -> false end)}
  end

  @impl true
  def handle_event("toggle_detail", _value, socket) do
    toggle = !socket.assigns.star_detail

    {:noreply, assign(socket, star_detail: toggle)}
  end
end
