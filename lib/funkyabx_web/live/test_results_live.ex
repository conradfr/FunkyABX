defmodule FunkyABXWeb.TestResultsLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use FunkyABXWeb, :live_view
  alias FunkyABX.Tests
  alias FunkyABX.Ranks
  alias FunkyABX.Identifications
  alias FunkyABX.Test

  @title_max_length 100

  def render(assigns) do
    ~H"""
      <h3 class="mb-0"><%= @test.title %></h3>
      <%= if @test.author != nil do %>
        <h6>
          By <%= @test.author %>
        </h6>
      <% end %>

      <h4 class="mt-4">Ranking</h4>

      <div class="tracks my-2 mb-4 results">
        <%= for rank <- @ranks do %>
          <div class="track my-1 d-flex align-items-center">
            <div class="p-3">
              <%= if (rank.rank < 4) do %>
                <i class={"bi bi-trophy-fill trophy-#{rank.rank}"}></i>
              <% else %>
                #<%= rank.rank %>
              <% end %>
            </div>
            <div class="p-2 flex-grow-1"><%= rank.track_title %></div>
              <div class="p-3 ps-0 text-end">
                <%= rank.count %> votes as #<%= rank.rank %>
              </div>
          </div>
        <% end %>
      </div>

      <h4 class="mt-4">Identification</h4>

      <div class="tracks my-2 results">
        <%= for track <- @test.tracks do %>
          <div class="track my-1 d-flex align-items-center">
            <div class="p-3">
              #1
            </div>
            <div class="p-2 flex-grow-1"><%= track.title %></div>
            <div class="p-3 ps-0 text-end">
              <%= get_top_identified(track, @identifications_denorm) |> Map.get(:track_guessed_title) %>
            </div>
            <div class="p-3 ps-0 text-end">
              <%= get_top_identified(track, @identifications_denorm) |> Map.get(:vote_percent) %>%
            </div>
          </div>
          <%= for guess <- get_tail_identified(track, @identifications_denorm) do %>
            <div class="track-guess d-flex align-items-center justify-content-end">
              <div class="p-3 ps-0 text-end">
                <%= guess.track_guessed_title %>
              </div>
              <div class="p-3 ps-0 text-end">
                <%= guess.vote_percent %>%
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    """
  end

  def mount(%{"slug" => slug, "key" => _key} = _params, %{}, socket) do
    test = Tests.get(slug)
    ranks = Ranks.get_ranks(test)
    identifications = Identifications.get_identification(test)
    identifications_denorm = identifications_denorm(test.tracks, identifications)

    {:ok,
     assign(socket, %{
       page_title: "Test results - " <> String.slice(test.title, 0..@title_max_length),
       test: test,
       ranks: ranks,
       identifications: identifications,
       identifications_denorm: identifications_denorm
     })}
  end

  def mount(%{"slug" => slug} = _params, %{}, socket) do
    test = Tests.get(slug)
    ranks = Ranks.get_ranks(test)
    identifications = Identifications.get_identification(test)
    identifications_denorm = identifications_denorm(test.tracks, identifications)

    {:ok,
     assign(socket, %{
       page_title: "Test results - " <> String.slice(test.title, 0..@title_max_length),
       test: test,
       ranks: ranks,
       identifications: identifications,
       identifications_denorm: identifications_denorm
     })}
  end

  # ---------- VIEW HELPERS ----------

  def identifications_denorm(tracks, identifications) do
    tracks
    |> Enum.map(fn t ->
      identifications_this_track = Enum.filter(identifications, fn i -> t.id == i.track_id end)
      total_votes = Enum.reduce(identifications_this_track, 0, fn i, acc -> acc + i.count end)

      identifications_this_track
      |> Enum.map(fn i ->
        track_guessed = get_track_from_id(i.track_guessed_id, tracks)

        %{
          track_id: i.track_id,
          vote_percent: Float.round(i.count * 100 / total_votes),
          track_guessed_id: track_guessed.id,
          track_guessed_title: track_guessed.title
        }
      end)
    end)
    |> Map.new(fn x ->
      track_id = x |> List.first() |> Map.get(:track_id)
      {track_id, x}
    end)
  end

  def get_top_identified(track, identifications) do
    # should be already sorted by the sql query
    identifications
    |> Map.get(track.id)
    |> List.first()
  end

  def get_tail_identified(track, identifications) do
    # should be already sorted by the sql query
    list =
      identifications
      |> Map.get(track.id)

    [_ | tail] = list
    tail
  end

  def get_track_from_id(id, tracks) do
    Enum.find(tracks, fn t -> t.id == id end)
  end

  def get_guess_class(track_id, guess_id) do
    if track_id == guess_id do
      " track-correct"
    else
      " track-wrong"
    end
  end
end
