defmodule FunkyABXWeb.TestLive do
  require Logger
  use FunkyABXWeb, :live_view
  alias Phoenix.LiveView.JS
  alias FunkyABX.Test
  alias FunkyABX.Tests
  alias FunkyABX.Tracks

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
      <div class="row">
        <div class="col-sm-6">
          <h3 class="mb-0 header-typographica" id="test-header" phx-hook="Test" data-testid={@test.id}>
            <%= @test.title %>
          </h3>
          <%= if @test.author != nil do %>
            <h6 class="header-typographica">By <%= @test.author %></h6>
          <% end %>
        </div>
        <div class="col-sm-6 text-start text-sm-end pt-1">
            <div class="fs-7 text-muted header-texgyreadventor">Test taken <strong><%= @test_taken_times %></strong> times</div>
          <.live_component module={TestFlagComponent} id="flag" test={@test} />
        </div>
      </div>

      <%= if @test.description != nil do %>
        <TestDescriptionComponent.format wrapper_class="mt-2 p-3 test-description" description_markdown={@test.description_markdown} description={@test.description} />
      <% end %>

      <%= if @view_tracklist == false do %>
        <div class="fs-8 mt-2 mb-2 cursor-link text-muted" phx-click="toggle_tracklist">Tracklist&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></div>
      <% else %>
        <div class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_tracklist">Hide tracklist&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></div>
        <div class="test-tracklist mt-2 mb-4 p-3 py-2">
          <%= for {track, i} <- @test.tracks |> Enum.with_index(1) do %>
            <div class="test-tracklist-one"><%= i %>.&nbsp;&nbsp;<%= track.title %></div>
          <% end %>
        </div>
      <% end %>

      <form phx-change="change_player_settings">
      <div class="controls d-flex flex-wrap flex-row align-items-center"
        id="player-controls"
        phx-hook="Player"
        data-tracks={Tracks.to_json(@tracks, @test)}
        data-rotate-seconds={@rotate_seconds}
        data-rotate={to_string(@rotate)}
        data-loop={to_string(@loop)}
        data-waveform={to_string(@test_params.draw_waveform)}>
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
            <div class="spinner-border spinner-border-sm ms-2 text-muted" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
            <span class="text-muted ms-2"><small>Loading tracks ...</small></span>
          <% else %>
            <div class="ms-2 text-muted" role="status">
              <small><i class="bi bi-info-circle text-extra-muted" title="Player controls" role="button"
                data-bs-toggle="popover" data-bs-placement="auto" data-bs-html="true"
                data-bs-content="<strong>Mouse/touch:</strong><ul><li>Click on a track number to switch and/or start playing</li><li>Click on a waveform to go to a specific time</li></ul><strong>Keyboard shortcuts:</strong><ul><li>space: play/pause</li><li>arrows: previous/next</li><li>1-9: switch to track # (alt/option: +10)</li><li>ctrl+key: command + rewind</li><li>w: hide/show waveform</li></ul>">
              </i></small>
            </div>
          <% end %>
        </div>
        <%= if @test.nb_of_rounds > 1 do %>
          <div class="flex-grow-1 p-2 text-center">
            Round <%= @current_round %> / <%= @test.nb_of_rounds %>
          </div>
        <% end %>
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
            <div class="p-2">
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
              <%= if @test.anonymized_track_title == false do %>
                <div class="p-2 text-truncate cursor-link" style="width: 300px;" phx-click={JS.dispatch(if @current_track == track.hash and @playing == true do "stop" else "play" end, to: "body", detail: %{"track_hash" => track.hash})}>
                  <%= track.title %>
                </div>
              <% else %>
                <div class="p-2 cursor-link" style="min-width: 100px" phx-click={JS.dispatch(if @current_track == track.hash and @playing == true do "stop" else "play" end, to: "body", detail: %{"track_hash" => track.hash})}>
                  Track <%= i %>
                </div>
              <% end %>
            <div class="flex-grow-1 px-2 px-md-3" style="min-width: 100px" id={"waveform-#{Tracks.get_track_hash(track)}"}>
              <div phx-update="ignore" id="waveform-wrapper" class="waveform-wrapper">
              </div>
            </div>

            <%= unless @test_already_taken == true do %>
              <%= for module <- @choices_modules do %>
                <.live_component module={module} id={Atom.to_string(module) <> "_#{i}"} track={track} test={@test} tracks={@tracks} choices_taken={@choices_taken} round={@current_round} />
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>

      <%= unless @test_params.has_choices == false do %>
        <div class="mt-3">
          <div class="d-flex flex-row align-items-center justify-content-between">
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
    test = Tests.get_by_slug(slug)
    changeset = Test.changeset(test)
    test_params = Tests.get_test_params(test)

    tracks =
      test.tracks
      |> Tracks.prep_tracks(test)
      |> Tests.prep_tracks(test)

    choices_modules = Tests.get_choices_modules(test)

    FunkyABXWeb.Endpoint.subscribe(test.id)

    {:ok,
     assign(socket, %{
       page_title: String.slice(test.title, 0..@title_max_length),
       ip_address: Map.get(session, "visitor_ip", nil),
       test: test,
       tracks: tracks,
       choices_modules: choices_modules,
       test_params: test_params,
       current_round: 1,
       tracks_loaded: false,
       current_track: nil,
       loop: true,
       rotate: true,
       rotate_seconds: 7,
       changeset: changeset,
       choices_taken: %{},
       playing: false,
       playingTime: 0,
       valid: false,
       flag_display: false,
       test_taken_times: Tests.get_how_many_taken(test),
       test_already_taken: Map.get(session, "test_taken_" <> slug, false),
       view_tracklist: test.description == nil
     })}
  end

  # ---------- PUB/SUB EVENTS ----------

  # Handling flash from children
  @impl true
  def handle_info({:flash, {status, text}}, socket) do
    {:noreply, put_flash(socket, status, text)}
  end

  @impl true
  def handle_info(%{event: "test_taken"} = _payload, socket) do
    {:noreply, assign(socket, :test_taken_times, socket.assigns.test_taken_times + 1)}
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

  # ---------- FROM COMPONENT ----------

  def handle_info({:update_choices_taken, round, params}, socket) do
    updated_choices_taken_round =
      socket.assigns.choices_taken
      |> Map.get(round, %{})
      |> Map.merge(params)

    updated_choices_taken =
      Map.merge(socket.assigns.choices_taken, %{round => updated_choices_taken_round})

    valid = Tests.is_valid?(socket.assigns.test, round, updated_choices_taken)
    {:noreply, assign(socket, %{choices_taken: updated_choices_taken, valid: valid})}
  end

  # ---------- PLAYER CLIENT ----------

  @impl true
  def handle_event("tracksLoaded", _params, socket) do
    {:noreply,
     socket
     |> assign(tracks_loaded: true)
     |> push_event("tracks_loaded", %{})}
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
    with true <- is_binary(rotate_seconds) and rotate_seconds != "",
         seconds <- String.to_integer(rotate_seconds) do
      {:noreply,
       socket
       |> assign(rotate_seconds: rotate_seconds)
       |> push_event("rotateSeconds", %{seconds: seconds})}
    else
      _ ->
        {:noreply, socket}
    end
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

  # ---------- TEST ----------

  @impl true
  def handle_event("test_already_taken", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "You have already taken this test.")
     |> assign(test_already_taken: true)}
  end

  # When there is more than one round, go to next when valid instead of submit
  @impl true
  def handle_event("submit", _params, %{assigns: %{current_round: current_round}} = socket)
      when current_round < socket.assigns.test.nb_of_rounds do
    with test <- socket.assigns.test,
         choices <- socket.assigns.choices_taken,
         true <- Tests.is_valid?(test, current_round, choices) do
      tracks =
        test.tracks
        |> Tracks.prep_tracks(test)
        |> Tests.prep_tracks(test)

      {:noreply,
       socket
       |> push_event("update_tracks", %{tracks: Tracks.to_json(tracks, test)})
       |> assign(
         current_round: current_round + 1,
         tracks: tracks,
         valid: false,
         current_track: nil,
         tracks_loaded: false
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit", _params, %{assigns: %{current_round: current_round}} = socket) do
    with test <- socket.assigns.test,
         tracks <- socket.assigns.tracks,
         choices <- socket.assigns.choices_taken,
         true <- Tests.is_valid?(test, current_round, choices) do
      Logger.info("Test taken")

      choices_cleaned = Tests.clean_choices(choices, tracks, test)

      Tests.submit(test, choices_cleaned, socket.assigns.ip_address)

      FunkyABXWeb.Endpoint.broadcast!(test.id, "test_taken", nil)
      FunkyABX.Notifier.Email.test_taken(test, socket)

      Process.send_after(
        self(),
        {:redirect_results,
         Routes.test_results_public_path(
           socket,
           FunkyABXWeb.TestResultsLive,
           test.slug
         )},
        1000
      )

      {:noreply,
       socket
       |> push_event("store_test", choices_cleaned)
       # |> push_redirect(
       #     to: Routes.test_results_public_path(socket, FunkyABXWeb.TestResultsLive, socket.assigns.test.slug),
       #     replace: true
       # )
       |> put_flash(:success, "Your submission has been registered!")}
    else
      _ -> {:noreply, socket}
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

  # ---------- UI ----------

  def handle_event("toggle_tracklist", _value, socket) do
    toggle = !socket.assigns.view_tracklist

    {:noreply, assign(socket, view_tracklist: toggle)}
  end
end
