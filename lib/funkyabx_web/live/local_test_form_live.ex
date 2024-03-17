defmodule FunkyABXWeb.LocalTestFormLive do
  import Ecto.Changeset

  require Logger
  use FunkyABXWeb, :live_view

  alias Ecto.UUID
  alias FunkyABX.Tests.FormUtils
  alias FunkyABX.{Tests, Tracks, Utils, Urls}
  alias FunkyABX.{Test, Track}

  @impl true
  def render(assigns) do
    ~H"""
    <.form
      :let={f}
      class="mb-2"
      for={@changeset}
      phx-change="validate"
      phx-submit={@action}
      id="test-form"
      phx-hook="LocalTestForm"
    >
      <div class="row">
        <div class="col-md-6 col-sm-12 order-md-1 order-2">
          <h3 class="mb-2 mt-0 header-chemyretro">
            Local test
            <i
              class="bi bi-question-circle text-body-secondary"
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
            <div class="form-unit px-3 py-3 rounded-3">
              <div class="form-check">
                <label class="form-check-label">
                  <%= radio_button(f, :type, "regular", class: "form-check-input") %>
                  <%= dgettext("test", "Blind test") %>
                </label>
                <%= error_tag(f, :type) %>
              </div>
              <div class="fs-8 mb-2 text-body-secondary ms-4 mb-1">
                <i class="bi bi-info-circle"></i>&nbsp;&nbsp;Select at least one option
              </div>
              <div class="form-check ms-4">
                <label class="form-check-label">
                  <%= checkbox(f, :rating,
                    class: "form-check-input",
                    disabled: get_field(@changeset, :type) !== :regular
                  ) %>
                  <%= dgettext("test", "Enable rating") %>
                </label>

                <div class="form-check mt-2 ms-1">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "pick",
                      class: "form-check-input",
                      disabled:
                        get_field(@changeset, :type) !== :regular or
                          get_field(@changeset, :rating) !== true
                    ) %> Picking
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext("test", "You will have to pick their preferred track") %>
                  </div>
                </div>

                <div class="form-check ms-1">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "star",
                      class: "form-check-input",
                      disabled:
                        get_field(@changeset, :type) !== :regular or
                          get_field(@changeset, :rating) !== true
                    ) %> Stars
                  </label>
                  <div class="form-text mb-2">
                    <%= dgettext(
                      "test",
                      "Each track will have a 1-5 star rating (usually NOT the best choice !)"
                    ) %>
                  </div>
                </div>

                <div class="form-check ms-1">
                  <label class="form-check-label">
                    <%= radio_button(f, :regular_type, "rank",
                      class: "form-check-input",
                      disabled:
                        get_field(@changeset, :type) !== :regular or
                          get_field(@changeset, :rating) !== true
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
                        disabled:
                          get_field(@changeset, :type) !== :regular or
                            Kernel.length(get_field(@changeset, :tracks)) < 10
                      ) %>
                      <%= dgettext("test", "Only rank the top/bottom three tracks") %>
                    </label>
                    <div class="form-text mb-2">
                      <%= dgettext("test", "Only for tests with 10+ tracks") %>
                    </div>
                  </div>
                </div>
              </div>
              <div class="form-check ms-4">
                <label class="form-check-label">
                  <%= checkbox(f, :identification,
                    class: "form-check-input",
                    disabled: get_field(@changeset, :type) !== :regular
                  ) %>
                  <%= dgettext("test", "Recognition test") %>
                </label>
                <div class="form-text mb-2">
                  <%= dgettext("test", "You will have to identify the anonymized tracks") %>
                </div>
              </div>

              <div class="form-check disabled mt-4 mb-2">
                <label class="form-check-label">
                  <%= radio_button(f, :type, "abx", class: "form-check-input") %>
                  <%= dgettext("test", "ABX test") %>
                </label>
                <div class="form-text mb-2">
                  <%= dgettext("test", "You will have to guess which track is cloned for n rounds") %>
                </div>
                <div class="row ms-4 mb-1">
                  <label for="test[nb_of_rounds]" class="col-6 col-sm-4 col-form-label ps-0">
                    <%= dgettext("test", "Number of rounds:") %>
                  </label>
                  <div class="col-6 col-sm-2">
                    <%= number_input(f, :nb_of_rounds,
                      class: "form-control",
                      required: input_value(f, :type) == :abx,
                      disabled: get_field(@changeset, :type) !== :abx
                    ) %>
                  </div>
                </div>
                <div class="form-check mt-2 ms-4 mb-3">
                  <label class="form-check-label">
                    <%= checkbox(f, :anonymized_track_title,
                      class: "form-check-input",
                      disabled: get_field(@changeset, :type) !== :abx
                    ) %>
                    <%= dgettext("test", "Hide tracks' title") %>
                  </label>
                </div>
              </div>

              <div class="form-check disabled mt-4 mb-2">
                <label class="form-check-label">
                  <%= radio_button(f, :type, "listening", class: "form-check-input") %>
                  <%= dgettext("test", "No test, only listening") %>
                </label>
              </div>
            </div>
          </fieldset>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6 col-sm-12">
          <h4 class="mt-1 header-typographica"><%= dgettext("test", "Tracks") %></h4>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6 col-sm-12">
          <fieldset class="form-group mb-3">
            <div class="form-unit p-3 pb-2 rounded-3" id="local_files_drop_zone">
              <div class="row form-unit pb-1 rounded-3">
                <%= label(:f, :filename, dgettext("test", "Add file(s):"),
                  class: "col-sm-3 col-form-label text-start text-md-end",
                  style: "padding-top: 5px;"
                ) %>
                <div class="col text-center">
                  <button id="local-file-picker" type="button" class="btn btn-info px-4">
                    <i class="bi bi-file-earmark-music"></i>&nbsp;&nbsp;<%= dgettext(
                      "test",
                      "Select files"
                    ) %>
                  </button>
                </div>
                <div class="col text-center">
                  <button id="local-folder-picker" type="button" class="btn btn-secondary  px-3">
                    <i class="bi bi-folder-plus"></i>&nbsp;&nbsp;<%= dgettext("test", "Select folder") %>
                  </button>
                </div>
                <div class="col-1 text-center col-form-label d-none d-sm-block">
                  <i
                    class="bi bi-info-circle text-body-secondary"
                    data-bs-toggle="tooltip"
                    title={dgettext("site", "Or drag and drop files here")}
                  >
                  </i>
                </div>
              </div>
            </div>
          </fieldset>
        </div>

        <div class="col-md-6 col-sm-12 order-md-1 order-2">
          <fieldset class="form-group mb-3">
            <div class="form-unit p-3 pb-2 rounded-3">
              <div class="row form-unit pb-1 rounded-3">
                <%= label(:f, :upload_url, dgettext("test", "Add file from url:"),
                  class: "col-sm-4 col-form-label text-start text-md-end mt-2 mt-md-0"
                ) %>
                <div class="col">
                  <div class="input-group">
                    <%= url_input(f, :upload_url, class: "form-control") %>
                    <div class="input-group-text">
                      <i
                        class="bi bi-info-circle text-body-secondary"
                        data-bs-toggle="tooltip"
                        data-bs-placement="left"
                        title={
                          dgettext(
                            "site",
                            "The file will be downloaded once you submit, not served from the original url"
                          )
                        }
                      >
                      </i>
                    </div>
                  </div>
                </div>
                <div class="col-sm-2">
                  <button
                    type="button"
                    class={[
                      "btn",
                      "btn-secondary",
                      "mt-2",
                      "mt-sm-0",
                      (get_field(@changeset, :upload_url) == nil or
                         get_field(@changeset, :upload_url) == "") && "disabled"
                    ]}
                    phx-click="add_url"
                  >
                    <i class="bi bi-plus-lg"></i> <%= dgettext("test", "Add") %>
                  </button>
                </div>
              </div>
            </div>
          </fieldset>
        </div>
      </div>

      <%= error_tag(f, :tracks) %>

      <fieldset>
        <div class="mb-2 rounded-3 form-unit">
          <.inputs_for :let={fp} field={f[:tracks]}>
            <div class={"row p-2 mx-0#{unless input_value(fp, :id) == nil, do: " mb-2"}"}>
              <%= hidden_input(fp, :id) %>
              <%= hidden_input(fp, :local) %>
              <%= hidden_input(fp, :local_url) %>
              <%= hidden_input(fp, :filename) %>
              <%= hidden_input(fp, :original_filename) %>

              <label class="col-sm-1 col-form-label">
                <%= dgettext("test", "Track #%{track_index}", track_index: fp.index + 1) %>
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

              <div class="col-sm-2 d-flex flex-row-reverse" style="min-width: 62px">
                <button
                  type="button"
                  class="btn btn-dark"
                  phx-click="remove_track"
                  phx-value-id={input_value(fp, :id)}
                >
                  <i class="bi bi-trash text-danger"></i>
                </button>

                <label :if={Tests.can_have_reference_track?(@changeset)} class="col-form-label pe-3">
                  <%= checkbox(fp, :reference_track, class: "form-check-input") %> &nbsp;&nbsp;<%= dgettext(
                    "test",
                    "Reference"
                  ) %> &nbsp;<i
                    class="bi bi-info-circle text-body-secondary"
                    data-bs-toggle="tooltip"
                    title={
                      dgettext(
                        "site",
                        "Reference / unprocessed track that will not be part of the test but playable alongside the others."
                      )
                    }
                  >
                  </i>
                </label>
              </div>
            </div>
          </.inputs_for>
        </div>
      </fieldset>

      <div class="mt-3 mb-3 text-center text-md-center d-flex flex-row justify-content-center align-items-center">
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
          data =
            Tests.form_data_from_session(Map.put(session, "tracks", []))
            |> Tests.form_data_from_params(params)

          Test.changeset_local(test, data)

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
       page_id: Utils.get_page_id_from_socket(socket),
       action: "save",
       changeset: changeset,
       test: test,
       tracks_to_delete: []
     })
     |> add_url_maybe(Map.get(params, "url"))}
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
      |> FormUtils.update_reference_track_params(target)

    changeset =
      socket.assigns.test
      |> Test.changeset_local(updated_test_params)

    {:noreply,
     assign(socket,
       changeset: changeset,
       upload_url: test_params["upload_url"]
     )}
  end

  @impl true
  def handle_event("validate", %{"test" => test_params}, socket) do
    changeset =
      socket.assigns.test
      |> Test.changeset_local(test_params)

    {:noreply,
     assign(socket,
       changeset: changeset
     )}
  end

  # ---------- FORM ----------

  @impl true
  def handle_event("save", %{"test" => test_params}, socket) do
    test_params = consume_and_update_form_tracks_params(test_params, socket)
    test = Test.changeset_local(socket.assigns.test, test_params)

    case test.valid? do
      true ->
        Logger.info(
          "Local test created (#{fetch_field!(test, :type)} / #{length(fetch_field!(test, :tracks))} tracks)"
        )

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
          #           |> push_redirect(to: url, redirect: false)
        }

      false ->
        {:noreply, assign(socket, changeset: test)}
    end
  end

  # ---------- TRACKS ----------

  @impl true
  def handle_event("add_url", _value, socket)
      when is_binary(socket.assigns.upload_url) and socket.assigns.upload_url != "" do
    {:noreply, add_url_maybe(socket, socket.assigns.upload_url)}
  end

  @impl true
  def handle_event("add_url", _value, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("track_added", %{"id" => track_id, "filename" => filename} = _params, socket) do
    {:noreply,
     socket
     |> add_track_from_filename(track_id, filename)
     |> push_event("revalidate", %{})}
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

  defp add_url_maybe(socket, url) when is_binary(url) do
    parsed_upload_url = Urls.parse_url_tracks(url)

    socket
    |> add_track_from_url(parsed_upload_url)
    |> push_event("revalidate", %{})
  end

  defp add_url_maybe(socket, _url), do: socket

  defp add_track_from_url(socket, url) when is_list(url) do
    Enum.reduce(url, socket, fn x, acc ->
      add_track_from_url(acc, x)
    end)
  end

  defp add_track_from_url(socket, url) do
    temp_id = UUID.generate()

    {title, final_url} =
      case url do
        {file_title, dest_url} ->
          {Tracks.url_to_title(file_title), dest_url}

        _ ->
          {Tracks.url_to_title(url), url}
      end

    tracks =
      socket.assigns.changeset
      |> get_field(:tracks)
      |> Enum.concat([
        Track.changeset(
          %Track{
            test_id: socket.assigns.test.id,
            temp_id: temp_id,
            id: temp_id,
            original_filename: final_url,
            url: final_url,
            title: title,
            local_url: true
          },
          %{}
        )
      ])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)
      |> Test.changeset_reset_upload_url()

    socket
    |> assign(upload_url: nil, changeset: changeset)
  end

  # only url tracks
  defp consume_and_update_form_tracks_params(test_params, socket) do
    updated_tracks =
      test_params
      |> Map.get("tracks", %{})
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        with true <- Map.get(t, "local") == "false",
             downloaded when downloaded != :error <- Tracks.import_url_for_local(t) do
          Map.put(acc, k, downloaded)
        else
          :error ->
            Utils.send_error_toast(
              "Error downloading #{t["original_filename"]}",
              socket.assigns.page_id
            )

            Map.put(acc, k, t)

          _ ->
            Map.put(acc, k, t)
        end
      end)

    Map.put(test_params, "tracks", updated_tracks)
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
