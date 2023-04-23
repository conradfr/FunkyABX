defmodule FunkyABXWeb.TestLive do
  require Logger
  use FunkyABXWeb, :live_view

  alias Ecto.UUID
  alias Phoenix.LiveView.JS
  alias FunkyABX.{Test, Tests, Tracks, Invitations}

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
      <div class="row">
        <div class="col-sm-6">
          <h3 class="mb-0 header-typographica" id="test-header" phx-hook="Test" data-testid={@test.id}>
            <%= @test.title %>
          </h3>
          <h6 :if={@test.author != nil} class="header-typographica"><%= dgettext "test", "By %{author}", author: @test.author %></h6>
        </div>
        <div :if={@test.local == false and @test.type != :listening} class="col-sm-6 text-start text-sm-end pt-1">
          <div class="fs-7 text-muted header-texgyreadventor"><%= raw dngettext "test", "Test taken <strong>%{count}</strong> time", "Test taken <strong>%{count}</strong> times", @test_taken_times %></div>
          <div :if={@test.local == false and @test.to_close_at_enabled == true and Tests.is_closed?(@test) == false} class="fs-7 text-muted header-texgyreadventor">
            <small><%= raw dgettext "test", "Test closing on <time datetime=\"%{to_close_at}\">%{to_close_at_format}</time>", to_close_at: @test.to_close_at, to_close_at_format: format_date(@test.to_close_at, @timezone) %></small>
          </div>

          <.live_component module={TestFlagComponent} id="flag" test={@test} />
        </div>
      </div>

      <TestDescriptionComponent.format :if={@test.description != nil} wrapper_class="mt-2 p-3 test-description" description_markdown={@test.description_markdown} description={@test.description} />

      <%= if @view_tracklist == false do %>
        <div class="fs-8 mt-2 mb-2 cursor-link text-muted" phx-click="toggle_tracklist">Tracklist&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></div>
      <% else %>
        <div class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_tracklist">Hide tracklist&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></div>
        <div class="test-tracklist-bg mt-2 mb-4 p-3 py-2">
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
                <i class="bi bi-pause-fill"></i>&nbsp;&nbsp;&nbsp;<%= dgettext "test", "Pause" %>&nbsp;&nbsp;
              </button>
            <% else %>
              <button type="button" phx-click={JS.dispatch("play", to: "body")} class={"btn btn-secondary header-typographica btn-play me-1#{if @tracks_loaded == false, do: " disabled"}"}>
                <i class="bi bi-play-fill"></i>&nbsp;&nbsp;&nbsp;<%= dgettext "test","Play" %>&nbsp;&nbsp;
              </button>
            <% end %>
            <button type="button" phx-click={JS.dispatch("stop", to: "body")} class={"btn btn-dark px-2 me-1#{if @tracks_loaded == false, do: " disabled"}"}>
              <i class="bi bi-stop-fill"></i>
            </button>
            <%= if @tracks_loaded == false do %>
              <div class="spinner-border spinner-border-sm ms-2 text-muted" role="status">
                <span class="visually-hidden"><%= dgettext "test", "Loading..." %></span>
              </div>
              <span class="text-muted ms-2"><small><%= dgettext "test", "Loading tracks ..." %></small></span>
            <% else %>
              <div class="ms-2 text-muted" role="status">
                <small><i class="bi bi-info-circle text-extra-muted" title={dgettext("test", "Player controls")} role="button"
                  data-bs-toggle="popover" data-bs-placement="auto" data-bs-html="true"
                  data-bs-content={dgettext("test", "<strong>Mouse/touch:</strong><ul><li>Click on a track number to switch and/or start playing</li><li>Click on a waveform to go to a specific time</li></ul><strong>Keyboard shortcuts:</strong><ul><li>space: play/pause</li><li>arrows: previous/next</li><li>1-9: switch to track # (alt/option: +10)</li><li>ctrl+key: command + rewind</li><li>w: hide/show waveform</li></ul>")}>
                </i></small>
              </div>
            <% end %>
          </div>
          <div :if={@test.local == false and @test.nb_of_rounds > 1} class="flex-grow-1 p-2 text-center">
            <%= dgettext "test", "Round %{current_round} / %{nb_of_rounds}", current_round: @current_round, nb_of_rounds: @test.nb_of_rounds %>
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
                      <%= dgettext "test", "Switch track every" %>
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
              <div class="p-2 cursor-link" style={"min-width: #{if @test.type == :listening, do: "300", else: "100"}px"} phx-click={JS.dispatch(if @current_track == track.hash and @playing == true do "stop" else "play" end, to: "body", detail: %{"track_hash" => track.hash})}>
                <%= dgettext "test", "Track %{track_index}", track_index: i %>
              </div>
            <% end %>

            <div class="flex-grow-1 px-2 px-md-3 " style="position: relative; min-width: 100px" id={"waveform-#{Tracks.get_track_hash(track)}"}>
              <div :if={@test.local == false and @tracks_loaded == false} class="track-loading-indicator text-muted">
                <small :if={get_track_state(track.hash, @tracks_state) == :loading}><%= dgettext "test", "Loading ... %{progress}%", progress: get_track_progress(track.hash, @tracks_loading) %></small>
                <small :if={get_track_state(track.hash, @tracks_state) == :decoding}><%= dgettext "test", "Decoding..." %>
                  <div class="spinner-grow spinner-grow-sm ms-2 text-muted" role="status">
                    <span class="visually-hidden"><%= dgettext "test", "Decoding..." %></span>
                  </div>
                </small>
                <small :if={get_track_state(track.hash, @tracks_state) == :finished}><%= dgettext "test", "Done " %> <i class="bi bi-check"></i></small>
                <small :if={get_track_state(track.hash, @tracks_state) == :error}><%= dgettext "test", "Error" %> <i class="bi bi-x-circle"></i></small>
              </div>
              <div phx-update="ignore" id={"waveform-wrapper-#{Tracks.get_track_hash(track)}"} class="waveform-wrapper"></div>
            </div>

            <%= unless @test_already_taken == true do %>
              <%= for module <- @choices_modules do %>
                <.live_component module={module} id={Atom.to_string(module) <> "_#{i}"} track={track} test={@test} tracks={@tracks} choices_taken={@choices_taken} round={@current_round} />
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="mt-3">
        <div class="d-flex flex-row align-items-center justify-content-between">
          <%= unless @test_params.has_choices == false do %>
            <div :if={@test.local == true} class="results-actions">
              <i :if={@tracks_loaded == true} class="bi bi-arrow-left color-action"></i>&nbsp;<.link navigate={~p"/local_test/edit/#{@test_data}"} replace={true}><%= dgettext "test", "Go back to the test form" %></.link>
            </div>
            <div :if={@test.local == true} class="results-actions">
              <i class="bi bi-plus color-action"></i>&nbsp;<.link href={~p"/local_test"} class="color-action"><%= dgettext "test", "Create a new local test" %></.link>
            </div>
            <%= unless @test_already_taken == true or Tests.is_closed?(@test) == true do %>
              <%= unless @test.local == true do %>
                <div class="px-1">
                  <button phx-click="no_participate" class="btn btn-sm btn-outline-dark" data-confirm={dgettext("test", "Are you sure you want to check the results? You won't be able to participate afterwards.")}><%= gettext "Check the results without participating" %></button>
                </div>
              <% end %>
            <div class="text-end px-1 _flex-fill">
              <button phx-click="submit" class={"btn btn-primary#{unless (@valid == true), do: " disabled"}"}><%= dgettext "test", "Submit my choices" %></button>
            </div>
            <% else %>
              <div class="text-end px-1 flex-fill">
                <.link :if={@test.local == false} href={~p"/results/#{@test.slug}"} class="btn btn-primary"><%= dgettext "test", "Check the results" %></.link>
              </div>
            <% end %>
          <% else %>
            <div class="px-1">
              <button :if={@test.anonymized_track_title == false} phx-click="hide_and_shuffle_tracks" class="btn btn-sm btn-outline-dark"><%= dgettext "test", "Hide titles and shuffle tracks" %></button>
              <button :if={@test.anonymized_track_title == true} phx-click="hide_and_shuffle_tracks" class="btn btn-sm btn-outline-dark"><%= dgettext "test", "Reveal tracks' titles" %></button>
            </div>
          <% end %>
        </div>
      </div>

      <.live_component module={DisqusComponent} :if={@test.type == :listening and @test.local == false and @embed != true} id="disqus" test={@test} />
    """
  end

  # Local test
  @impl true
  def mount(%{"data" => data} = _params, _session, socket) do
    test_data =
      data
      |> Base.url_decode64!()
      |> Jason.decode!()

    changeset =
      Test.new_local()
      |> Test.changeset_local(test_data)

    {:ok, test} = Ecto.Changeset.apply_action(changeset, :update)

    tracks =
      test.tracks
      |> Tracks.prep_tracks(test)
      |> Tests.prep_tracks(test)

    test_params = Tests.get_test_params(test)
    choices_modules = Tests.get_choices_modules(test)

    {:ok,
     socket
     |> assign(%{
       page_title: "Local test",
       test_data: data,
       test: test,
       tracks: tracks,
       tracks_state: %{},
       tracks_loading: %{},
       tracks_loaded: false,
       choices_modules: choices_modules,
       test_params: test_params,
       current_round: 1,
       current_track: nil,
       loop: true,
       rotate: true,
       rotate_seconds: 5,
       changeset: changeset,
       choices_taken: %{},
       played: false,
       playing: false,
       playingTime: 0,
       valid: false,
       #       test_already_taken: Map.get(session, "test_taken_" <> slug, false),
       test_already_taken: false,
       view_tracklist: false
     })
     |> push_event("set_warning_local_test_reload", %{set: true})}
  end

  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    test = Tests.get_by_slug(slug)
    changeset = Test.changeset(test)
    test_params = Tests.get_test_params(test)

    timezone =
      case get_connect_params(socket) do
        nil -> "Etc/UTC"
        params -> Map.get(params, "timezone", "Etc/UTC")
      end

    if connected?(socket), do: FunkyABXWeb.Endpoint.subscribe(test.id)

    tracks =
      test.tracks
      |> Tracks.prep_tracks(test)
      |> Tests.prep_tracks(test)

    choices_modules = Tests.get_choices_modules(test)

    invitation_id =
      params
      |> Map.get("i")
      |> Tests.parse_session_id()

    session_id =
      if invitation_id == nil do
        UUID.generate()
      else
        invitation_id
      end

    test_already_taken =
      case Invitations.get_invitation(invitation_id) do
        nil ->
          Map.get(session, "test_taken_" <> slug, false)

        invitation ->
          invitation.test_taken == true
      end

    {:ok,
     assign(socket, %{
       page_title: String.slice(test.title, 0..@title_max_length),
       timezone: timezone,
       ip_address: Map.get(session, "visitor_ip", nil),
       test: test,
       tracks: tracks,
       tracks_state: %{},
       tracks_loading: %{},
       tracks_loaded: false,
       choices_modules: choices_modules,
       test_params: test_params,
       session_id: session_id,
       current_round: 1,
       current_track: nil,
       loop: true,
       rotate: true,
       rotate_seconds: 5,
       changeset: changeset,
       choices_taken: %{},
       played: false,
       playing: false,
       playingTime: 0,
       valid: false,
       flag_display: false,
       test_taken_times: Tests.get_how_many_taken(test),
       test_already_taken: test_already_taken,
       view_tracklist: test.description == nil,
       embed: Map.get(session, "embed", false),
       invitation_id: invitation_id
     })
     |> then(fn s ->
       if Tests.is_closed?(test) == true do
         link = url(~p"/results/#{s.assigns.test.slug}")

         put_flash(
           s,
           :info,
           dgettext(
             "test",
             "This test has been closed. <a href=\"%{link}\">Check the results</a>",
             link: link
           )
           |> raw()
         )
       else
         s
       end
     end)
     |> then(fn s ->
       if test_already_taken == true do
         put_flash(
           s,
           :info,
           dgettext(
             "test",
             "Your invitation has already been redeemed. <a href=\"%{link}\">Take the test anonymously instead</a>.",
             link: ~p"/test/#{test.slug}"
           )
           |> raw()
         )
       else
         s
       end
     end)}
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
  def handle_info(%{event: "test_opened"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "This test has been reopened.")
     |> redirect(
       to: ~p"/test/#{socket.assigns.test.slug}"
     )}
  end

  @impl true
  def handle_info(%{event: "test_closed"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(
       :info,
       dgettext(
         "test",
         "This test has been closed. <a href=\"%{results_url}\">Check the results</a>",
         results_url: ~p"/results/#{socket.assigns.test.slug}"
       )
       |> raw()
     )
     |> redirect(
       to: ~p"/test/#{socket.assigns.test.slug}"
     )}
  end

  @impl true
  def handle_info(%{event: "test_deleted"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:error, dgettext("test", "This test has been deleted :("))
     |> redirect(
       to: ~p"/info"
     )}
  end

  @impl true
  def handle_info(%{event: "test_updated"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(
       :info,
       dgettext("test", "Test has been updated by its creator, so the page has been reloaded.")
     )
     |> redirect(
       to: ~p"/test/#{socket.assigns.test.slug}"
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
    # a bit hackish, for now
    embed = if socket.assigns.embed == true, do: "?embed=1", else: ""

    {:noreply,
     socket
     |> put_flash(:success, dgettext("test", "Your submission has been registered!"))
     |> redirect(to: url <> embed)}
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
  def handle_event("tracks_loaded", _params, socket) do
    {:noreply,
     socket
     |> assign(tracks_loaded: true)
     |> push_event("tracks_loaded", %{})}
  end

  @impl true
  def handle_event("tracks_error", _params, socket) do
    flash_text =
      case socket.assigns.test.local do
        true ->
          dgettext(
            "test",
            "One or more tracks couldn't be loaded. If you have refreshed the page, you need to create a new test."
          )

        false ->
          dgettext(
            "test",
            "One or more tracks couldn't be loaded. Please refresh the page to try again."
          )
      end

    {:noreply,
     socket
     |> assign(tracks_loaded: false)
     |> push_event("set_warning_local_test_reload", %{set: false})
     |> put_flash(:error, flash_text)}
  end

  @impl true
  def handle_event("track_state", %{"track_hash" => track_hash, "state" => status} = _params, socket) do
    tracks_state=
      socket.assigns.tracks_state
      |> Map.put(track_hash, String.to_atom(status))

    {:noreply,
      socket
      |> assign(tracks_state: tracks_state)}
  end

  @impl true
  def handle_event("track_progress", %{"track_hash" => track_hash, "progress" => progress} = _params, socket) do
    tracks_loading =
      socket.assigns.tracks_loading
      |> Map.put(track_hash, progress)

    {:noreply,
      socket
      |> assign(tracks_loading: tracks_loading)}
  end

  @impl true
  def handle_event("playing", _params, %{assigns: %{test: test, played: played}} = socket) do
    spawn(fn ->
      if played == false, do: Tests.increment_view_counter(test)
    end)

    {:noreply, assign(socket, playing: true, played: true)}
  end

  @impl true
  def handle_event("stopping", _params, socket) do
    {:noreply, assign(socket, playing: false)}
  end

  @impl true
  def handle_event("current_track_hash", %{"track_hash" => track_hash} = _params, socket) do
    {:noreply, assign(socket, current_track: track_hash)}
  end

  @impl true
  def handle_event("current_track_hash", _params, socket) do
    {:noreply, socket}
  end

  # Restore custom setting of visitor when player is loaded
  # (duplicated code from below)
  @impl true
  def handle_event("update_rotate_seconds", %{"seconds" => rotate_seconds} = _params, socket) do
    with true <- is_binary(rotate_seconds) and rotate_seconds != "",
         seconds <- String.to_integer(rotate_seconds) do
      {:noreply,
       socket
       |> assign(rotate_seconds: rotate_seconds)
       |> push_event("rotate_seconds", %{seconds: seconds})}
    else
      _ ->
        {:noreply, socket}
    end
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
       |> push_event("rotate_seconds", %{seconds: seconds})}
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

  @impl true
  def handle_event(
        "hide_and_shuffle_tracks",
        _params,
        %{assigns: %{test: test, tracks: tracks}} = socket
      )
      when test.anonymized_track_title == false do
    tracks = Enum.shuffle(tracks)
    test = %{test | anonymized_track_title: true}

    {:noreply,
     socket
     |> push_event("update_tracks", %{tracks: Tracks.to_json(tracks, test)})
     |> assign(
       test: test,
       tracks: tracks,
       current_track: nil,
       tracks_loaded: false
     )}
  end

  @impl true
  def handle_event(
        "hide_and_shuffle_tracks",
        _params,
        %{assigns: %{test: test}} = socket
      ) do
    test = %{test | anonymized_track_title: false}
    {:noreply, assign(socket, test: test)}
  end

  # ---------- TEST ----------

  @impl true
  def handle_event("test_already_taken", _params, socket) do
    results_url = ~p"/results/#{socket.assigns.test.slug}"

    {:noreply,
     socket
     |> put_flash(
       :info,
       dgettext(
         "test",
         "You have already taken this test. <a href=\"%{results_url}\">Check the results</a>.",
         results_url: results_url
       )
       |> raw()
     )
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

  # Local test
  @impl true
  def handle_event("submit", _params, %{assigns: %{current_round: current_round}} = socket)
      when socket.assigns.test.local == true do
    with test <- socket.assigns.test,
         tracks <- socket.assigns.tracks,
         choices <- socket.assigns.choices_taken,
         true <- Tests.is_valid?(test, current_round, choices) do
      Logger.info("Local test taken")

      choices_cleaned =
        choices
        |> Tests.clean_choices(tracks, test)
        |> Jason.encode!()
        |> Base.url_encode64()

      {:noreply,
       socket
       |> push_redirect(
         to: ~p"/local_test/results/#{socket.assigns.test_data}/#{choices_cleaned}",
         redirect: false
       )}
    else
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "submit",
        _params,
        %{
          assigns: %{
            current_round: current_round,
            test: test,
            tracks: tracks,
            choices_taken: choices,
            ip_address: ip_address,
            invitation_id: invitation_id,
            session_id: session_id
          }
        } = socket
      ) do
    with true <- Tests.is_valid?(test, current_round, choices),
         invitation <- Invitations.get_invitation(session_id),
         true <- invitation == nil or invitation.test_taken == false do
      Logger.info("Test taken")

      choices_cleaned = Tests.clean_choices(choices, tracks, test)

      Tests.submit(test, choices_cleaned, session_id, ip_address)

      spawn(fn ->
        FunkyABXWeb.Endpoint.broadcast!(test.id, "test_taken", nil)
        FunkyABX.Notifier.Email.test_taken(test, socket)
        Invitations.test_taken(invitation_id, test)
      end)

      Process.send_after(
        self(),
        {:redirect_results, ~p"/results/#{socket.assigns.test.slug}"},
        1000
      )

      {:noreply,
       socket
       |> push_event("store_test", %{choices: choices_cleaned, session_id: session_id})
       |> put_flash(:success, dgettext("test", "Your submission has been registered!"))}
    else
      _ ->
        {:noreply,
         put_flash(
           socket,
           :error,
           dgettext("test", "Your test can't be submitted. Please try again or reload the page")
         )}
    end
  end

  @impl true
  def handle_event("no_participate", _params, socket) do
    Process.send_after(
      self(),
      {:skip_to_results, ~p"/results/#{socket.assigns.test.slug}"},
      1000
    )

    {:noreply, push_event(socket, "bypass_test", %{})}
  end

  # ---------- UI ----------

  def handle_event("toggle_tracklist", _value, socket) do
    toggle = !socket.assigns.view_tracklist

    {:noreply, assign(socket, view_tracklist: toggle)}
  end

  defp format_date(datetime, _timezone) when datetime == nil, do: ""

  defp format_date(datetime, timezone) do
    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(timezone)
    |> Cldr.DateTime.to_string!(format: :medium)
  end

  defp get_track_state(track_hash, tracks_state) when is_map_key(tracks_state, track_hash) do
    tracks_state
    |> Map.get(track_hash)
  end

  defp get_track_state(_track_hash, _tracks_loading), do: :loading

  defp get_track_progress(track_hash, tracks_loading) when is_map_key(tracks_loading, track_hash) do
    tracks_loading
    |> Map.get(track_hash)
    |> Kernel.round()
  end

  defp get_track_progress(_track_hash, _tracks_loading), do: 0
end
