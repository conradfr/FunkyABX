defmodule FunkyABXWeb.TestResultIdentificationComponent do
  use FunkyABXWeb, :live_component
  alias Phoenix.LiveView.JS
  alias FunkyABX.Tracks
  alias FunkyABX.Identifications

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
      |> assign_new(:identification_detail, fn ->
        false
      end)
      |> assign_new(:visitor_identification_score, fn ->
        {666, 1020}
      end)

    ~H"""
      <div>
        <div class="d-flex flex-row align-items-end">
          <div class="me-auto">
            <h4 class="mt-3 header-neon">Identification</h4>
            <%= if @visitor_identification_score != nil do %>
              <div class="mb-3">
                Your score: <strong><%= Kernel.elem(@visitor_identification_score, 0) %>/<%= Kernel.elem(@visitor_identification_score, 1) %></strong>
                <%= if Kernel.elem(@visitor_identification_score, 0) == Kernel.elem(@visitor_identification_score, 1) do %>
                  <i class="bi bi-hand-thumbs-up"></i>
                <% end %>
              </div>
            <% end %>
          </div>
          <div class="justify-content-end text-end pt-4">
            <!--
            <%= if @identification_detail == false do %>
              <span class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_identification_detail">View details&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></span>
            <% else %>
              <span class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_identification_detail">Hide details&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></span>
            <% end %>
            -->
          </div>
        </div>

        <div class="tracks track-results mb-2 results">
          <%= if Kernel.length(@identifications) == 0 do %>
            <div class="alert alert-info alert-thin">No tracks guesses ... yet!</div>
          <% end %>
          <%= for {identification, i} <- @identifications |> Enum.with_index(1) do %>
            <div class={"track my-1 #{if (i > 1), do: "mt-4"} d-flex flex-wrap align-items-center"} phx-click={JS.dispatch(if @play_track_id == identification.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => identification.track_id, "track_url" => Tracks.get_track_url(identification.track_id, @test)})}>

                <TestResultTrackHeaderComponent.display playing={@play_track_id == identification.track_id} rank={i} title={identification.title} />

                <div class="p-3 flex-grow-1 text-end text-truncate">
                  <%= if @visitor_identified != %{} do %>
                    <%= if identification.track_id == @visitor_identified[identification.track_id] do %>
                      <i class="bi bi-check color-correct"></i> You identified this track correctly!
                    <% else %>
                      <i class="bi bi-x color-incorrect"></i> You identified this track as <%= Tracks.find_track(@visitor_identified[identification.track_id], @test.tracks).title  %>
                    <% end %>
                  <% else %>
                    <%= if (i == 1) do %>
                      <small class="text-muted">You did not participate in this test</small>
                    <% end %>
                  <% end %>
                </div>
            </div>

              <%= for {guess, j} <- identification.guesses |> Enum.with_index() do %>
                <%= if (j == 0) do %>
                  <div class="my-1 d-flex flex-wrap align-items-center justify-content-end">
                    <div class="p-1 ps-0 text-end text-muted"><small>Mostly identified as</small></div>
                    <div class="p-1 ps-0 text-end text-truncate"><i class={"bi bi-#{if identification.track_id == guess["track_guessed_id"], do: "check color-correct", else: "x color-incorrect"}"}}></i> <%= guess["title"]  %></div>
                    <div class="p-1 ps-0 text-end text-muted"><small>at</small></div>
                    <div class="p-2 ps-0 text-end"><%= percent_of(guess["count"], identification.total_guess) %>%</div>
                  </div>
                <% else %>
                  <%= if @identification_detail == true do %>
                    <div class="track-guess d-flex align-items-center justify-content-end">
                      <div class="p-1 ps-0 text-end text-muted"><small>Identified as</small></div>
                      <div class="p-1 ps-0 text-end text-truncate"><i class={"bi bi-#{if identification.track_id == guess["track_guessed_id"], do: "check color-correct", else: "x color-incorrect"}"}}></i><%= guess["title"] %></div>
                      <div class="p-1 ps-0 text-end text-muted"><small>at</small></div>
                      <div class="p-2 ps-0 text-end"><%= percent_of(guess["count"], identification.total_guess) %>%</div>
                    </div>
                  <% end %>
                <% end %>
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
     |> assign_new(:identifications, fn -> Identifications.get_identification(assigns.test) end)}
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
