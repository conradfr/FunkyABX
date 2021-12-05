defmodule FunkyABXWeb.TestResultsLive do
  use FunkyABXWeb, :live_view
  alias Phoenix.LiveView.JS
  alias FunkyABX.Tests
  alias FunkyABX.Tracks
  alias FunkyABX.Ranks
  alias FunkyABX.Identifications

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
      <div class="row">
        <div class="col-sm-6">
          <h3 class="mb-0 header-typographica" id="test-results-header" phx-hook="TestResults" data-testid={@test.id}>
          <%= @test.title %></h3>
          <%= if @test.author != nil do %>
            <h6 class="header-typographica">By <%= @test.author %></h6>
          <% end %>
        </div>
        <div class="col-sm-6 text-start text-sm-end pt-1 pt-sm-3">
          <span class="fs-7 text-muted header-texgyreadventor">Test taken <strong><%= get_number_of_tests_taken(@ranks, @identifications) %></strong> times</span>
        </div>
      </div>

      <%= if @test.description != nil do %>
        <%= if @view_description == false do %>
          <div class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_description">View description&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></div>
        <% else %>
          <div class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_description">Hide description&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></div>
          <TestDescriptionComponent.format wrapper_class="my-2 p-3 test-description" description_markdown={@test.description_markdown} description={@test.description} />
        <% end %>
      <% end %>

      <h4 class="mt-3 header-neon">Ranking</h4>

      <%= if @test.ranking == true do %>
        <div class="tracks my-2 mb-4 track-results results">
          <%= if Kernel.length(@ranks) == 0 do %>
            <div class="alert alert-info alert-thin">No ranking done ... yet!</div>
          <% end %>
          <%= for rank <- @ranks do %>
            <div class="track my-1 d-flex flex-wrap justify-content-between align-items-center" phx-click={JS.dispatch(if @play_track_id == rank.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => rank.track_id, "track_url" => get_track_url(rank.track_id, @test)})}>
              <div class="p-2">
                <button type="button" class="btn btn-dark px-2">
                  <%= if @play_track_id == rank.track_id do %>
                    <i class="bi bi-stop-fill"></i>
                  <% else %>
                    <i class="bi bi-play-fill"></i>
                  <% end %>
                </button>
              </div>
              <div class="p-2">
                <%= if (rank.rank < 4) do %>
                  <i class={"bi bi-trophy-fill trophy-#{rank.rank}"}></i>
                <% else %>
                  #<%= rank.rank %>
                <% end %>
              </div>
              <div class="p-2 flex-grow-1 text-truncate cursor-link"><%= rank.track_title %></div>
              <div class="d-flex flex-grow-1 justify-content-end align-items-center">
              <%= if @visitor_ranking != %{} do %>
                <div class="p-3 flex-grow-1 text-sm-end text-start pe-5"><small>You ranked this track: #<%= @visitor_ranking[rank.track_id] %></small></div>
              <% end %>
              <div class="p-3 ps-0 text-end">
                <%= rank.count %> votes as #<%= rank.rank %>
              </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <%= if @test.identification == true do %>
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
            <div class={"track my-1 #{if (i > 1), do: "mt-4"} d-flex flex-wrap align-items-center"} phx-click={JS.dispatch(if @play_track_id == identification.track_id do "stop" else "play" end, to: "body", detail: %{"track_id" => identification.track_id, "track_url" => get_track_url(identification.track_id, @test)})}>
              <div class="p-2">
                <button type="button" class="btn btn-dark px-2">
                  <%= if @play_track_id == identification.track_id do %>
                    <i class="bi bi-stop-fill"></i>
                  <% else %>
                    <i class="bi bi-play-fill"></i>
                  <% end %>
                </button>
              </div>
              <div class="p-2">
                <%= if (i < 4) do %>
                  <i class={"bi bi-trophy-fill trophy-#{i}"}></i>
                <% else %>
                  #<%= i %>
                <% end %>
              </div>
              <div class="p-2 flex-grow-1 cursor-link"><%= identification.title %></div>
                <div class="p-3 flex-grow-1 text-end text-truncate">
                  <%= if @visitor_identification != %{} do %>
                    <%= if identification.track_id == @visitor_identification[identification.track_id] do %>
                      <i class="bi bi-check color-correct"></i> You identified this track correctly!
                    <% else %>
                      <i class="bi bi-x color-incorrect"></i> You identified this track as <%= get_track_from_id(@visitor_identification[identification.track_id], @test.tracks).title  %>
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
      <% end %>
    """
  end

  # Password given by query string / url
  @impl true
  def mount(%{"slug" => slug, "key" => key} = params, %{}, socket) do
    test = Tests.get_by_slug(slug)
    # will throw an error if password is incorrect
    true = test.password == key

    params
    |> Map.delete("key")
    |> mount(%{}, socket)
  end

  @impl true
  def mount(%{"slug" => slug} = _params, session, socket) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         true <-
           Map.get(session, "test_taken_" <> slug, false) or
          (Map.get(session, "current_user_id") == test.user_id and test.user_id != nil) do

      ranks = Ranks.get_ranks(test)
      identifications = Identifications.get_identification(test)

      FunkyABXWeb.Endpoint.subscribe(test.id)

      {:ok,
       assign(socket, %{
         page_title: "Test results - " <> String.slice(test.title, 0..@title_max_length),
         test: test,
         current_user_id: Map.get(session, "current_user_id"),
         ranks: ranks,
         identifications: identifications,
         identification_detail: false,
         view_description: false,
         visitor_ranking: %{},
         visitor_identification: %{},
         visitor_identification_score: nil,
         play_track_id: nil
       })}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Please take the test before checking the results.")
         |> assign(test_already_taken: false)
         |> redirect(to: Routes.test_public_path(socket, FunkyABXWeb.TestLive, slug))}
    end
  end

  @impl true
  def handle_event("test_not_taken", _params, socket) do
    with false <- socket.assigns.current_user_id == socket.assigns.test.user_id do
      {:noreply,
       socket
       |> redirect(
         to:
           Routes.test_public_path(
             socket,
             FunkyABXWeb.TestLive,
             socket.assigns.test.slug
           )
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  # ---------- EVENTS ----------

  @impl true
  def handle_event("results", params, socket) do
    {:noreply,
      socket
      |> assign(:visitor_ranking, Map.get(params, "ranking", %{}))
      |> assign(:visitor_identification, Map.get(params, "identification", %{}))
      |> assign(
           :visitor_identification_score,
           calculate_identification_score(Map.get(params, "identification", %{}))
         )}
  end

  # ---------- PLAYER ----------

  @impl true
  def handle_event("playing",  %{"track_id" => track_id} = _params, socket) do
    {:noreply, assign(socket, :play_track_id, track_id)}
  end

  @impl true
  def handle_event("stopping", _params, socket) do
    {:noreply, assign(socket, :play_track_id, nil)}
  end

  # ---------- UI ----------

  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
  end

  def handle_event("toggle_identification_detail", _value, socket) do
    toggle = !socket.assigns.identification_detail

    {:noreply, assign(socket, identification_detail: toggle)}
  end

  # ---------- PUB/SUB EVENTS ----------

  @impl true
  def handle_info(%{event: "test_updated"} = _payload, socket) do
    test = Tests.get(socket.assigns.test.id)

    {:noreply,
     assign(socket, %{
       test: test
     })}
  end

  @impl true
  def handle_info(%{event: "test_taken"} = _payload, socket) do
    ranks = Ranks.get_ranks(socket.assigns.test)
    identifications = Identifications.get_identification(socket.assigns.test)

    {:noreply,
     assign(socket, %{
       ranks: ranks,
       identifications: identifications
     })}
  end

  @impl true
  def handle_info(%{event: "test_deleted"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "This test has been deleted :(")
     |> redirect(
       to:
         Routes.info_path(
           socket,
           FunkyABXWeb.FlashLive
         )
     )}
  end

  @impl true
  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
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

  def get_number_of_tests_taken(rankings, identifications) do
    Tests.get_how_many_taken(rankings, identifications)
  end

  def percent_of(count, total) do
    Float.round(count * 100 / total)
  end

  def get_track_from_id(id, tracks) do
    Enum.find(tracks, fn t -> t.id == id end)
  end

  def get_track_url(track_id, test) do
    track_id
    |> get_track_from_id(test.tracks)
    |> Tracks.get_media_url(test)
  end
end
