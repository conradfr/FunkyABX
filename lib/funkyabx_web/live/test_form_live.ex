defmodule FunkyABXWeb.TestFormLive do
  use FunkyABXWeb, :live_view
  alias Ecto.UUID
  alias FunkyABX.Accounts
  alias FunkyABX.Repo
  alias FunkyABX.Tests
  alias FunkyABX.Test
  alias FunkyABX.Track
  alias FunkyABX.Files

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
      <.form class="mb-2" let={f} for={@changeset} phx-change="validate" phx-submit={@action}>
        <%= hidden_input(f, :password) %>
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
              <div class="form-unit px-3 py-3 rounded-3">
                <div class="form-check">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "regular", class: "form-check-input") %>
                    Blind test
                  </label>
                  <%= error_tag f, :type %>
                </div>
                <div class="fs-8 text-muted ms-4 mb-1"><i class="bi bi-info-circle"></i>&nbsp;&nbsp;Select one or two options</div>
                <div class="form-check ms-4">
                  <label class="form-check-label">
                    <%= checkbox(f, :ranking, class: "form-check-input") %>
                    Ranking
                  </label>
                  <div class="form-text mb-1">People will be asked to rank the tracks</div>
                </div>
                <div class="form-check ms-4">
                  <label class="form-check-label">
                    <%= checkbox(f, :identification, class: "form-check-input") %>
                    Recognition
                  </label>
                  <div class="form-text mb-2">People will have to identify the anonymized tracks</div>
                </div>
                <div class="form-check disabled mb-2">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "abx", class: "form-check-input", disabled: true, checked: f.data.type == :abx) %>
                    ABX test
                  </label>
                  <div class="form-text mb-2">Coming soon(ish) ...</div>
                </div>
                <div class="form-check disabled">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "listening", class: "form-check-input") %>
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
                    <button class="btn btn-info" type="button" phx-click="clipboard" phx-value-text={Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)}>
                      <i class="bi bi-clipboard"></i>
                    </button>
                    <a class="btn btn-light" type="button" target="_blank" href={Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                  </div>
                </div>
                <div class="mb-3">
                  <label for="test_edit_link" class="form-label">Test edit page <span class="form-text">(this page)</span></label>
                  <div class="input-group mb-3">
                    <%= if @current_user do %>
                      <%= text_input(f, :edit_link, class: "form-control", readonly: "readonly", value: Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug)) %>
                      <button class="btn btn-info" type="button" phx-click="clipboard" phx-value-text={Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug)}>
                        <i class="bi bi-clipboard"></i>
                      </button>
                      <a class="btn btn-light" type="button" target="_blank" href={Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <% else %>
                      <%= text_input(f, :edit_link, class: "form-control", readonly: "readonly", value: Routes.test_edit_private_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)) %>
                        <button class="btn btn-info" type="button" phx-click="clipboard" phx-value-text={Routes.test_edit_private_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)}>
                          <i class="bi bi-clipboard"></i>
                        </button>
                      <a class="btn btn-light" type="button" target="_blank" href={Routes.test_edit_private_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <% end %>
                  </div>
                </div>
                <%= unless @test.type == :listening do %>
                  <div class="mb-3">
                    <label for="" class="form-label">Test private results page</label>
                    <div class="input-group mb-3">
                      <%= if @current_user do %>
                        <%= text_input(f, :results_link, class: "form-control", readonly: "readonly", value: Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug)) %>
                        <button class="btn btn-info" type="button" phx-click="clipboard" phx-value-text={Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug)}>
                          <i class="bi bi-clipboard"></i>
                        </button>
                        <a class="btn btn-light" type="button" target="_blank" href={Routes.test_results_public_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                      <% else %>
                        <%= text_input(f, :results_link, class: "form-control", readonly: "readonly", value: Routes.test_results_private_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug, f.data.password)) %>
                        <button class="btn btn-info" type="button" phx-click="clipboard" phx-value-text={Routes.test_results_private_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug, f.data.password)}>
                          <i class="bi bi-clipboard"></i>
                        </button>
                        <a class="btn btn-light" type="button" target="_blank" href={Routes.test_results_private_url(@socket, FunkyABXWeb.TestResultsLive, f.data.slug, f.data.password)}><i class="bi bi-box-arrow-up-right"></i></a>
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
                    Use <a target="_blank" href="https://www.markdownguide.org/cheat-sheet/">Markdown</a>
                  </label>
                </div>
                Description
              <% end %>
              <%= textarea(f, :description, class: "form-control", rows: "3", placeholder: "Optional") %>
              <div class="fs-8 mt-2 mb-1 cursor-link" phx-click="toggle_description">Preview&nbsp;&nbsp;<i class={"bi bi-arrow-#{if @view_description == true do "down" else "right" end}-circle"}></i></div>
              <%= if @view_description == true do %>
                <TestDescription.format description_markdown={@description_markdown} description={@description} />
              <% end %>
            </div>
          </div>
        </fieldset>

        <fieldset>
          <legend class="header-typographica"><span class="float-end fs-8 text-muted" style="font-family: var(--bs-font-sans-serif); padding-top: 12px;"><i class="bi bi-info-circle"></i>&nbsp;Two tracks minimum</span>Tracks</legend>

          <%= if @tracks_updatable == false do %>
            <div class="alert alert-danger alert-thin"><i class="bi bi-x-circle"></i>&nbsp;&nbsp;Tracks can't be modified once at least one person has taken the test.</div>
          <% else %>
            <div class="alert alert-info alert-thin"><i class="bi bi-info-circle"></i>&nbsp;&nbsp;Supported formats: wav, mp3, aac, ogg, flac ... <a href="https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats" target="_blank">(html5 audio)</a>. Wav files are converted to flac. No normalization or gain correction is applied, do it yourself :)</div>
          <% end %>

          <%= error_tag f, :tracks %>

          <div class="mb-2">
            <%= for {fp, i} <- inputs_for(f, :tracks) |> Enum.with_index(1) do %>
              <%= unless Enum.member?(@tracks_to_delete, fp.data.id) == true do %>
                <div class="row mb-1 p-2 form-unit mx-0">
                  <%= if fp.data.id != nil do %>
                    <%= hidden_input(fp, :id) %>
                    <%= hidden_input(fp, :delete) %>
                  <% else %>
                    <%= hidden_input(fp, :temp_id) %>
                  <% end %>
                  <label class="col-sm-1 col-form-label">Track #<%= i %></label>
                  <hr class="d-block d-sm-none mb-0">
                  <%= label :fp, :title, "Name:*", class: "col-sm-1 col-form-label text-start text-md-end" %>
                  <div class="col-sm-4">
                    <%= text_input fp, :title, class: "form-control", disabled: !@tracks_updatable, required: true %>
                  </div>
                  <%= label :fp, :filename, "File:", class: "col-sm-1 col-form-label text-start text-md-end mt-2 mt-md-0" %>
                  <div class="col text-center">
                    <%= if fp.data.id != nil do %>
                      <label class="col-sm-1 col-form-label w-100"><%= fp.data.original_filename %></label>
                    <% else %>
                      <%= live_file_input @uploads[String.to_atom("track" <> fp.data.temp_id)], required: true %>
                      <%= for entry <- @uploads[String.to_atom("track" <> fp.data.temp_id)].entries do %>
                        <progress value={entry.progress} max="100"> <%= entry.progress %>% </progress>
                        <%= for err <- upload_errors(@uploads[String.to_atom("track" <> fp.data.temp_id)], entry) do %>
                          <div class="alert alert-thin alert-danger"><%= error_to_string(err) %></div>
                        <% end %>
                      <%end %>
                    <% end %>
                  </div>
                    <div class="col-sm-1 text-left" style="width: 62px">
                      <%= if fp.data.id != nil do %>
                        <button type="button" class={"btn btn-dark#{if @tracks_updatable == false, do: " disabled"}"} data-confirm="Are you sure?" phx-click="delete_track" phx-value-id={fp.data.id}><i class="bi bi-trash text-danger"></i></button>
                      <% else %>
                        <button type="button" class={"btn btn-dark#{if @tracks_updatable == false, do: " disabled"}"} phx-click="remove_track" phx-value-id={fp.data.temp_id}><i class="bi bi-trash text-danger"></i></button>
                      <% end %>
                   </div>
                </div>
              <% end %>
            <% end %>
          </div>
          <div class="">
            <button type="button" class={"btn btn-secondary mt-1#{if @tracks_updatable == false, do: " disabled"}"} phx-click="add_track"><i class="bi bi-plus-lg"></i> Add a track</button>
          </div>
        </fieldset>

        <div class="mt-4 mt-md-4 text-center text-md-end">
          <%= if @action == "save" do %>
            <%= submit("Create test", class: "btn btn-lg btn-primary") %>
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
           (params["key"] != nil and params["key"] == test.password) or
             Map.get(session, "current_user_id") == test.user_id do
      tracks_updatable = !Tests.has_tests_taken?(test.id)
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
         changeset: changeset,
         test: test,
         view_description: false,
         description_markdown: test.description_markdown,
         description: test.description,
         uploaded_files: [],
         tracks_to_delete: [],
         tracks_updatable: tracks_updatable
       })}
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

    password = if user == nil, do: UUID.generate(), else: nil

    test = %Test{
      id: UUID.generate(),
      type: :regular,
      ranking: true,
      identification: false,
      password: password,
      description_markdown: false,
      tracks: [],
      user: user
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
       changeset: changeset,
       test: test,
       view_description: false,
       description_markdown: false,
       description: "",
       uploaded_files: [],
       tracks_to_delete: [],
       tracks_updatable: true
     })
     |> add_track()
     |> add_track()}
  end

  # ---------- PUB/SUB EVENTS ----------

  @impl true
  def handle_info(%{event: "test_taken"} = _payload, socket) do
    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, socket.assigns.test.tracks)

    {:noreply,
     assign(socket, %{changeset: changeset, tracks_updatable: false, tracks_to_delete: []})}
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

  # ---------- MISC EVENTS ----------

  @impl true
  def handle_event("clipboard", %{"text" => text}, socket) do
    {:noreply, push_event(socket, "clipboard", %{text: text})}
  end

  # ---------- FORM EVENTS ----------

  # Edit
  @impl true
  def handle_event("validate", %{"test" => test_params}, socket)
      when socket.assigns.action == "update" do
    changeset =
      socket.assigns.test
      |> Test.changeset_update(test_params)
      |> Map.put(:action, :update)

    {:noreply,
     assign(socket,
       changeset: changeset,
       description: test_params["description"],
       description_markdown: test_params["description_markdown"] == "true"
     )}
  end

  # New
  @impl true
  def handle_event("validate", %{"test" => test_params}, socket) do
    changeset =
      socket.assigns.test
      |> Test.changeset_update(test_params)

    # |> Map.put(:action, :insert)

    {:noreply,
     assign(socket,
       changeset: changeset,
       description: test_params["description"],
       description_markdown: test_params["description_markdown"] == "true"
     )}
  end

  # Edit
  @impl true
  def handle_event("update", %{"test" => test_params}, socket) do
    updated_tracks =
      test_params["tracks"]
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        unless Map.has_key?(t, "temp_id") == false do
          case uploaded_entries(socket, String.to_atom("track" <> t["temp_id"])) do
            {[_ | _] = entries, []} ->
              [{original_filename, filename}] =
                for entry <- entries do
                  consume_uploaded_entry(socket, entry, fn %{path: path} ->
                    filename_dest = Files.get_destination_filename(entry.client_name)

                    final_filename_dest =
                      Files.save(path, Path.join([socket.assigns.test.id, filename_dest]))

                    {entry.client_name, final_filename_dest}
                  end)
                end

              updated_track =
                Map.merge(t, %{"filename" => filename, "original_filename" => original_filename})

              Map.put(acc, k, updated_track)

            _ ->
              Map.put(acc, k, t)
          end
        else
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
        FunkyABXWeb.Endpoint.broadcast!(socket.assigns.test.id, "test_updated", nil)

        # Delete files from removed tracks
        socket.assigns.test.tracks
        |> Enum.filter(fn t -> t.id in socket.assigns.tracks_to_delete end)
        |> Enum.map(fn t -> t.filename end)
        |> Files.delete(socket.assigns.test.id)

        {:noreply,
         socket
         |> assign(test: test)
         |> put_flash(:success, "Your test has been updated !")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset, tracks_to_delete: [])}
    end
  end

  # New
  @impl true
  def handle_event("save", %{"test" => test_params}, socket) do
    updated_tracks =
      test_params
      |> Map.get("tracks", %{})
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        [{original_filename, filename}] =
          consume_uploaded_entries(socket, String.to_atom("track" <> t["temp_id"]), fn %{
                                                                                         path:
                                                                                           path
                                                                                       },
                                                                                       entry ->
            filename_dest = Files.get_destination_filename(entry.client_name)

            final_filename_dest =
              Files.save(path, Path.join([socket.assigns.test.id, filename_dest]))

            {entry.client_name, final_filename_dest}
          end)

        updated_track =
          Map.merge(t, %{"filename" => filename, "original_filename" => original_filename})

        Map.put(acc, k, updated_track)
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
          {:redirect, redirect, flash_text},
          1500
        )

        changeset = Test.changeset_update(test)

        {
          :noreply,
          socket
          |> assign(action: "update", test: test, changeset: changeset)
          |> push_event("saveTest", %{
            test_id: test.id,
            test_password: test.password,
            test_author: test.author
          })
          |> put_flash(:success, flash_text)
          #         |> push_redirect(to: redirect, replace: true)
        }

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("delete_test", _params, socket) do
    Files.delete_all(socket.assigns.test.id)
    socket.assigns.test
    |> Test.changeset_delete()
    |> Repo.update()
    |> IO.inspect()

    FunkyABXWeb.Endpoint.broadcast!(socket.assigns.test.id, "test_deleted", nil)

    flash_text = "Your test has been successfully deleted."

    Process.send_after(
      self(),
      {:redirect, Routes.info_path(socket, FunkyABXWeb.FlashLive), flash_text},
      1500
    )

    {
      :noreply,
      socket
      |> push_event("deleteTest", %{
        test_id: socket.assigns.test.id,
        test_password: socket.assigns.test.password
      })
      |> put_flash(:success, flash_text)
    }
  end

  @impl true
  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
  end

  # ---------- TRACKS ----------

  @impl true
  def handle_event("add_track", _value, socket) do
    {:noreply, add_track(socket)}
  end

  defp add_track(socket) do
    temp_id = UUID.generate()

    tracks =
      Map.get(socket.assigns.changeset.changes, :tracks, socket.assigns.test.tracks)
      |> Enum.concat([
        Track.changeset(%Track{test_id: socket.assigns.test.id, temp_id: temp_id}, %{})
      ])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    socket
    |> assign(changeset: changeset)
    |> allow_upload(String.to_atom("track" <> temp_id),
      accept: ~w(.wav .mp3 .aac .ogg),
      max_entries: 1,
      max_file_size: 50_000_000
    )
  end

  # Persisted tracks
  @impl true
  def handle_event("delete_track", %{"id" => track_id}, socket) do
    tracks =
      socket.assigns.changeset.data.tracks
      # map tracks to a "param" map, didn't find without that step
      |> Enum.map(fn track ->
        track_map = %{
          id: track.id,
          temp_id: track.temp_id,
          title: track.title,
          delete: nil
        }

        case Map.get(track, :id, nil) do
          nil ->
            track_map

          id ->
            if id == track_id do
              %{track_map | delete: true}
            else
              track_map
            end
        end
      end)

    updated_tracks_to_delete = socket.assigns.tracks_to_delete ++ [track_id]

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.cast(%{"tracks" => tracks}, [])
      |> Ecto.Changeset.cast_assoc(:tracks)

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

    {:noreply, assign(socket, %{changeset: changeset})}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
