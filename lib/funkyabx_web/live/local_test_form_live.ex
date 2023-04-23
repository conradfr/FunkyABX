defmodule FunkyABXWeb.LocalTestFormLive do
  import Ecto.Changeset

  require Logger
  use FunkyABXWeb, :live_view

  alias FunkyABX.Tests.FormUtils
  alias FunkyABX.{Tests, Test, Track, Tracks}

  @impl true
  def render(assigns) do
    ~H"""
    <.form :let={f} class="mb-2" for={@changeset} phx-change="validate" phx-submit={@action}>
      <div class="row">
        <div class="col-md-6 col-sm-12 order-md-1 order-2">
          <h3 class="mb-2 mt-0 header-chemyretro" id="test-form-header" phx-hook="LocalTestForm">
            Local test
            <i
              class="bi bi-question-circle text-muted"
              style="font-size: 0.75rem"
              data-bs-toggle="tooltip"
              title={
                dgettext(
                  "site",
                  "Local tests are ephemerous tests that can't be shared and are using your files locally."
                )
              }
            >
            </i>
          </h3>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6 col-sm-12">
          <h4 class="mt-1 header-typographica"><%= dgettext("test", "Test type") %></h4>
          <fieldset class="form-group mb-3">
            <%= hidden_input(f, :type) %>
            <div class="form-unit px-3 py-3 rounded-3">
              <div class="fs-8 mb-2 text-muted mb-1">
                <i class="bi bi-info-circle"></i>&nbsp;&nbsp;<%= dgettext(
                  "test",
                  "Select at least one option"
                ) %>
              </div>
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :rating, class: "form-check-input") %>
                  <%= dgettext("test", "Enable rating") %>
                </label>

                <div class="form-check mt-2">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "pick",
                      class: "form-check-input",
                      disabled: get_field(@changeset, :rating) !== true
                    ) %>
                    <%= dgettext("test", "Picking") %>
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext("test", "You will have to pick your preferred track") %>
                  </div>
                </div>

                <div class="form-check ms-1">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "star",
                      class: "form-check-input",
                      disabled: get_field(@changeset, :rating) !== true
                    ) %>
                    <%= dgettext("test", "Stars") %>
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext("test", "Each track will have a 1-5 star rating") %>
                  </div>
                </div>

                <div class="form-check ms-1">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "rank",
                      class: "form-check-input",
                      disabled: get_field(@changeset, :rating) !== true
                    ) %>
                    <%= dgettext("test", "Ranking") %>
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext("test", "You will be asked to rank the tracks") %>
                  </div>
                  <div class="form-check ms-4">
                    <label class="form-check-label">
                      <%= checkbox(f, :ranking_only_extremities,
                        class: "form-check-input",
                        disabled: Kernel.length(get_field(@changeset, :tracks)) < 10
                      ) %>
                      <%= dgettext("test", "Only rank the top/bottom three tracks") %>
                    </label>
                    <div class="form-text mb-2">
                      <%= dgettext("test", "Only for tests with 10+ tracks") %>
                    </div>
                  </div>
                </div>
              </div>
              <div class="form-check">
                <label class="form-check-label">
                  <%= checkbox(f, :identification, class: "form-check-input") %>
                  <%= dgettext("test", "Recognition test") %>
                </label>
                <div class="form-text mb-2">
                  <%= dgettext("test", "You will have to identify the anonymized tracks") %>
                </div>
              </div>
            </div>
          </fieldset>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6 col-sm-12">
          <h4 class="mt-1 header-typographica"><%= dgettext("test", "Tracks") %></h4>
          <fieldset class="form-group mb-3">
            <div class="form-unit p-3 pb-2 rounded-3" id="local_files_drop_zone">
              <div class="row form-unit pb-1 rounded-3">
                <%= label(:f, :filename, dgettext("test", "Add file(s):"),
                  class: "col-sm-4 col-form-label text-start text-md-end"
                ) %>
                <div class="col text-center">
                  <button id="local-file-picker" type="button" class="btn btn-info">
                    <i class="bi bi-file-earmark-music"></i>&nbsp;&nbsp;<%= dgettext(
                      "test",
                      "Select files"
                    ) %>
                  </button>
                </div>
                <div class="col text-center">
                  <button id="local-folder-picker" type="button" class="btn btn-secondary">
                    <i class="bi bi-folder-plus"></i>&nbsp;&nbsp;<%= dgettext("test", "Select folder") %>
                  </button>
                </div>
                <div class="col-1 text-center col-form-label d-none d-sm-block">
                  <i
                    class="bi bi-info-circle text-muted"
                    data-bs-toggle="tooltip"
                    title={dgettext("site", "Or drag and drop files here")}
                  >
                  </i>
                </div>
              </div>
            </div>
          </fieldset>
        </div>
      </div>

      <%= error_tag(f, :tracks) %>

      <fieldset>
        <div class="mb-2 rounded-3 form-unit">
          <%= for {fp, i} <- inputs_for(f, :tracks) |> Enum.with_index(1) do %>
            <div class={"row p-2 mx-0#{unless input_value(fp, :id) == nil, do: " mb-2"}"}>
              <%= hidden_input(fp, :id) %>
              <%= hidden_input(fp, :local) %>
              <%= hidden_input(fp, :filename) %>
              <%= hidden_input(fp, :original_filename) %>

              <label class="col-sm-1 col-form-label">
                <%= dgettext("test", "Track #%{track_index}", track_index: i) %>
              </label>
              <hr class="d-block d-sm-none mb-0" />
              <%= label(:fp, :title, dgettext("test", "Name:*"),
                class: "col-sm-1 col-form-label text-start text-md-end"
              ) %>
              <div class="col-sm-4">
                <%= text_input(fp, :title, class: "form-control", required: true) %>
              </div>

              <%= label(:fp, :original_filename, "File:",
                class: "col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0"
              ) %>
              <div
                class="col w-100 text-truncate d-flex align-items-center"
                title={input_value(fp, :original_filename)}
              >
                <%= input_value(fp, :original_filename) %>
              </div>

              <div class="col-sm-1 d-flex flex-row-reverse" style="min-width: 62px">
                <button
                  type="button"
                  class="btn btn-dark"
                  phx-click="remove_track"
                  phx-value-id={input_value(fp, :id)}
                >
                  <i class="bi bi-trash text-danger"></i>
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </fieldset>

      <div class="mt-3 text-center text-md-center d-flex flex-row justify-content-center align-items-center">
        <div class="loading-spinner spinner-border spinner-border-sm text-primary me-2" role="status">
          <span class="visually-hidden"><%= dgettext("test", "Loading...") %></span>
        </div>
        <%= submit(gettext("Create local test"),
          class: "btn btn-lg btn-primary",
          disabled: !@changeset.valid?
        ) %>
      </div>
    </.form>
    """
  end

  # ---------- MOUNT ----------

  @impl true
  def mount(params, session, socket) do
    test = Test.new_local()

    changeset =
      case Map.get(params, "data") do
        nil ->
          Test.changeset_local(test, Tests.form_data_from_session(session))

        data ->
          test_data =
            data
            |> Base.url_decode64!()
            |> Jason.decode!()

          Test.changeset_local(test, test_data)
      end

    {:ok,
     socket
     |> assign(%{
       page_title: "Local test",
       action: "save",
       changeset: changeset,
       test: test,
       tracks_to_delete: []
     })}
  end

  # ---------- MISC EVENTS ----------

  @impl true
  def handle_event("redirect", %{"url" => url}, socket) do
    {:noreply,
     socket
     |> push_redirect(to: url, replace: false)}
  end

  # ---------- FORM EVENTS ----------

  @impl true
  def handle_event("validate", %{"test" => test_params, "_target" => target}, socket) do
    updated_test_params =
      target
      |> List.last()
      |> FormUtils.update_test_params(test_params)

    changeset =
      socket.assigns.test
      |> Test.changeset_local(updated_test_params)

    {:noreply,
     assign(socket,
       changeset: changeset
     )}
  end

  # ---------- TRACKS ----------

  @impl true
  def handle_event("track_added", %{"id" => track_id, "filename" => filename} = _params, socket) do
    {:noreply, add_track_from_filename(socket, track_id, filename)}
  end

  @impl true
  def handle_event("remove_track", %{"id" => track_id}, socket) do
    tracks =
      socket.assigns.changeset.changes.tracks
      |> Enum.reject(fn track_changeset ->
        get_field(track_changeset, :id) == track_id
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    {:noreply,
     socket
     |> assign(%{changeset: changeset})}
  end

  # ---------- FORM ----------

  @impl true
  def handle_event("save", %{"test" => test_params}, socket) do
    test = Test.changeset_local(socket.assigns.test, test_params)

    case test.valid? do
      true ->
        Logger.info("Local test created")

        Tests.increment_local_test_counter()

        test_encoded =
          test_params
          |> Jason.encode!()
          |> Base.url_encode64()

        {
          :noreply,
          socket
          |> push_event("store_params_and_redirect", %{
            "url" => ~p"/local_test/#{test_encoded}",
            "params" => [
              %{
                "name" => "identification",
                "value" => test_params["identification"]
              },
              %{
                "name" => "rating",
                "value" => test_params["rating"]
              },
              %{
                "name" => "regular_type",
                "value" => test_params["regular_type"]
              }
            ]
          })
          # |> push_redirect(to: url, redirect: false)
        }

      false ->
        {:noreply, assign(socket, changeset: test)}
    end
  end

  # ---------- UTILS ----------

  defp add_track_from_filename(socket, track_id, filename) do
    tracks =
      Map.get(socket.assigns.changeset.changes, :tracks, socket.assigns.test.tracks)
      |> Enum.concat([
        Track.changeset(
          %Track{},
          %{
            "test_id" => socket.assigns.test.id,
            "id" => track_id,
            "local" => true,
            "original_filename" => filename,
            "filename" => filename,
            "title" => Tracks.filename_to_title(filename)
          }
        )
      ])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    socket
    |> assign(changeset: changeset)
  end
end
