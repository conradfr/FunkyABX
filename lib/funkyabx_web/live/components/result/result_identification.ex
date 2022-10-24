defmodule FunkyABXWeb.TestResultIdentificationComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.{Tracks, Identifications, Test}

  attr :test, Test, required: true
  attr :visitor_choices, :any, required: true
  attr :is_another_session, :boolean, required: true
  attr :track_id, :string, required: true
  attr :test_taken_times, :integer, required: true

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
      |> assign_new(:visitor_identification_score, fn ->
        {666, 1020}
      end)

    ~H"""
      <div>
        <div class="d-flex flex-row align-items-end">
          <div class="me-auto">
            <h4 class="mt-3 header-neon">Identification</h4>
            <div :if={@visitor_identification_score != nil} class="mb-3">
              Your score: <strong><%= Kernel.elem(@visitor_identification_score, 0) %>/<%= Kernel.elem(@visitor_identification_score, 1) %></strong>
              <i :if={Kernel.elem(@visitor_identification_score, 0) == Kernel.elem(@visitor_identification_score, 1)} class="bi bi-hand-thumbs-up"></i>
            </div>
          </div>
          <div :if={@test.local == false} class="justify-content-end text-end pt-4">
            <%= if @identification_detail == false do %>
              <span class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_detail" phx-target={@myself}>View details&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></span>
            <% else %>
              <span class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_detail" phx-target={@myself}>Hide details&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></span>
            <% end %>
          </div>
        </div>

        <div class="tracks track-results mb-2 results">
          <div :if={Kernel.length(@identifications) == 0} class="alert alert-info alert-thin">No tracks guesses ... yet!</div>
          <%= for {identification, i} <- @identifications |> Enum.with_index(1) do %>
            <div class={"track my-1 #{if (i > 1), do: "mt-4"} d-flex flex-wrap align-items-center"}>

              <TestResultTrackHeaderComponent.display playing={@play_track_id == identification.track_id} rank={i} test={@test} track_id={identification.track_id} title={identification.title} />

              <div class="p-3 flex-grow-1 text-end text-truncate">
                <%= if @visitor_identified != %{} do %>
                  <%= if identification.track_id == @visitor_identified[identification.track_id] do %>
                    <i class="bi bi-check color-correct"></i>&nbsp;
                    <%= if @is_another_session == true do %>
                      This track was identified correctly
                    <% else %>
                      You identified this track correctly!
                    <% end %>
                  <% else %>
                    <i class="bi bi-x color-incorrect"></i>&nbsp;
                    <%= if @is_another_session == true do %>
                      This track was identified as
                    <% else %>
                      You identified this track as
                    <% end %>&nbsp;<%= Tracks.find_track(@visitor_identified[identification.track_id], @test.tracks).title  %>
                  <% end %>
                <% else %>
                  <small :if={i == 1 and @is_another_session == false} class="text-muted">You did not participate in this test</small>
                <% end %>
              </div>
            </div>

            <%= if @test.local == false do %>
              <%= for {guess, j} <- identification.guesses |> Enum.with_index() do %>
                <%= if (j == 0) do %>
                  <div class="my-1 d-flex flex-wrap align-items-center justify-content-end">
                    <div class="p-1 ps-0 text-end text-muted"><small>Mostly identified as</small></div>
                    <div class="p-1 ps-0 text-end text-truncate"><i class={"bi bi-#{if identification.track_id == guess["track_guessed_id"], do: "check color-correct", else: "x color-incorrect"}"}}></i> <%= guess["title"]  %></div>
                    <div class="p-1 ps-0 text-end text-muted"><small>at</small></div>
                    <div class="p-2 ps-0 text-end"><%= percent_of(guess["count"], identification.total_guess) %>%</div>
                  </div>
                <% else %>
                  <div :if={@identification_detail == true} id={"#{i}_#{j}"} class="track-guess d-flex align-items-center justify-content-end">
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
     |> assign_new(:identifications, fn ->
       Identifications.get_identification(assigns.test, assigns.visitor_choices)
     end)
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
