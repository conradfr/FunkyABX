defmodule FunkyABXWeb.TestResultIdentificationComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.{Tracks, Identifications, Tests}
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
      case Map.has_key?(assigns, :visitor_identified) do
        false ->
          visitor_identified = Map.get(assigns.visitor_choices, "identification", %{})
          visitor_identification_score = calculate_identification_score(visitor_identified)

          assign(assigns, %{
            visitor_identified: visitor_identified,
            visitor_identification_score: visitor_identification_score
          })

        _ ->
          assigns
      end

    ~H"""
    <div>
      <div class="d-flex flex-row align-items-end">
        <div class="me-auto">
          <h4 class="mt-3 header-neon"><%= dgettext("test", "Identification") %></h4>
          <div :if={@visitor_identification_score != nil} class="mb-3">
            <%= raw(
              dgettext("test", "Your score: <strong>%{score}/%{count}</strong>",
                score: Kernel.elem(@visitor_identification_score, 0),
                count: length(@identifications)
              )
            ) %>
            <i
              :if={Kernel.elem(@visitor_identification_score, 0) == length(@identifications)}
              class="bi bi-hand-thumbs-up"
            >
            </i>
          </div>
        </div>
        <div
          :if={@test.local == false and @test.hide_global_results == false}
          class="view-details justify-content-end text-end pt-4"
        >
          <%= if @identification_detail == false do %>
            <span
              class="fs-8 mt-2 cursor-link text-body-secondary"
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

      <div class="tracks track-results mb-2 results">
        <div :if={Kernel.length(@identifications) == 0} class="alert alert-info alert-thin">
          <%= dgettext("test", "No tracks guesses ... yet!") %>
        </div>
        <%= for {identification, i} <- @identifications |> Enum.with_index(1) do %>
          <div class={["track", "my-1", "d-flex", "flex-wrap", "align-items-center", i > 1 && "mt-4"]}>
            <TestResultTrackHeaderComponent.display
              playing={@play_track_id == identification.track_id}
              rank={i}
              test={@test}
              track_id={identification.track_id}
              title={identification.title}
              tracks_order={@tracks_order}
            />

            <div class="p-3 flex-grow-1 text-end text-truncate">
              <%= if @visitor_identified != %{} do %>
                <%= if identification.track_id == @visitor_identified[identification.track_id] do %>
                  <i class="bi bi-check color-correct"></i>&nbsp;
                  <%= if @is_another_session == true do %>
                    <%= dgettext("test", "This track was identified correctly") %>
                  <% else %>
                    <%= dgettext("test", "You identified this track correctly!") %>
                  <% end %>
                <% else %>
                  <i class="bi bi-x color-incorrect"></i>&nbsp;
                  <%= if @is_another_session == true do %>
                    <%= dgettext("test", "This track was identified as") %>
                  <% else %>
                    <%= dgettext("test", "You identified this track as") %>
                  <% end %>&nbsp;<%= Tracks.find_track(
                    @visitor_identified[identification.track_id],
                    @test.tracks
                  ).title %>
                <% end %>
              <% else %>
                <small :if={i == 1 and @is_another_session == false} class="text-body-secondary">
                  <%= dgettext("test", "You did not participate in this test") %>
                </small>
              <% end %>
            </div>
          </div>

          <%= if @test.local == false and @test.hide_global_results == false do %>
            <%= for {guess, j} <- identification.guesses |> Enum.with_index() do %>
              <%= if (j == 0) do %>
                <div class="my-1 d-flex flex-wrap align-items-center justify-content-end">
                  <div class="p-1 ps-0 text-end text-body-secondary">
                    <small>Mostly identified as</small>
                  </div>
                  <div class="p-1 ps-0 text-end text-truncate">
                    <i class={[
                      "bi",
                      identification.track_id == guess["track_guessed_id"] && "bi-check" &&
                        "color-correct",
                      identification.track_id != guess["track_guessed_id"] && "bi-x" &&
                        "color-incorrect"
                    ]}>
                    </i> <%= guess["title"] %>
                  </div>
                  <div class="p-1 ps-0 text-end text-body-secondary">
                    <small><%= dgettext("test", "at") %></small>
                  </div>
                  <div class="p-2 ps-0 text-end">
                    <%= percent_of(guess["count"], identification.total_guess) %>%
                  </div>
                </div>
              <% else %>
                <div
                  :if={@identification_detail == true}
                  id={"#{i}_#{j}"}
                  class="track-guess d-flex align-items-center justify-content-end"
                >
                  <div class="p-1 ps-0 text-end text-body-secondary">
                    <small>Identified as</small>
                  </div>
                  <div class="p-1 ps-0 text-end text-truncate">
                    <i class={[
                      "bi",
                      identification.track_id == guess["track_guessed_id"] && "bi-check" &&
                        "color-correct",
                      identification.track_id != guess["track_guessed_id"] && "bi-x" &&
                        "color-incorrect"
                    ]}>
                    </i><%= guess["title"] %>
                  </div>
                  <div class="p-1 ps-0 text-end text-body-secondary">
                    <small><%= dgettext("test", "at") %></small>
                  </div>
                  <div class="p-2 ps-0 text-end">
                    <%= percent_of(guess["count"], identification.total_guess) %>%
                  </div>
                </div>
              <% end %>
            <% end %>
          <% end %>
        <% end %>

        <div
          :if={@reference_track != nil}
          class="track track-reference my-1 mt-4 d-flex flex-wrap justify-content-between align-items-center"
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
          identifications:
            Identifications.get_identification(
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
     |> assign_new(:identifications, fn ->
       Identifications.get_identification(assigns.test, assigns.visitor_choices)
     end)
     |> assign_new(:reference_track, fn -> Tests.get_reference_track(assigns.test) end)
     |> assign_new(:identification_detail, fn -> false end)}
  end

  @impl true
  def handle_event("toggle_detail", _value, socket) do
    toggle = !socket.assigns.identification_detail

    {:noreply, assign(socket, identification_detail: toggle)}
  end

  # ---------- UTILS ----------

  defp calculate_identification_score(choices) when choices == %{}, do: nil

  defp calculate_identification_score(choices) do
    choices
    |> Enum.reduce({0, 0}, fn {track_id, track_guess_id}, {correct_count, total} ->
      if track_id == track_guess_id do
        correct_count + 1
      else
        correct_count
      end
      |> (&{&1, total + 1}).()
    end)
  end

  # ---------- VIEW HELPERS ----------

  def percent_of(count, total) do
    Float.round(count * 100 / total)
  end
end
