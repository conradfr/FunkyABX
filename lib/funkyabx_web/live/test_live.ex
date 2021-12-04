defmodule FunkyABXWeb.TestLive do
  use FunkyABXWeb, :live_view
  alias Phoenix.LiveView.JS
  alias FunkyABX.Tests
  alias FunkyABX.Tracks
  alias FunkyABX.Test

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
      <.live_component module={TestFlag} id="flag" test={@test} />
      <h3 class="mb-0 header-typographica" id="test-header" phx-hook="Test" data-testid={@test.id}>
        <%= @test.title %>
      </h3>
      <%= if @test.author != nil do %>
        <h6 class="header-typographica">By <%= @test.author %></h6>
      <% end %>
      <%= if @test.description != nil do %>
        <TestDescription.format wrapper_class="my-3 p-3 test-description" description_markdown={@test.description_markdown} description={@test.description} />
      <% end %>

      <form phx-change="change_player_settings">
      <div class="controls d-flex flex-wrap flex-row align-items-center"
        id="player-controls"
        phx-hook="Player"
        data-tracks={Tracks.to_json(@tracks, @test)}
        data-rotate-seconds={@rotate_seconds}
        data-rotate={to_string(@rotate)}
        data-loop={to_string(@loop)}>
        <div class="p-2 me-auto d-flex align-items-center">
          <button type="button" phx-click={JS.dispatch("back", to: "body")} class={"btn btn-dark px-2 me-1#{if @tracks_loaded == false, do: " disabled"}"}>
            <i class="bi bi-skip-start-fill"></i>
          </button>
          <%= if @playing == true do %>
            <button type="button" phx-click={JS.dispatch("pause", to: "body")} class="btn btn-success me-1">
              <i class="bi bi-pause-fill"></i>&nbsp;&nbsp;&nbsp;Pause&nbsp;&nbsp;
            </button>
          <% else %>
            <button type="button" phx-click={JS.dispatch("play", to: "body")} class={"btn btn-secondary header-typographica btn-play me-1#{if @tracks_loaded == false, do: " disabled"}"}>
              <i class="bi bi-play-fill"></i>&nbsp;&nbsp;&nbsp;Play&nbsp;&nbsp;
            </button>
          <% end %>
          <button type="button" phx-click={JS.dispatch("stop", to: "body")} class={"btn btn-dark px-2 me-1#{if @tracks_loaded == false, do: " disabled"}"}>
            <i class="bi bi-stop-fill"></i>
          </button>
          <%= if @tracks_loaded == false do %>
            <div class="track-loader text-muted ms-2">
              <div class="refresh-animate">
                <i class="bi bi-arrow-repeat"></i>
              </div>
            </div>
          <% end %>
        </div>
        <div class="p-2">
          <fieldset class="form-group">
            <div class="form-check">
              <input class="form-check-input disabled" type="checkbox" id="inputLoopCheckbox" name="inputLoopCheckbox" checked={@loop}>
              <label class="form-check-label" for="inputLoopCheckbox">
                Loop
              </label>
          </div>
          </fieldset>
        </div>
        <div class="p-2">
          <div class="d-flex align-items-center">
            <div class="p-2">
              <fieldset class="form-group">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="inputRotateCheckbox" name="inputRotateCheckbox" checked={@rotate}>
                  <label class="form-check-label" for="inputRotateCheckbox">
                    Switch track every
                  </label>
                </div>
              </fieldset>
            </div>
            <div class="p-2">
              <input type="number" name="rotate-seconds" class="form-control form-control-sm" value={@rotate_seconds} style="width: 65px" min="3" max="3600">
            </div>
            <div class="p-2">
              seconds
            </div>
          </div>
        </div>
      </div>
      </form>

      <div class="tracks my-2">
        <%= for {track, i} <- @tracks |> Enum.with_index(1) do %>
          <div class={"track my-1 d-flex flex-wrap flex-md-nowrap align-items-center #{if @current_track == track.hash, do: "track-active"}"}>
            <div class="p-3">
              <%= if @current_track == track.hash and @playing == true do %>
                <button type="button" class={"btn btn-dark px-2 #{if @current_track == track.hash, do: "btn-track-active"}"} phx-click={JS.dispatch("pause", to: "body")}>
                  <i class="bi bi-pause-fill"></i>
                </button>
              <% else %>
                <button type="button" class={"btn btn-dark px-2 #{if @current_track == track.hash, do: "btn-track-active"}"} phx-click={JS.dispatch("play", to: "body", detail: %{"track_hash" => track.hash})}>
                  <i class={"bi bi-play-fill #{if @tracks_loaded == false, do: " text-muted"}"}></i>
                </button>
              <% end %>
            </div>
              <%= if @test.type === :listening do %>
                <div class="p-2 text-truncate cursor-link" style="width: 300px;" phx-click={JS.dispatch(if @current_track == track.hash and @playing == true do "stop" else "play" end, to: "body", detail: %{"track_hash" => track.hash})}>
                  <%= track.title %>
                </div>
              <% else %>
                <div class="p-2 cursor-link" style="min-width: 100px" phx-click={JS.dispatch(if @current_track == track.hash and @playing == true do "stop" else "play" end, to: "body", detail: %{"track_hash" => track.hash})}>
                  Track <%= i %>
                </div>
              <% end %>
            <div class="flex-grow-1 px-2 px-md-3" style="min-width: 100px">
              <div id={"wrapper-waveform-#{:crypto.hash(:md5 , track.id <> track.filename) |> Base.encode16()}"} class="waveform-wrapper">
              </div>
            </div>
            <%= unless (@test_already_taken == true) or (@test.type == :listening) do %>
              <%= if @test.ranking == true do %>
                <div class="p-2 d-flex flex-row align-items-center flex-grow-1 flex-md-grow-0">
                    <div class="me-auto flex-grow-1 flex-md-grow-0">
                      <span class="me-3 text-muted"><small>I rank this track ...</small></span>
                    </div>
                    <div class=" p-0 p-md-3 flex-fill">
                      <form phx-change="change_ranking">
                        <input name="track[id]" type="hidden" value={track.id}>
                        <select class="form-select" name="rank">
                          <%= options_for_select([""] ++ Enum.to_list(1..Kernel.length(@test.tracks)), Map.get(@ranking, track.id, "")) %>
                        </select>
                      </form>
                    </div>
                </div>
              <% end %>
              <%= if @test.identification == true do %>
                <div class="p-2 d-flex flex-row align-items-center flex-grow-1 flex-md-grow-0">
                  <div class="me-auto ms-0 ms-md-3 flex-fill text-start text-md-end">
                    <span class="me-2 text-muted"><small>I think this is ...</small></span>
                  </div>
                  <div class="me-auto p-0 p-md-3 ps-0 flex-grow-1 flex-md-grow-0">
                    <form phx-change="change_identification">
                      <input name="track[id]" type="hidden" value={track.id}>
                      <select class="form-select" name="guess">
                        <%= options_for_select([""] ++ Enum.map(@tracks |> Enum.sort_by(&Map.fetch(&1, :title)), fn x -> {x.title, x.fake_id} end), Map.get(@identification, track.fake_id, "")) %>
                      </select>
                    </form>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= unless @test.type == :listening do %>
        <div class="mt-3">
          <div class="d-flex flex-row align-items-center justify-content-between">
            <div class="me-2">
              <small><i class="bi bi-info-circle text-muted" title="Player controls" role="button"
                data-bs-toggle="popover" data-bs-placement="auto"  data-bs-html="true"
                data-bs-content="<strong>Mouse/touch:</strong><ul><li>Click on a track number to switch and/or start playing</li><li>Click on a waveform to go to a specific time</li></ul><strong>Keyboard shortcuts:</strong><ul><li>space: play/pause</li><li>arrows: previous/next</li><li>1-9: switch to track #</li><li>ctrl+key: command + rewind</li></ul>">
              </i></small>
            </div>
            <%= unless @test_already_taken == true do %>
              <div class="px-1">
                <button phx-click="no_participate" class="btn btn-sm btn-outline-dark" data-confirm="Are you sure you want to check the results? You won't be able to participate afterwards.">Check the results without participating</button>
              </div>
              <div class="text-end px-1 flex-fill">
                <button phx-click="submit" class={"btn btn-primary#{unless (@valid == true) do " disabled" else "" end}"}>Submit my choices</button>
              </div>
            <% else %>
              <div class="text-end px-1 flex-fill">
                <%= link "Check the results", to: Routes.test_results_public_path(@socket, FunkyABXWeb.TestResultsLive, @test.slug), class: "btn btn-primary" %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    """
  end

  @impl true
  def mount(%{"slug" => slug} = _params, session, socket) do
    #    with false <- Map.get(session, "test_taken_" <> slug, false) do
    ip_address =
      case get_connect_info(socket) do
        nil -> nil
        info -> info.peer_data.address
      end

    test = Tests.get_by_slug(slug)
    changeset = Test.changeset(test)

    tracks =
      test.tracks
      |> Enum.map(fn t ->
        %{
          t
          | fake_id: :rand.uniform(1_000_000),
            hash: :crypto.hash(:md5, t.id <> t.filename) |> Base.encode16(),
            width: "0"
        }
      end)
      |> Enum.shuffle()

    FunkyABXWeb.Endpoint.subscribe(test.id)

    {:ok,
     assign(socket, %{
       page_title: String.slice(test.title, 0..@title_max_length),
       ip: ip_address,
       test: test,
       tracks: tracks,
       tracks_loaded: false,
       current_track: nil,
       loop: true,
       rotate: true,
       rotate_seconds: 7,
       changeset: changeset,
       ranking: %{},
       identification: %{},
       playing: false,
       playingTime: 0,
       valid: false,
       flag_display: false,
       #          test_already_taken: false
       test_already_taken: Map.get(session, "test_taken_" <> slug, false)
     })}

    #    else
    #      _ ->
    #        # Test taken, redirect to results
    #        {:ok,
    #          socket
    #          |> put_flash(:info, "You have already taken this test.")
    #          |> assign(test_already_taken: true)
    #          |> redirect(to: Routes.test_results_public_path(socket, FunkyABXWeb.TestResultsLive, slug))
    #        }
    #    end
  end

  # ---------- PUB/SUB EVENTS ----------

  # Handling flash from children
  @impl true
  def handle_info({:flash, {status, text}}, socket) do
    {:noreply, put_flash(socket, status, text)}
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
  def handle_info(%{event: "test_updated"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Test has been updated by its creator, so the page has been reloaded.")
     |> redirect(
       to:
         Routes.test_public_path(
           socket,
           FunkyABXWeb.TestLive,
           socket.assigns.test.slug
         )
     )}
  end

  @impl true
  def handle_info({:skip_to_results, url} = _payload, socket) do
    {:noreply,
      socket
      |> redirect(to: url)}
  end

  @impl true
  def handle_info({:redirect_results, url} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:success, "Your submission has been registered!")
     |> redirect(to: url)}
  end

  @impl true
  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("test_already_taken", _params, socket) do
    {:noreply,
      socket
      |> put_flash(:info, "You have already taken this test.")
      |> assign(test_already_taken: true)}
  end

  # ---------- PLAYER CLIENT ----------

  @impl true
  def handle_event("tracksLoaded", _params, socket) do
    {:noreply, assign(socket, tracks_loaded: true)}
  end

  @impl true
  def handle_event("playing", _params, socket) do
    {:noreply, assign(socket, playing: true)}
  end

  @impl true
  def handle_event("stopping", _params, socket) do
    {:noreply, assign(socket, playing: false)}
  end

  @impl true
  def handle_event("currentTrackHash", %{"track_hash" => track_hash} = _params, socket) do
    {:noreply, assign(socket, current_track: track_hash)}
  end

  @impl true
  def handle_event("currentTrackHash", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("updatePlayerTime", %{"time" => playing_time} = _params, socket) do
    {:noreply, assign(socket, playingTime: playing_time)}
  end

  # ---------- PLAYER SETTINGS ----------

  @impl true
  def handle_event(
        "change_player_settings",
        %{"_target" => ["rotate-seconds"], "rotate-seconds" => rotate_seconds} = _player_params,
        socket
      ) do
    {:noreply,
     socket
     |> assign(rotate_seconds: rotate_seconds)
     |> push_event("rotateSeconds", %{seconds: String.to_integer(rotate_seconds)})}
  end

  @impl true
  def handle_event(
        "change_player_settings",
        %{"_target" => ["inputRotateCheckbox"]} = player_params,
        socket
      ) do
    rotate = Map.has_key?(player_params, "inputRotateCheckbox")

    {:noreply,
     socket
     |> assign(rotate: rotate)
     |> push_event("rotate", %{rotate: rotate})}
  end

  @impl true
  def handle_event(
        "change_player_settings",
        %{"_target" => ["inputLoopCheckbox"]} = player_params,
        socket
      ) do
    loop = Map.has_key?(player_params, "inputLoopCheckbox")

    {:noreply,
     socket
     |> assign(loop: loop)
     |> push_event("loop", %{loop: loop})}
  end

  #  def handle_event("change_player_settings", player_params, socket) do
  #    IO.puts "#{inspect player_params}"
  #    {:noreply, socket}
  #  end

  # ---------- TEST ----------

  @impl true
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

    {:noreply,
     socket |> assign(ranking: ranking_updated) |> (&assign(&1, valid: is_valid(&1.assigns))).()}
  end

  @impl true
  def handle_event(
        "change_identification",
        %{"track" => %{"id" => track_id}} = identification_params,
        socket
      ) do
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

    {:noreply,
     socket
     |> assign(identification: identification_updated)
     |> (&assign(&1, valid: is_valid(&1.assigns))).()}
  end

  @impl true
  def handle_event("submit", _params, socket) do
    params =
      if is_ranking_valid?(socket.assigns.ranking, socket.assigns.test) == true and
           is_identification_valid?(socket.assigns.identification, socket.assigns.test) == true do
        params_ranking =
          unless socket.assigns.ranking == false do
            Tests.submit_ranking(socket.assigns.test, socket.assigns.ranking, socket.assigns.ip)
            socket.assigns.ranking
          else
            %{}
          end

        params_identification =
          unless socket.assigns.identification == false do
            # match fake ids to the real track ids
            identification =
              socket.assigns.identification
              |> Enum.reduce(%{}, fn {track_fake_id, track_guess_fake_id}, acc ->
                track_id = find_track_id_from_fake_id(track_fake_id, socket.assigns.tracks)

                track_guess_id =
                  find_track_id_from_fake_id(track_guess_fake_id, socket.assigns.tracks)

                Map.put(acc, track_id, track_guess_id)
              end)

            Tests.submit_identification(
              socket.assigns.test,
              identification,
              socket.assigns.ip
            )

            identification
          else
            %{}
          end

        FunkyABXWeb.Endpoint.broadcast!(socket.assigns.test.id, "test_taken", nil)
        %{ranking: params_ranking, identification: params_identification}
      else
        nil
      end

    unless params == nil do
      Process.send_after(
        self(),
        {:redirect_results,
         Routes.test_results_public_path(
           socket,
           FunkyABXWeb.TestResultsLive,
           socket.assigns.test.slug
         )},
        1000
      )

      {:noreply,
       socket
       |> push_event("store_test", params)
       #        |> push_redirect(
       #            to: Routes.test_results_public_path(socket, FunkyABXWeb.TestResultsLive, socket.assigns.test.slug),
       #            replace: true
       #        )
       |> put_flash(:success, "Your submission has been registered!")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("no_participate", _params, socket) do
    Process.send_after(
      self(),
      {:skip_to_results,
        Routes.test_results_public_path(
          socket,
          FunkyABXWeb.TestResultsLive,
          socket.assigns.test.slug
        )},
      1000
    )

    {:noreply, push_event(socket, "bypass_test", %{})}
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
