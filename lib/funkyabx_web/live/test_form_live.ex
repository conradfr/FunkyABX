defmodule FunkyABXWeb.TestFormLive do
  import Ecto.Changeset
  require Logger
  use FunkyABXWeb, :live_view
  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.Accounts
  alias FunkyABX.{Test, Tests, Track, Files, Download}

  # TODO Reduce duplicate code between "new" and "update"

  # TODO Fix crash during submit when adding a track while one is marked for deletion

  @title_max_length 100
  @default_rounds 10

  @impl true
  def render(assigns) do
    ~H"""
      <.form class="mb-2" let={f} for={@changeset} phx-change="validate" phx-submit={@action}>
        <%= hidden_input(f, :access_key) %>
        <div class="row">
          <div class="col-md-6 col-sm-12 order-md-1 order-2">
            <h3 class="mb-2 mt-0 header-chemyretro" id="test-form-header" phx-hook="TestForm">
              <%= if @action == "save" do %>
                Create a new test
              <% else %>
                Edit a test
              <% end %>
            </h3>
            <fieldset class="form-group mb-3">
              <legend class="mt-1 header-typographica">Test type</legend>
                <%= if @test_updatable == false do %>
                  <div class="alert alert-warning alert-thin"><i class="bi bi-x-circle"></i>&nbsp;&nbsp;Test type can't be changed  once at least one person has taken the test.</div>
                <% end %>
              <div class="form-unit px-3 py-3 rounded-3">
                <div class="form-check">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "regular", class: "form-check-input", disabled: !@test_updatable) %>
                    Blind test
                  </label>
                  <%= error_tag f, :type %>
                </div>
                <div class="fs-8 mb-2 text-muted ms-4 mb-1"><i class="bi bi-info-circle"></i>&nbsp;&nbsp;Select at least one option</div>
                <div class="form-check ms-4">
                  <label class="form-check-label">
                    <%= checkbox(f, :rating, class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :regular) %>
                    Enable rating
                  </label>

                  <div class="form-check mt-2 ms-1">
                    <label class="form-check-label">
                      <%= radio_button(f, :regular_type, "pick",
                        class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :regular or get_field(@changeset, :rating) !== true) %>
                      Picking
                    </label>
                    <div class="form-text mb-2">People will have to pick their preferred track</div>
                  </div>

                  <div class="form-check ms-1">
                    <label class="form-check-label">
                      <%= radio_button(f, :regular_type, "star",
                        class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :regular or get_field(@changeset, :rating) !== true) %>
                      Stars
                    </label>
                    <div class="form-text mb-2">Each track will have a 1-5 star rating (usually NOT the best choice !)</div>
                  </div>

                  <div class="form-check ms-1">
                    <label class="form-check-label">
                      <%= radio_button(f, :regular_type, "rank", class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :regular or get_field(@changeset, :rating) !== true) %>
                      Ranking
                    </label>
                    <div class="form-text mb-2">People will be asked to rank the tracks</div>
                      <div class="form-check ms-4">
                        <label class="form-check-label">
                          <%= checkbox(f, :ranking_only_extremities,
                            class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :regular or Kernel.length(get_field(@changeset, :tracks)) < 10) %>
                        Only rank the top/bottom three tracks
                        </label>
                        <div class="form-text mb-2">Only for tests with 10+ tracks</div>
                      </div>
                  </div>
                </div>
                <div class="form-check ms-4">
                  <label class="form-check-label">
                    <%= checkbox(f, :identification, class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :regular) %>
                    Recognition test
                  </label>
                  <div class="form-text mb-2">People will have to identify the anonymized tracks</div>
                </div>

                <div class="form-check disabled mt-4 mb-2">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "abx", class: "form-check-input", disabled: !@test_updatable) %>
                    ABX test
                  </label>
                  <div class="form-text mb-2">People will have to guess which track is cloned for n rounds</div>
                  <div class="row ms-4 mb-1">
                    <label for="inputEmail3" class="col-4 col-form-label ps-0">Number of rounds:</label>
                    <div class="col-2">
                      <%= number_input(f, :nb_of_rounds, class: "form-control", required: f.data.type == :abx,
                        disabled: !@test_updatable or get_field(@changeset, :type) !== :abx) %>
                    </div>
                  </div>
                  <div class="form-check mt-2 ms-4 mb-3">
                    <label class="form-check-label">
                      <%= checkbox(f, :anonymized_track_title,
                        class: "form-check-input", disabled: !@test_updatable or get_field(@changeset, :type) !== :abx) %>
                      Hide tracks' title
                    </label>
                  </div>
                </div>

                <div class="form-check disabled mt-4">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "listening", class: "form-check-input", disabled: !@test_updatable) %>
                    No test, only listening
                  </label>
                </div>

              </div>
            </fieldset>
          </div>

          <div class="offset-md-1 col-md-5 col-m-12 order-1 order-md-2">
            <%= if @action == "update" do %>
            <fieldset class="form-group mb-3">
              <legend class="header-typographica">Your test</legend>
              <div class="px-3 pt-2 pb-3 rounded-3" style="background-color: #583247;">
                <div class="mb-3">
                  <label for="test_public_link" class="form-label">Test public page <span class="form-text">(share this link)</span></label>
                  <div class="input-group mb-3">
                    <%= text_input(f, :public_link, class: "form-control", readonly: "readonly", value: Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)) %>
                    <button class="btn btn-info" type="button" title="Copy to clipboard" phx-click="clipboard" phx-value-text={Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)}>
                      <i class="bi bi-clipboard"></i>
                    </button>
                    <a class="btn btn-light" type="button" target="_blank" title="Open in a new tab" href={Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                  </div>
                </div>
                <div class="mb-3">
                  <label for="test_edit_link" class="form-label">Test edit page <span class="form-text">(this page)</span></label>
                  <div class="input-group mb-3">
                    <%= if @current_user do %>
                      <%= text_input(f, :edit_link, class: "form-control", readonly: "readonly", value: Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug)) %>
                      <button class="btn btn-info" type="button" title="Copy to clipboard" phx-click="clipboard" phx-value-text={Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug)}>
                        <i class="bi bi-clipboard"></i>
                      </button>
                      <a class="btn btn-light" type="button" target="_blank" title="Open in a new tab" href={Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <% else %>
                      <%= text_input(f, :edit_link, class: "form-control", readonly: "readonly", value: Routes.test_edit_private_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.access_key)) %>
                        <button class="btn btn-info" type="button" title="Copy to clipboard" phx-click="clipboard" phx-value-text={Routes.test_edit_private_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.access_key)}>
                          <i class="bi bi-clipboard"></i>
                        </button>
                      <a class="btn btn-light" type="button" target="_blank" title="Open in a new tab" href={Routes.test_edit_private_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.access_key)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <% end %>
                  </div>
                </div>
                <%= unless @test.type == :listening do %>
                  <div class="mb-3">
                    <label for="" class="form-label">Test private results page</label>
                    <div class="input-group mb-3">
                      <%= if @current_user do %>
                        <%= text_input(f, :results_link, class: "form-control", readonly: "readonly", value: Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug)) %>
                        <button class="btn btn-info" type="button" title="Copy to clipboard" phx-click="clipboard" phx-value-text={Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug)}>
                          <i class="bi bi-clipboard"></i>
                        </button>
                        <a class="btn btn-light" type="button" target="_blank" title="Open in a new tab" href={Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                      <% else %>
                        <%= text_input(f, :results_link, class: "form-control", readonly: "readonly", value: Routes.test_results_private_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug, f.data.access_key)) %>
                        <button class="btn btn-info" type="button" title="Copy to clipboard" phx-click="clipboard" phx-value-text={Routes.test_results_private_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug, f.data.access_key)}>
                          <i class="bi bi-clipboard"></i>
                        </button>
                        <a class="btn btn-light" type="button" target="_blank" title="Open in a new tab" href={Routes.test_results_private_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug, f.data.access_key)}><i class="bi bi-box-arrow-up-right"></i></a>
                      <% end %>
                    </div>
                  </div>
                <% end %>
                <div class="text-center">
                  <hr>
                  <button type="button" class="btn btn-danger" data-confirm="Are you sure?" phx-click="delete_test"><i class="bi bi-trash"></i> Delete test</button>
                </div>
              </div>
            </fieldset>
            <% end %>
          </div>
        </div>

        <fieldset class="form-group mb-3">
          <legend class="mt-1 header-typographica">Infos</legend>
          <div class="form-unit p-3 pb-2 rounded-3">
            <div class="row mb-3">
              <div class="col-12 col-md-6">
                <%= label :f, :title, "Title*", class: "form-label" %>
                <%= text_input(f, :title, class: "form-control", placeholder: "Mandatory", required: true) %>
                <%= error_tag f, :title %>
              </div>
              <div class="col-12 col-md-6 pt-3 pt-md-0">
                <%= label :f, :author, "Created by", class: "form-label" %>
                <%= text_input(f, :author, class: "form-control", placeholder: "Optional") %>
              </div>
            </div>
            <div class="mb-2">
              <%= label :f, :description, class: "form-label w-100" do %>
                <div class="form-check ms-4 float-end">
                  <label class="form-check-label">
                    <%= checkbox(f, :description_markdown, class: "form-check-input") %>
                    Use <a target="_blank" href="https://www.markdownguide.org/cheat-sheet/">Markdown</a>&nbsp;&nbsp;<small><i class="bi bi-info-circle text-muted" data-bs-toggle="tooltip" data-bs-placement="left" title="<br> supported for line breaks"></i></small>
                  </label>
                </div>
                Description
              <% end %>
              <%= textarea(f, :description, class: "form-control", rows: "5", placeholder: "Optional") %>
              <div class="fs-8 mt-2 mb-1 cursor-link" phx-click="toggle_description">Preview&nbsp;&nbsp;<i class={"bi bi-arrow-#{if @view_description == true do "down" else "right" end}-circle"}></i></div>
              <%= if @view_description == true do %>
                <TestDescriptionComponent.format description_markdown={get_field(@changeset, :description_markdown)} description={get_field(@changeset, :description)} />
              <% end %>
            </div>
          </div>
        </fieldset>

        <div class="row">
          <div class="col-md-6 col-sm-12 order-md-1 order-2">

            <fieldset class="form-group mb-3">
              <legend class="mt-1 header-typographica">Options</legend>
              <div class="form-unit p-3 pb-1 rounded-3">
                <div class="form-check mb-3">
                  <label class="form-check-label">
                    <%= checkbox(f, :public, class: "form-check-input") %>
                    &nbsp;&nbsp;The test is public
                  </label>
                  <div class="form-text">It will be published in the gallery 15 minutes after its creation</div>
                </div>

                <div class="form-check mb-3">
                  <label class="form-check-label">
                    <%= checkbox(f, :email_notification, class: "form-check-input", disabled: @test.user == nil) %>
                    &nbsp;&nbsp;Notify me by email when a test is taken
                  </label>
                  <%= if @test.user == nil do %>
                    <div class="form-text">Available only for logged in users</div>
                  <% end %>
                </div>

                <div class="form-check mb-2">
                  <label class="form-check-label">
                    <%= checkbox(f, :password_enabled, class: "form-check-input") %>
                    &nbsp;&nbsp;Password protected
                  </label>
                  <div class="form-text">The test will require a password to be taken (public tests will be modified as private)</div>
                </div>
                <%= hidden_input(f, :password_length) %>
                <%= if @test.password_enabled == true and @test.password_length != nil do %>
                  <div class="form-check mt-2 mb-3">
                    Current:&nbsp;
                    <%= for _star <- 1..@test.password_length do %>
                      *
                    <% end %>
                  </div>
                <% end %>
                <div class="form-check mt-2 mb-3">
                  <%= password_input(f, :password_input, class: "form-control", placeholder: "Enter new password") %>
                  <%= error_tag f, :password_input %>
                </div>
              </div>

            </fieldset>

          </div>
        </div>

        <fieldset>
          <legend class="header-typographica"><span class="float-end fs-8 text-muted" style="font-family: var(--bs-font-sans-serif); padding-top: 12px;"><i class="bi bi-info-circle"></i>&nbsp;Two tracks minimum</span>Tracks</legend>

          <%= if @test_updatable == false do %>
            <div class="alert alert-warning alert-thin"><i class="bi bi-x-circle"></i>&nbsp;&nbsp;Tracks can't be modified once at least one person has taken the test.</div>
          <% else %>
            <div class="alert alert-info alert-thin"><i class="bi bi-info-circle"></i>&nbsp;&nbsp;Supported formats: wav, mp3, aac, flac ... <a href="https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats" target="_blank">(html5 audio)</a>. Wav files are converted to flac.</div>
          <% end %>

          <fieldset class="form-group mb-3">
            <div class="form-unit p-3 rounded-3">
              <div class="form-check">
                <div class="d-flex justify-content-between">
                  <label class="form-check-label">
                    <%= checkbox(f, :normalization, class: "form-check-input") %>
                    &nbsp;&nbsp;Apply EBU R128 loudness normalization during upload (wav files only)
                  </label>
                  <div class="text-muted text-end"><small><i class="bi bi-info-circle"></i>&nbsp; True Peak -1dB, target -24dB, </small></div>
                </div>
              </div>
            </div>
          </fieldset>
        </fieldset>

        <div class="row">
          <div class="col-md-6 col-sm-12 order-md-1 order-2">
            <fieldset class="form-group mb-3">
              <div class="form-unit p-3 pb-2 rounded-3">
                <div class="row form-unit pb-1 rounded-3" phx-drop-target={@uploads.tracks.ref}>
                  <%= label :f, :filename, "Select file(s) to upload:", class: "col-sm-4 col-form-label text-start text-md-end" %>
                  <div class="col text-center pt-1">
                    <%= live_file_input @uploads.tracks %>
                  </div>
                  <div class="col-1 text-center col-form-label d-none d-sm-block">
                    <i class="bi bi-info-circle text-muted" data-bs-toggle="tooltip" title="Or drag and drop files here"></i>
                  </div>
                </div>
              </div>
            </fieldset>
          </div>

          <div class="col-md-6 col-sm-12 order-md-1 order-2">
            <fieldset class="form-group mb-3">
              <div class="form-unit p-3 pb-2 rounded-3">
                <div class="row form-unit pb-1 rounded-3">
                  <%= label :f, :upload_url, "Add file from url:", class: "col-sm-4 col-form-label text-start text-md-end mt-2 mt-md-0" %>
                  <div class="col">
                    <div class="input-group">
                      <%= url_input f, :upload_url, class: "form-control" %>
                      <div class="input-group-text">
                        <i class="bi bi-info-circle text-muted" data-bs-toggle="tooltip" data-bs-placement="left" title="The file will be downloaded, not served from the original url"></i>
                      </div>
                    </div>
                  </div>
                  <div class="col-sm-2">
                    <button type="button" class={"btn btn-secondary mt-2 mt-sm-0 #{if get_field(@changeset, :upload_url) == nil or get_field(@changeset, :upload_url) == "", do: " disabled"}"} phx-click="add_url"><i class="bi bi-plus-lg"></i> Add</button>
                  </div>
                </div>
              </div>
            </fieldset>
          </div>
        </div>

        <%= error_tag f, :tracks %>

        <fieldset>
          <div class="mb-2">
            <%= for {fp, i} <- inputs_for(f, :tracks) |> Enum.with_index(1) do %>
              <%= unless Enum.member?(@tracks_to_delete, fp.data.id) == true do %>
                <div class={"row p-2 form-unit mx-0#{unless fp.data.id == nil, do: " mb-2"}"}>

                  <%= if fp.data.id != nil do %>
                    <%= hidden_input(fp, :id) %>
                    <%= hidden_input(fp, :delete) %>
                  <% else %>
                    <%= hidden_input(fp, :temp_id) %>
                  <% end %>

                  <%= if fp.data.url != nil do %>
                    <%= hidden_input(fp, :url) %>
                  <% end %>

                  <label class="col-sm-1 col-form-label">Track #<%= i %></label>
                  <hr class="d-block d-sm-none mb-0">
                  <%= label :fp, :title, "Name:*", class: "col-sm-1 col-form-label text-start text-md-end" %>
                  <div class="col-sm-4">
                    <%= text_input fp, :title, class: "form-control", disabled: !@test_updatable, required: true %>
                  </div>
                  <%= if get_upload_entry(fp.data.temp_id, @uploads.tracks.entries) != nil and get_upload_entry_progress(fp.data.temp_id, @uploads.tracks.entries) > 0 do %>
                    <%= label :fp, :filename, "Upload:", class: "col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0" %>
                    <div class="col d-flex align-items-center"><progress value={get_upload_entry_progress(fp.data.temp_id, @uploads.tracks.entries)} max="100"> <%= get_upload_entry_progress(fp.data.temp_id, @uploads.tracks.entries) %>%</progress></div>
                  <% else %>
                    <%= label :fp, :filename, "File:", class: "col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0" %>
                    <div class="col w-100 text-truncate d-flex align-items-center" title={fp.data.original_filename} >
                      <%= fp.data.original_filename %>
                    </div>
                  <% end %>
                  <div class="col-sm-1 d-flex flex-row-reverse" style="min-width: 62px">
                    <%= if fp.data.id != nil do %>
                      <button type="button" class={"btn btn-dark#{if @test_updatable == false, do: " disabled"}"} data-confirm="Are you sure?" phx-click="delete_track" phx-value-id={fp.data.id}><i class="bi bi-trash text-danger"></i></button>
                    <% else %>
                      <button type="button" class={"btn btn-dark#{if @test_updatable == false, do: " disabled"}"} phx-click="remove_track" phx-value-id={fp.data.temp_id}><i class="bi bi-trash text-danger"></i></button>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </fieldset>

        <div class="mt-3 text-center text-md-end d-flex flex-row justify-content-end align-items-center">
          <%= if @loading == true do %>
            <div class="spinner-border spinner-border-sm text-primary me-2" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
          <% end %>
          <%= if @action == "save" do %>
            <%= submit("Create test", class: "btn btn-lg btn-primary", disabled: !@changeset.valid?) %>
          <% else %>
            <%= submit("Update test", class: "btn btn-lg btn-primary", disabled: !@changeset.valid?) %>
          <% end %>
        </div>
      </.form>
    """
  end

  # ---------- MOUNT ----------

  # Edit
  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         nil <- test.deleted_at,
         true <-
           (params["key"] != nil and params["key"] == test.access_key) or
             Map.get(session, "current_user_id") == test.user_id do
      test_updatable = !Tests.has_tests_taken?(test)
      changeset = Test.changeset_update(test)

      FunkyABXWeb.Endpoint.subscribe(test.id)

      {:ok,
       socket
       |> assign_new(:current_user, fn ->
         case session["user_token"] do
           nil -> nil
           token -> Accounts.get_user_by_session_token(token)
         end
       end)
       |> assign(%{
         page_title: "Edit test - " <> String.slice(test.title, 0..@title_max_length),
         action: "update",
         loading: false,
         changeset: changeset,
         test: test,
         view_description: false,
         tracks_to_delete: [],
         test_updatable: test_updatable
       })
       |> allow_upload(:tracks,
         accept: ~w(.wav .mp3 .aac .flac),
         max_entries: 20,
         max_file_size: 500_000_000
       )}
    else
      _ ->
        {:ok, redirect(socket, to: Routes.test_new_path(socket, FunkyABXWeb.TestFormLive))}
    end
  end

  # New
  @impl true
  def mount(_params, session, socket) do
    user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    access_key = if user == nil, do: UUID.generate(), else: nil
    name = Map.get(session, "author")

    test = %Test{
      id: UUID.generate(),
      type: :regular,
      rating: true,
      regular_type: :pick,
      ranking_only_extremities: false,
      identification: false,
      author: name,
      access_key: access_key,
      password_enabled: false,
      password_length: nil,
      description_markdown: false,
      upload_url: nil,
      tracks: [],
      normalization: false,
      user: user,
      nb_of_rounds: @default_rounds,
      anonymized_track_title: true,
      email_notification: false,
      ip_address: Map.get(session, "visitor_ip", nil)
    }

    changeset = Test.changeset(test)

    {:ok,
     socket
     |> assign_new(:current_user, fn ->
       case session["user_token"] do
         nil -> nil
         token -> Accounts.get_user_by_session_token(token)
       end
     end)
     |> assign(%{
       page_title: "Create test",
       action: "save",
       loading: false,
       changeset: changeset,
       test: test,
       view_description: false,
       tracks_to_delete: [],
       test_updatable: true
     })
     |> allow_upload(:tracks,
       accept: ~w(.wav .mp3 .aac .flac),
       max_entries: 20,
       max_file_size: 500_000_000
     )}
  end

  # ---------- PUB/SUB EVENTS ----------

  @impl true
  def handle_info(%{event: "test_taken"} = _payload, socket) do
    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, socket.assigns.test.tracks)

    {:noreply,
     assign(socket, %{changeset: changeset, test_updatable: false, tracks_to_delete: []})}
  end

  def handle_info({:redirect, url, text} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:success, text)
     |> push_redirect(to: url, redirect: true)}
  end

  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
  end

  # ---------- INDIRECT FORM EVENTS ----------

  def handle_info({"update", %{"test" => test_params}}, socket) do
    normalization =
      socket.assigns.test
      |> Test.changeset_update(test_params)
      |> get_field(:normalization)

    updated_tracks =
      test_params["tracks"]
      # uploads
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        upload_entry = get_upload_entry(t["temp_id"], socket.assigns.uploads.tracks.entries)

        upload_consumed =
          unless upload_entry == nil do
            consume_uploaded_entry(socket, upload_entry, fn %{path: path} ->
              filename_dest = Files.get_destination_filename(upload_entry.client_name)

              final_filename_dest =
                Files.save(
                  path,
                  Path.join([socket.assigns.test.id, filename_dest]),
                  normalization
                )

              {:ok, {upload_entry.client_name, final_filename_dest}}
            end)
          else
            nil
          end

        case upload_consumed do
          {original_filename, filename} ->
            updated_track =
              Map.merge(t, %{"filename" => filename, "original_filename" => original_filename})

            Map.put(acc, k, updated_track)

          _ ->
            Map.put(acc, k, t)
        end
      end)
      # url download
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        with false <- Map.has_key?(t, "id"),
             url when url != nil <- Map.get(t, "url") do
          t
          |> import_track_url(socket.assigns.test)
          |> (&Map.put(acc, k, &1)).()
        else
          _ ->
            Map.put(acc, k, t)
        end
      end)

    updated_test_params = Map.put(test_params, "tracks", updated_tracks)

    update =
      socket.assigns.test
      |> Test.changeset_update(updated_test_params)
      |> Repo.update()

    case update do
      {:ok, test} ->
        Logger.info("Test updated")

        Tests.clean_get_test_cache(socket.assigns.test)
        FunkyABXWeb.Endpoint.broadcast!(socket.assigns.test.id, "test_updated", nil)

        # Delete files from removed tracks
        socket.assigns.test.tracks
        |> Enum.filter(fn t -> t.id in socket.assigns.tracks_to_delete end)
        |> Enum.map(fn t -> t.filename end)
        |> Files.delete(socket.assigns.test.id)

        # logged or not
        redirect =
          unless test.password == nil do
            Routes.test_edit_private_path(
              FunkyABXWeb.Endpoint,
              FunkyABXWeb.TestFormLive,
              test.slug,
              test.password
            )
          else
            Routes.test_edit_path(
              FunkyABXWeb.Endpoint,
              FunkyABXWeb.TestFormLive,
              test.slug
            )
          end

        flash_text = "Your test has been successfully updated."

        Process.send_after(
          self(),
          {:redirect, redirect, flash_text},
          1000
        )

        {:noreply,
         socket
         |> assign(test: test, loading: false)
         |> put_flash(:success, flash_text)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, loading: false, changeset: changeset, tracks_to_delete: [])}
    end
  end

  def handle_info({"save", %{"test" => test_params}}, socket) do
    normalization =
      socket.assigns.test
      |> Test.changeset_update(test_params)
      |> get_field(:normalization)

    updated_tracks =
      test_params
      |> Map.get("tracks", %{})
      # uploads
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        upload_entry = get_upload_entry(t["temp_id"], socket.assigns.uploads.tracks.entries)

        upload_consumed =
          unless upload_entry == nil do
            consume_uploaded_entry(socket, upload_entry, fn %{path: path} ->
              filename_dest = Files.get_destination_filename(upload_entry.client_name)

              final_filename_dest =
                Files.save(
                  path,
                  Path.join([socket.assigns.test.id, filename_dest]),
                  normalization
                )

              {:ok, {upload_entry.client_name, final_filename_dest}}
            end)
          else
            nil
          end

        case upload_consumed do
          {original_filename, filename} ->
            updated_track =
              Map.merge(t, %{"filename" => filename, "original_filename" => original_filename})

            Map.put(acc, k, updated_track)

          _ ->
            Map.put(acc, k, t)
        end
      end)
      # url download
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        with false <- Map.has_key?(t, "id"),
             url when url != nil <- Map.get(t, "url") do
          t
          |> import_track_url(socket.assigns.test)
          |> (&Map.put(acc, k, &1)).()
        else
          _ ->
            Map.put(acc, k, t)
        end
      end)

    updated_test_params = Map.put(test_params, "tracks", updated_tracks)

    insert =
      socket.assigns.test
      |> Test.changeset(updated_test_params)
      |> Repo.insert()

    case insert do
      {:ok, test} ->
        # logged or not
        redirect =
          unless test.password == nil do
            Routes.test_edit_private_path(
              FunkyABXWeb.Endpoint,
              FunkyABXWeb.TestFormLive,
              test.slug,
              test.password
            )
          else
            Routes.test_edit_path(
              FunkyABXWeb.Endpoint,
              FunkyABXWeb.TestFormLive,
              test.slug
            )
          end

        flash_text =
          "Your test has been successfully created !<br><br>You can now share the <a href=\"" <>
            Routes.test_public_url(socket, FunkyABXWeb.TestLive, test.slug) <>
            "\">test's public link</a> for people to take it."

        Process.send_after(
          self(),
          {:redirect, redirect <> "#top", flash_text},
          1500
        )

        changeset = Test.changeset_update(test)

        Logger.info("Test created")

        # Refresh user test list if logged
        unless test.user == nil do
          Tests.clean_get_user_cache(test.user)
        end

        {
          :noreply,
          socket
          |> assign(action: "update", loading: false, test: test, changeset: changeset)
          |> push_event("saveTest", %{
            test_id: test.id,
            test_access_key: test.access_key,
            test_author: test.author
          })
          |> put_flash(:success, flash_text)
          #         |> push_redirect(to: redirect, replace: true)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, loading: false, changeset: changeset)}
    end
  end

  # ---------- MISC EVENTS ----------

  @impl true
  def handle_event("clipboard", %{"text" => text}, socket) do
    {:noreply, push_event(socket, "clipboard", %{text: text})}
  end

  # ---------- FORM EVENTS ----------

  @impl true
  def handle_event("validate", %{"test" => test_params, "_target" => target}, socket) do
    updated_test_params =
      target
      |> List.last()
      |> update_test_params(test_params)

    changeset =
      socket.assigns.test
      |> Test.changeset_update(updated_test_params)
      |> build_upload_tracks(socket)
      |> update_action(socket.assigns.action)

    {:noreply,
     assign(socket,
       changeset: changeset,
       upload_url: test_params["upload_url"],
       description: test_params["description"],
       description_markdown: test_params["description_markdown"] == "true"
     )}
  end

  # Edit
  @impl true
  def handle_event("update", params, socket) do
    send(self(), {"update", params})
    {:noreply, assign(socket, :loading, true)}
  end

  # New
  @impl true
  def handle_event("save", params, socket) do
    send(self(), {"save", params})
    {:noreply, assign(socket, :loading, true)}
  end

  @impl true
  def handle_event("delete_test", _params, socket) do
    test =
      socket.assigns.test
      |> Repo.preload(:user)

    Files.delete_all(test.id)

    test
    |> Test.changeset_delete()
    |> Repo.update()

    Tests.clean_get_test_cache(test)
    # Refresh user test list if logged
    unless test.user == nil or test.user.id == nil do
      Tests.clean_get_user_cache(test.user)
    end

    FunkyABXWeb.Endpoint.broadcast!(test.id, "test_deleted", nil)

    flash_text = "Your test has been successfully deleted."

    Process.send_after(
      self(),
      {:redirect, Routes.info_path(socket, FunkyABXWeb.FlashLive), flash_text},
      1500
    )

    Logger.info("Test deleted")

    {
      :noreply,
      socket
      |> push_event("deleteTest", %{
        test_id: test.id,
        test_access_key: test.access_key
      })
      |> put_flash(:success, flash_text)
    }
  end

  @impl true
  def handle_event(
        "track_file_selected",
        %{"track_id" => track_id, "filename" => filename},
        socket
      ) do
    {:noreply, set_track_title_if_empty(socket, track_id, filename)}
  end

  @impl true
  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
  end

  # ---------- TRACKS ----------

  @impl true
  def handle_event("add_url", _value, socket)
      when is_binary(socket.assigns.upload_url) and socket.assigns.upload_url != "" do
    {:noreply, add_track_from_url(socket, socket.assigns.upload_url)}
  end

  @impl true
  def handle_event("add_url", _value, socket) do
    {:noreply, socket}
  end

  # Persisted tracks
  @impl true
  def handle_event("delete_track", %{"id" => track_id}, socket) do
    deleted_track =
      socket.assigns.changeset.data.tracks
      |> Enum.find(&(&1.id == track_id))
      |> Map.put(:delete, true)
      |> Track.changeset(%{})

    # done here instead at the end of the previous pipe to have the correct sort
    tracks =
      Map.get(socket.assigns.changeset.changes, :tracks, socket.assigns.test.tracks)
      |> Enum.concat([deleted_track])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.cast_assoc(:tracks, tracks)

    updated_tracks_to_delete = socket.assigns.tracks_to_delete ++ [track_id]

    {:noreply,
     assign(socket, %{changeset: changeset, tracks_to_delete: updated_tracks_to_delete})}
  end

  # New tracks
  @impl true
  def handle_event("remove_track", %{"id" => track_id}, socket) do
    tracks =
      socket.assigns.changeset.changes.tracks
      |> Enum.reject(fn %{data: track} ->
        track.temp_id == track_id
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    {:noreply,
     socket
     |> assign(%{changeset: changeset})
     |> then(fn socket ->
       # only cancel upload if entry is not from url
       case get_upload_entry(track_id, socket.assigns.uploads.tracks.entries) do
         nil ->
           socket

         entry ->
           ref_to_cancel = Map.get(entry, :ref)
           cancel_upload(socket, :tracks, ref_to_cancel)
       end
     end)}
  end

  defp build_upload_tracks(changeset, socket) do
    existing_ids =
      socket.assigns.changeset.changes
      |> Map.get(:tracks, [])
      |> Enum.map(& &1.data.temp_id)

    new_tracks =
      socket.assigns.uploads.tracks.entries
      |> Enum.reject(fn e -> e.uuid in existing_ids end)
      |> Enum.map(fn e ->
        Track.changeset(
          %Track{
            test_id: socket.assigns.test.id,
            temp_id: e.uuid,
            title: filename_to_title(e.client_name),
            original_filename: e.client_name
          },
          %{}
        )
      end)

    # done here instead at the end of the previous pipe to have the correct sort
    tracks =
      Map.get(socket.assigns.changeset.changes, :tracks, socket.assigns.test.tracks)
      |> Enum.concat(new_tracks)

    changeset
    |> Ecto.Changeset.put_assoc(:tracks, tracks)
  end

  defp add_track_from_url(socket, url) do
    temp_id = UUID.generate()

    tracks =
      Map.get(socket.assigns.changeset.changes, :tracks, socket.assigns.test.tracks)
      |> Enum.concat([
        Track.changeset(
          %Track{
            test_id: socket.assigns.test.id,
            temp_id: temp_id,
            original_filename: url,
            url: url,
            title: url_to_title(url)
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

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  # ---

  defp import_track_url(track, test) do
    task = Task.Supervisor.async(FunkyABX.TaskSupervisor, Download, :from_url, [track["url"]])
    result = Task.await(task)

    case result do
      {original_filename, download_path} ->
        filename_dest =
          track
          |> Map.get("url")
          |> Files.get_destination_filename()
          |> (&Path.join([test.id, &1])).()

        final_filename_dest = Files.save(download_path, filename_dest)
        File.rm(download_path)

        Map.merge(track, %{
          "url" => track["url"],
          "filename" => final_filename_dest,
          "original_filename" => original_filename
        })

      _ ->
        track
    end
  end

  defp set_track_title_if_empty(socket, track_id, filename)
       when is_binary(track_id) and is_binary(filename) do
    tracks =
      socket.assigns.changeset.changes.tracks
      |> Enum.map(fn
        %{changes: changes, data: %{temp_id: temp_id} = track}
        when temp_id == track_id and
               ((is_map_key(changes, :title) and (changes.title == nil or changes.title == "")) or
                  is_map_key(changes, :title) == false) ->
          Track.changeset(track, %{title: filename_to_title(filename)})

        track_changeset ->
          track_changeset
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    assign(socket, %{changeset: changeset})
  end

  defp url_to_title(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> URI.decode()
    |> Path.basename()
    |> filename_to_title()
  end

  defp filename_to_title(filename) when is_binary(filename) do
    filename
    |> String.replace_suffix(Path.extname(filename), "")
    |> String.replace("_", " ")
    |> :string.titlecase()
  end

  # ---------- FORM UTILS ----------

  defp update_action(changeset, "update") do
    Map.put(changeset, :action, :update)
  end

  defp update_action(changeset, _action) do
    #    Map.put(:action, :insert)
    changeset
  end

  defp update_test_params("ranking", %{"ranking" => ranking} = test_params)
       when ranking == "true" do
    test_params
    |> Map.put("picking", false)
    |> Map.put("starring", false)
  end

  defp update_test_params("picking", %{"picking" => picking} = test_params)
       when picking == "true" do
    test_params
    |> Map.put("ranking", false)
    |> Map.put("starring", false)
  end

  defp update_test_params("starring", %{"starring" => starring} = test_params)
       when starring == "true" do
    test_params
    |> Map.put("ranking", false)
    |> Map.put("picking", false)
  end

  defp update_test_params(_target, test_params) do
    test_params
  end

  defp get_upload_entry(track_id, uploads) do
    Enum.find(uploads, &(&1.uuid == track_id))
  end

  def get_upload_entry_progress(track_id, uploads) do
    case get_upload_entry(track_id, uploads) do
      nil -> nil
      entry -> entry.progress
    end
  end
end
