defmodule FunkyABXWeb.TestLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use FunkyABXWeb, :live_view
  alias FunkyABX.Tests
  alias FunkyABX.Tracks
  alias FunkyABX.Test

  @title_max_length 100

  def render(assigns) do
    ~H"""
      <h3 class="mb-0 header-typographica"><%= @test.title %></h3>
      <%= if @test.author != nil do %>
        <h5 class="header-typographica">By <%= @test.author %></h5>
      <% end %>
      <%= if @test.description != nil do %>
        <div class="my-3 p-3 test-description">
          <%= raw(Earmark.as_html!(@test.description, escape: true, inner_html: true)) %>
        </div>
      <% end %>

      <form phx-change="change_player_settings">
      <div class="controls d-flex flex-row align-items-center"
        id="player-controls"
        phx-hook="Player"
        data-tracks={Tracks.to_json(@tracks, @test)}
        data-rotate-seconds={@rotate_seconds}
        data-rotate={to_string(@rotate)}
        data-loop={to_string(@loop)}
      >
        <div class="p-2 me-auto">
          <%= if @playing == true do %>
            <button type="button" phx-click="stop" class="btn btn-light">
              <i class="bi bi-pause-fill"></i> Pause
            </button>
          <% else %>
            <button type="button" phx-click="play" class="btn btn-secondary header-typographica btn-play">
              <i class="bi bi-play-fill"></i> Play
            </button>
          <% end %>
        </div>
        <div class="p-2">
          <fieldset class="form-group">
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="inputLoopCheckbox" name="inputLoopCheckbox" checked={to_string(@loop)}>
              <label class="form-check-label" for="inputLoopCheckbox">
                Loop
              </label>
          </div>
          </fieldset>
        </div>
        <div class="p-2">
          <fieldset class="form-group">
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="inputRotateCheckbox" name="inputRotateCheckbox" checked={to_string(@rotate)}>
              <label class="form-check-label" for="inputRotateCheckbox">
                Switch track every
              </label>
          </div>
          </fieldset>
        </div>
        <div class="p-2">
          <input type="number" name="rotate-seconds" class="form-control form-control-sm" value={@rotate_seconds} style="width: 65px" min="1" max="3600">
        </div>
        <div class="p-2">
          seconds
        </div>
      </div>
      </form>

      <div class="tracks my-2">
        <%= for {track, i} <- @tracks |> Enum.with_index(1) do %>
          <div class={"track my-1 d-flex align-items-center #{if @current_track == track.hash do "active" else "" end}"}>
            <div class="p-3"><i class="bi bi-play-fill"></i></div>
            <div class="p-2">Track <%= i %></div>
            <div class="flex-grow-1 px-5">
              <canvas class="waveform-canvas" id={"waveform-#{:crypto.hash(:md5 , track.id <> track.filename) |> Base.encode16()}"}>
                Your browser is too old!
              </canvas>
            </div>
            <%= if @test.ranking == true do %>
              <div class="me-auto">
                <span class="me-2">I rank this track ...</span>
              </div>
              <div class="p-3 ps-0">
                <form phx-change="change_ranking">
                  <input name="track[id]" type="hidden" value={track.id}>
                  <select class="form-select" name="rank">
                    <%= options_for_select([""] ++ Enum.to_list(1..Kernel.length(@test.tracks)), Map.get(@ranking, track.id, "")) %>
                  </select>
                </form>
              </div>
            <% end %>
            <%= if @test.identification == true do %>
              <div class="me-auto ms-3">
                <span class="me-2">I think this is ...</span>
              </div>
              <div class="me-auto p-3 ps-0">
                <form phx-change="change_identification">
                  <input name="track[id]" type="hidden" value={track.id}>
                  <select class="form-select" name="guess">
                    <%= options_for_select([""] ++ Enum.map(@tracks, fn x -> {x.title, x.fake_id} end), Map.get(@identification, track.fake_id, "")) %>
                  </select>
                </form>
              </div>
            <% end %>
          </div>
        <% end %>
        <div class="mt-3 text-end">
          <button phx-click="submit" class={"btn btn-primary#{unless (@valid == true) do " disabled" else "" end}"}>Submit my choices</button>
        </div>
      </div>
    """
  end

  def mount(%{"slug" => slug} = _params, %{}, socket) do
    ip_address =
      case get_connect_info(socket) do
        nil -> nil
        info -> info.peer_data.address
      end

    test = Tests.get(slug)
    changeset = Test.changeset(test)
    tracks =
      test.tracks
      |> Enum.map(fn t ->
        %{t | fake_id: :rand.uniform(1000000), hash: :crypto.hash(:md5 , t.id <> t.filename) |> Base.encode16()}
      end)
      |> Enum.shuffle()

    {:ok,
     assign(socket, %{
       page_title: String.slice(test.title, 0..@title_max_length),
       ip: ip_address,
       test: test,
       tracks: tracks,
       current_track: nil,
       loop: true,
       rotate: true,
       rotate_seconds: 5,
       changeset: changeset,
       ranking: %{},
       identification: %{},
       playing: false,
       playingTime: 0,
       valid: false
     })}
  end

  # ---------- PLAYER ----------

  def handle_event("play", _params, socket) do
    {:noreply, push_event(socket, "play", %{})}
  end

  def handle_event("playing", _params, socket) do
    {:noreply, assign(socket, playing: true)}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, push_event(socket, "stop", %{})}
  end

  def handle_event("stopping", _params, socket) do
    {:noreply, assign(socket, playing: false)}
  end

  def handle_event("currentTrackHash", %{"track_hash" => track_hash} = _params, socket) do
    IO.puts("salut")
    IO.puts("#{inspect(track_hash)}")
    {:noreply, assign(socket, current_track: track_hash)}
  end

  def handle_event("currentTrackHash", params, socket) do
    IO.puts("wat")
    IO.puts("#{inspect(params)}")
    {:noreply, socket}
  end

  def handle_event("updatePlayerTime", %{"time" => playingTime} = _params, socket) do
    {:noreply, assign(socket, playingTime: playingTime)}
  end

  # ---------- PLAYER SETTINGS ----------

  def handle_event(
        "change_player_settings",
        %{"_target" => ["rotate-seconds"], "rotate-seconds" => rotate_seconds} = _player_params,
        socket
      ) do
    {:noreply, push_event(socket, "rotateSeconds", %{seconds: String.to_integer(rotate_seconds)})}
  end

  def handle_event(
        "change_player_settings",
        %{"_target" => ["inputRotateCheckbox"]} = player_params,
        socket
      ) do
    rotate = Map.has_key?(player_params, "inputRotateCheckbox")
    {:noreply, push_event(socket, "rotate", %{rotate: rotate})}
  end

  def handle_event(
        "change_player_settings",
        %{"_target" => ["inputLoopCheckbox"]} = player_params,
        socket
      ) do
    loop = Map.has_key?(player_params, "inputLoopCheckbox")
    {:noreply, push_event(socket, "loop", %{loop: loop})}
  end

  #  def handle_event("change_player_settings", player_params, socket) do
  #    IO.puts "#{inspect player_params}"
  #    {:noreply, socket}
  #  end

  # ---------- TEST ----------

  def handle_event("change_ranking", %{"track" => %{"id" => track_id}} = ranking_params, socket) do
    ranking_updated =
      case ranking_params["rank"] do
        rank when rank == "" ->
          Map.delete(socket.assigns.ranking, track_id)

        rank ->
          new_rank = String.to_integer(rank)

          socket.assigns.ranking
          |> Enum.find(nil, fn {_, value} -> value == new_rank end)
          |> case do
            nil ->
              socket.assigns.ranking
            {key, _} ->
              Map.delete(socket.assigns.ranking, key)
          end
          |> Map.put(track_id, new_rank)
      end

    {:noreply, socket |> assign(ranking: ranking_updated) |> (&(assign(&1, valid: is_valid(&1.assigns)))).() }
  end

  def handle_event("change_identification", %{"track" => %{"id" => track_id}} = identification_params, socket) do
    fake_id = find_fake_id_from_track_id(track_id, socket.assigns.tracks)

    identification_updated =
      case identification_params["guess"] do
        guess when guess == "" ->
          Map.delete(socket.assigns.identification, fake_id)

        guess ->
          guess_int = String.to_integer(guess)

          socket.assigns.identification
          |> Enum.find(nil, fn {_, value} -> value == guess_int end)
          |> case do
            nil -> socket.assigns.identification
            {key, _} -> Map.delete(socket.assigns.identification, key)
          end
          |> Map.put(fake_id, guess_int)
      end

    {:noreply, socket |> assign(identification: identification_updated) |> (&(assign(&1, valid: is_valid(&1.assigns)))).() }
  end

  def handle_event("submit", _params, socket) do
    if is_ranking_valid?(socket.assigns.ranking, socket.assigns.test) == true and
         is_identification_valid?(socket.assigns.identification, socket.assigns.test) == true do
      unless socket.assigns.ranking == false do
        Tests.submit_ranking(socket.assigns.test, socket.assigns.ranking, socket.assigns.ip)
      end

      unless socket.assigns.identification == false do
        # match fake ids to the real track ids
        identifications =
          socket.assigns.identification
          |> Enum.reduce(%{}, fn {track_id, track_guess_fake_id}, acc ->
            track_guess_id = find_track_id_from_fake_id(track_guess_fake_id, socket.assigns.tracks)
            Map.put(acc, track_id, track_guess_id)
          end)

        Tests.submit_identification(
          socket.assigns.test,
          identifications,
          socket.assigns.ip
        )
      end
    end

    {:noreply, socket}
  end

  # ---------- TEST UTILS ----------

  defp is_valid(assigns) do
    if is_ranking_valid?(assigns.ranking, assigns.test) == true and
       is_identification_valid?(assigns.identification, assigns.test) == true do
      true
    else
      false
    end
  end

  defp is_ranking_valid?(ranking, test) do
    case test.ranking do
      false ->
        true

      true ->
        case ranking
             |> Map.values()
             |> Enum.uniq()
             |> Enum.count() do
          count when count < Kernel.length(test.tracks) -> false
          _ -> true
        end
    end
  end

  defp is_identification_valid?(identification, test) do
    case test.identification do
      false ->
        true

      true ->
        case identification
             |> Map.values()
             |> Enum.count() do
          count when count < Kernel.length(test.tracks) -> false
          _ -> true
        end
    end
  end

  defp find_track_id_from_fake_id(fake_id, tracks) do
    tracks
    |> Enum.find(fn x -> x.fake_id == fake_id end)
    |> Map.get(:id)
  end

  defp find_fake_id_from_track_id(track_id, tracks) do
    tracks
    |> Enum.find(fn x -> x.id == track_id end)
    |> Map.get(:fake_id)
  end

end
