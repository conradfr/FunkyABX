defmodule FunkyABXWeb.PlayerComponent do
  use FunkyABXWeb, :live_component

  alias Phoenix.LiveView.JS
  alias FunkyABX.{Tracks, Tests}
  alias FunkyABX.Test

  # attr are not supported by live components, just act as docs here

  attr :test, Test, required: true
  attr :tracks, :list, required: true
  attr :user, User, required: false, default: nil
  attr :current_round, :integer, required: false, default: 1
  attr :choices_taken, :map, required: false, default: %{}
  attr :test_already_taken, :boolean, required: false, default: false
  attr :increment_view_counter, :boolean, default: true
  attr :loop, :boolean, default: true
  attr :rotate, :boolean, default: true

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <form phx-change="change_player_settings" phx-target={@myself}>
        <div
          class="controls d-flex flex-wrap flex-row align-items-center"
          id="player-controls"
          phx-hook="Player"
          data-tracks={Tracks.to_json(@tracks, @test)}
          data-rotate-seconds={@rotate_seconds}
          data-rotate={to_string(@rotate)}
          data-loop={to_string(@loop)}
          data-waveform={to_string(@test_params.draw_waveform)}
        >
          <div class="p-2 me-auto d-flex align-items-center">
            <button
              type="button"
              phx-click={JS.dispatch("back", to: "body")}
              title={dgettext("test", "Start back")}
              class={[
                "btn",
                "btn-dark",
                "px-2",
                "me-1",
                @tracks_loaded == false && "disabled"
              ]}
            >
              <i class="bi bi-skip-start-fill"></i>
            </button>
            <%= if @playing == true do %>
              <button
                type="button"
                phx-click={JS.dispatch("pause", to: "body")}
                title={dgettext("test", "Pause")}
                class="btn btn-success me-1"
              >
                <i class="bi bi-pause-fill"></i>&nbsp;&nbsp;&nbsp;{dgettext("test", "Pause")}&nbsp;&nbsp;
              </button>
            <% else %>
              <button
                type="button"
                phx-click={JS.dispatch("play", to: "body")}
                title={dgettext("test", "Play")}
                class={[
                  "btn",
                  "btn-secondary",
                  "header-funky",
                  "btn-play",
                  "me-1",
                  @tracks_loaded == false && "disabled"
                ]}
              >
                <i class="bi bi-play-fill"></i>&nbsp;&nbsp;&nbsp;{dgettext("test", "Play")}&nbsp;&nbsp;
              </button>
            <% end %>
            <button
              type="button"
              phx-click={JS.dispatch("stop", to: "body")}
              title={dgettext("test", "Stop")}
              class={["btn", "btn-dark", "ps-2", @tracks_loaded == false && "disabled"]}
            >
              <i class="bi bi-stop-fill"></i>
            </button>
            <%= if @tracks_loaded == false do %>
              <div class="spinner-border spinner-border-sm ms-2 text-body-secondary" role="status">
                <span class="visually-hidden">{dgettext("test", "Loading...")}</span>
              </div>
              <span class="text-body-secondary ms-2">
                <small>{dgettext("test", "Loading tracks ...")}</small>
              </span>
            <% else %>
              <div class="ms-3 text-body-secondary" role="status">
                <small>
                  <i
                    class="bi bi-info-circle text-extra-muted"
                    title={dgettext("test", "Player controls")}
                    role="button"
                    data-bs-toggle="popover"
                    data-bs-placement="auto"
                    data-bs-html="true"
                    data-bs-content={
                      dgettext(
                        "test",
                        "<strong>Mouse/touch:</strong><ul><li>Click on play icon or track number to switch and/or start playing (+ctrl to rewind)</li><li>Click on a timeline/waveform to go to a specific time & track</li></ul><strong>Keyboard shortcuts:</strong><ul><li>space: play/pause</li><li>arrows: previous/next</li><li>1-9: switch to track # (alt/option: +10)</li><li>ctrl+key: command + rewind</li><li>w: hide/show waveform</li></ul>"
                      )
                    }
                  >
                  </i>
                </small>
              </div>
            <% end %>
            <.live_component
              :if={@output_selector_available}
              id="output-selector-comp"
              module={OutputSelectorComponent}
            />
            <div id="volume-slider-wrapper" phx-update="ignore" class="d-none d-sm-block ms-3">
              <div id="volume-slider"></div>
            </div>
          </div>
          <div :if={@test.nb_of_rounds > 1} class="flex-grow-1 p-2 text-center">
            {dgettext("test", "Round %{current_round} / %{nb_of_rounds}",
              current_round: @current_round,
              nb_of_rounds: @test.nb_of_rounds
            )}
          </div>
          <div class="flex-grow-1 p-2 text-center">
            <button
              type="button"
              phx-click={JS.dispatch("start_cue", to: "body")}
              title={dgettext("test", "Cue start")}
              class="btn btn-dark btn-sm me-1"
            >
              <i class="bi bi-align-start"></i>
            </button>
            <button
              type="button"
              phx-click={JS.dispatch("end_cue", to: "body")}
              title={dgettext("test", "Cue end")}
              class="btn btn-dark btn-sm me-1"
            >
              <i class="bi bi-align-end"></i>
            </button>
          </div>
          <div class="p-2">
            <fieldset class="form-group">
              <div class="form-check">
                <input
                  class="form-check-input disabled"
                  type="checkbox"
                  id="inputLoopCheckbox"
                  name="inputLoopCheckbox"
                  checked={@loop}
                />
                <label class="form-check-label" for="inputLoopCheckbox">
                  {dgettext("test", "Loop")}
                </label>
              </div>
            </fieldset>
          </div>
          <div class="p-2">
            <div class="d-flex align-items-center">
              <div class="p-2">
                <fieldset class="form-group">
                  <div class="form-check">
                    <input
                      class="form-check-input"
                      type="checkbox"
                      id="inputRotateCheckbox"
                      name="inputRotateCheckbox"
                      checked={@rotate}
                    />
                    <label class="form-check-label" for="inputRotateCheckbox">
                      {dgettext("test", "Switch track every")}
                    </label>
                  </div>
                </fieldset>
              </div>
              <div class="p-2">
                <input
                  type="number"
                  name="rotate-seconds"
                  class="form-control form-control-sm"
                  value={@rotate_seconds}
                  style="width: 65px"
                  min="3"
                  max="3600"
                />
              </div>
              <div class="p-2">
                seconds
              </div>
            </div>
          </div>
        </div>
      </form>

      <div class="tracks my-2">
        <%= for {track, i} <- @tracks |> Enum.with_index(get_starting_index(@test)) do %>
          <div class={[
            "track",
            "my-1",
            "d-flex",
            "flex-wrap",
            "flex-md-nowrap",
            "align-items-center",
            @current_track == track.hash && "track-active",
            track.reference_track == true && "track-reference"
          ]}>
            <div class="p-2">
              <%= if @current_track == track.hash and @playing == true do %>
                <button
                  type="button"
                  class={[
                    "btn",
                    "btn-dark",
                    "px-2",
                    @current_track == track.hash && "btn-track-active"
                  ]}
                  phx-click={JS.dispatch("pause", to: "body")}
                >
                  <i class="bi bi-pause-fill"></i>
                </button>
              <% else %>
                <button
                  type="button"
                  class={[
                    "btn",
                    "btn-dark",
                    "px-2",
                    @current_track == track.hash && "btn-track-active"
                  ]}
                  phx-click={JS.dispatch("play", to: "body", detail: %{"track_hash" => track.hash})}
                >
                  <i class={["bi", "bi-play-fill", @tracks_loaded == false && "text-body-secondary"]}>
                  </i>
                </button>
              <% end %>
            </div>
            <%= if @test.anonymized_track_title == false do %>
              <div
                class="p-2 text-truncate cursor-link"
                style="width: 300px;"
                title={track.title}
                phx-click={
                  JS.dispatch(
                    if @current_track == track.hash and @playing == true do
                      "stop"
                    else
                      "play"
                    end,
                    to: "body",
                    detail: %{"track_hash" => track.hash}
                  )
                }
              >
                {track.title}
              </div>
            <% else %>
              <div
                class="p-2 cursor-link"
                style={"min-width: #{if @test.type == :listening, do: "300", else: "100"}px"}
                phx-click={
                  JS.dispatch(
                    if @current_track == track.hash and @playing == true do
                      "stop"
                    else
                      "play"
                    end,
                    to: "body",
                    detail: %{"track_hash" => track.hash}
                  )
                }
              >
                <div :if={track.reference_track == true}>{dgettext("test", "Reference")}</div>
                <div :if={track.reference_track != true}>
                  {dgettext("test", "Track %{track_index}", track_index: i)}
                </div>
              </div>
            <% end %>

            <div
              class="flex-grow-1 px-2 px-md-3 "
              style="position: relative; min-width: 100px"
              id={"waveform-#{track.hash}"}
            >
              <div
                :if={(@test.local == false or track.local_url == true) and @tracks_loaded == false}
                class="track-loading-indicator text-body-secondary"
              >
                <small :if={get_track_state(track.hash, @tracks_state) == :loading}>
                  {dgettext("test", "Loading ... %{progress}%",
                    progress: get_track_progress(track.hash, @tracks_loading)
                  )}
                </small>
                <small :if={get_track_state(track.hash, @tracks_state) == :decoding}>
                  {dgettext("test", "Decoding...")}
                  <div class="spinner-grow spinner-grow-sm ms-2 text-body-secondary" role="status">
                    <span class="visually-hidden">{dgettext("test", "Decoding...")}</span>
                  </div>
                </small>
                <small :if={get_track_state(track.hash, @tracks_state) == :finished}>
                  {dgettext("test", "Done ")} <i class="bi bi-check"></i>
                </small>
                <small :if={get_track_state(track.hash, @tracks_state) == :error}>
                  {dgettext("test", "Error")} <i class="bi bi-x-circle"></i>
                </small>
              </div>
              <div phx-update="ignore" id={"waveform-wrapper-#{track.hash}"} class="waveform-wrapper">
              </div>
            </div>

            <%= unless track.reference_track == true do %>
              <%= for module <- @choices_modules do %>
                <.live_component
                  module={module}
                  id={Atom.to_string(module) <> "_#{i}"}
                  track={track}
                  test={@test}
                  tracks={@tracks}
                  choices_taken={@choices_taken}
                  round={@current_round}
                  test_already_taken={@test_already_taken}
                />
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket, %{
       tracks_state: %{},
       tracks_loading: %{},
       tracks_loaded: false,
       current_track: nil,
       rotate: true,
       loop: true,
       rotate_seconds: 5,
       playing: false,
       playingTime: 0,
       played: false,
       output_selector_available: false
     })}
  end

  @impl true
  def update(assigns, socket) do
    choices_modules = Tests.get_choices_modules(assigns.test)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(tracks_loaded: socket.assigns.tracks_loaded)
     |> assign(choices_modules: choices_modules)
     |> assign_new(:choices_taken, fn ->
       %{}
     end)
     |> assign_new(:test_params, fn ->
       Tests.get_test_params(assigns.test)
     end)}
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
  def handle_event(
        "track_state",
        %{"track_hash" => track_hash, "state" => status} = _params,
        socket
      ) do
    tracks_state =
      socket.assigns.tracks_state
      |> Map.put(track_hash, String.to_atom(status))

    {:noreply,
     socket
     |> assign(tracks_state: tracks_state)}
  end

  @impl true
  def handle_event(
        "track_progress",
        %{"track_hash" => track_hash, "progress" => progress} = _params,
        socket
      ) do
    tracks_loading =
      socket.assigns.tracks_loading
      |> Map.put(track_hash, progress)

    {:noreply,
     socket
     |> assign(tracks_loading: tracks_loading)}
  end

  @impl true
  def handle_event(
        "playing",
        _params,
        %{assigns: %{test: test, played: played}} = socket
      ) do
    spawn(fn ->
      if Map.get(socket.assigns, :current_round, 1) < 2 and
           Map.get(socket.assigns, :increment_view_counter, true) == true and
           played == false,
         do: Tests.increment_view_counter(test)
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

  # because of the <form> tag output selection is send to the player component instead of the output selector.
  # so we relay it here as workaround
  @impl true
  def handle_event(
        "change_player_settings",
        %{"_target" => ["output-select"], "output-select" => device_id} = _player_params,
        socket
      ) do
    send_update(OutputSelectorComponent, id: "output-selector-comp", selected_device: device_id)
    {:noreply, push_event(socket, "output_device_selected", %{device_id: device_id})}
  end

  @impl true
  def handle_event("output_selector_detected", _params, socket) do
    {:noreply, assign(socket, output_selector_available: true)}
  end

  # ---------- UI ----------

  defp get_track_state(track_hash, tracks_state) when is_map_key(tracks_state, track_hash) do
    tracks_state
    |> Map.get(track_hash)
  end

  defp get_track_state(_track_hash, _tracks_loading), do: :loading

  defp get_track_progress(track_hash, tracks_loading)
       when is_map_key(tracks_loading, track_hash) do
    tracks_loading
    |> Map.get(track_hash)
    |> Kernel.round()
  end

  defp get_track_progress(_track_hash, _tracks_loading), do: 0

  defp get_starting_index(%Test{} = test) do
    case Tests.has_reference_track?(test) do
      true -> 0
      false -> 1
    end
  end
end
