defmodule FunkyABXWeb.TestFormLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use FunkyABXWeb, :live_view
  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.Tests
  alias FunkyABX.Test
  alias FunkyABX.Track

  @title_max_length 100

  def render(assigns) do
    ~H"""
      <.form let={f} for={@changeset} phx-change="validate" phx-submit={@action}>
        <%= hidden_input(f, :password) %>
        <div class="row">
          <div class="col-sm-6">
            <h3 class="mb-3 mt-0 header-chemyretro">
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
                    <%= radio_button(f, :type, "regular", class: "form-check-input", checked: f.data.type == :regular) %>
                    Blind test
                  </label>
                  <%= error_tag f, :type %>
                </div>
                <div class="fs-7 text-muted ms-4 mb-1"><i class="bi bi-info-circle"></i>&nbsp;&nbsp;Select one or two option</div>
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
                  <div class="form-text mb-2">(coming soon ...)</div>
                </div>
                <div class="form-check disabled">
                  <label class="form-check-label">
                    <%= radio_button(f, :type, "listening", class: "form-check-input", disabled: true, checked: f.data.type == :listening) %>
                    No test, only listening
                  </label>
                  <div class="form-text mb-0">(coming soon ...)</div>
                </div>
              </div>
            </fieldset>
          </div>
          <div class="offset-sm-1 col-sm-5">
            <%= if @action == "update" do %>
            <fieldset class="form-group mb-3">
              <legend class="header-typographica">Your test</legend>
              <div class="px-3 pt-2 pb-3 rounded-3" style="background-color: #5a3d2b;">
                <div class="mb-3">
                  <%= label :f, :public_link, "Public page link", class: "form-label" %>
                  <div class="input-group mb-3">
                    <%= text_input(f, :public_link, class: "form-control", readonly: "readonly", value: Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)) %>
                    <a class="btn btn-primary" type="button" target="_blank" href={Routes.test_public_url(@socket, FunkyABXWeb.TestLive, f.data.slug)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <!--<button class="btn btn-secondary" type="button" onclick="navigator.clipboard.writeText('');"><i class="bi bi-clipboard"></i></button>-->
                  </div>
                </div>
                <div class="mb-3">
                  <label for="" class="form-label">Edit page link <span class="form-text">(this page)</span></label>
                  <div class="input-group mb-3">
                    <%= text_input(f, :edit_link, class: "form-control", readonly: "readonly", value: Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)) %>
                    <a class="btn btn-primary" type="button" target="_blank" href={Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <!--<button class="btn btn-secondary" type="button"><i class="bi bi-clipboard"></i></button>-->
                  </div>
                </div>
                <div class="mb-3">
                  <label for="" class="form-label">Results page</label>
                  <div class="input-group mb-3">
                    <%= text_input(f, :edit_link, class: "form-control", readonly: "readonly", value: Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)) %>
                    <a class="btn btn-primary" type="button" target="_blank" href={Routes.test_edit_url(@socket, FunkyABXWeb.TestFormLive, f.data.slug, f.data.password)}><i class="bi bi-box-arrow-up-right"></i></a>
                    <!--<button class="btn btn-secondary" type="button"><i class="bi bi-clipboard"></i></button>-->
                  </div>
                </div>
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
              <div class="col-sm-6">
                <%= label :f, :title, "Title*", class: "form-label" %>
                <%= text_input(f, :title, class: "form-control") %>
                <%= error_tag f, :title %>
              </div>
              <div class="col-sm-6">
                <%= label :f, :author, "Created by", class: "form-label" %>
                <%= text_input(f, :author, class: "form-control") %>
              </div>
            </div>
            <div class="mb-2">
              <%= label :f, :description, class: "form-label w-100" do %>
                <span class="float-end fs-7 text-muted pt-1"><i class="bi bi-info-circle"></i>&nbsp;Markdown is supported</span>Description
              <% end %>
              <%= textarea(f, :description, class: "form-control", rows: "2") %>
              <div class="fs-7 mt-1 cursor-link" phx-click="toggle_description">Preview&nbsp;&nbsp;<i class={"bi bi-arrow-#{if (@view_description == true) do "down" else "right" end}-circle"}></i></div>
              <%= if (@view_description == true) do %>
              <div>
                <%= raw(Earmark.as_html!(@description, escape: true, inner_html: true)) %>
              </div>
              <% end %>
            </div>
          </div>
        </fieldset>

        <fieldset>
          <legend class="header-typographica"><span class="float-end fs-7 text-muted" style="padding-top: 13px;">Two tracks minimum</span>Tracks</legend>
          <div class="alert alert-info alert-thin"><i class="bi bi-info-circle"></i>&nbsp;&nbsp;Formats supported: wav, mp3, aac, ogg, flac ... <a href="https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats" target="_blank">(details)</a>. Wav files are converted to flac.</div>
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
                  <%= label :fp, :title, "Name:", class: "col-sm-1 col-form-label text-end" %>
                  <div class="col-sm-4">
                    <%= text_input fp, :title, class: "form-control" %>
                  </div>
                  <%= label :fp, :filename, "File:", class: "col-sm-1 col-form-label text-end" %>
                  <div class="col text-center">
                    <%= if fp.data.id != nil do %>
                      <label class="col-sm-1 col-form-label w-100"><%= fp.data.original_filename %></label>
                    <% else %>
                      <%= live_file_input @uploads[String.to_atom("track" <> fp.data.temp_id)] %>
                    <% end %>
                  </div>
                    <div class="col-sm-1 text-left" style="width: 62px">
                      <%= if fp.data.id != nil do %>
                        <button type="button" class="btn btn-dark" data-confirm="Are you sure?" phx-click="delete_track" phx-value-id={fp.data.id}><i class="bi bi-trash text-danger"></i></button>
                      <% else %>
                        <button type="button" class="btn btn-dark" phx-click="remove_track" phx-value-id={fp.data.temp_id}><i class="bi bi-trash text-danger"></i></button>
                      <% end %>
                   </div>
                </div>
              <% end %>
            <% end %>
          </div>
          <div class="">
            <button type="button" class="btn btn-secondary mt-1" phx-click="add_track"><i class="bi bi-plus-lg"></i> Add a track</button>
          </div>
        </fieldset>

        <div class="mt-2 text-end">
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
  def mount(%{"slug" => slug, "key" => key} = _params, %{}, socket) do
    test = Tests.get_edit(slug, key)
    changeset = Test.changeset_update(test)

    {:ok,
     assign(socket, %{
       action: "update",
       changeset: changeset,
       test: test,
       view_description: false,
       description: test.description,
       uploaded_files: [],
       tracks_to_delete: []
     })}
  end

  # New
  def mount(_params, %{}, socket) do
    test = %Test{
      id: UUID.generate(),
      type: :regular,
      ranking: true,
      identification: false,
      password: UUID.generate(),
      tracks: []
    }

    changeset =
      Test.changeset(test)

    {:ok,
     assign(socket, %{
       action: "save",
       changeset: changeset,
       test: test,
       view_description: false,
       description: "",
       uploaded_files: [],
       tracks_to_delete: []
     })}
  end

  # ---------- FORM EVENTS ----------

  # Edit
  def handle_event("validate", %{"test" => test_params}, socket)
      when socket.assigns.action == "update" do
    changeset =
      socket.assigns.test
      |> Test.changeset_update(test_params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset, description: test_params["description"])}
  end

  # New
  def handle_event("validate", %{"test" => test_params}, socket) do
    changeset =
      socket.assigns.test
      |> Test.changeset(test_params)
      |> Map.put(:action, :insert)

    IO.puts("#{inspect(test_params)}")

    {:noreply, assign(socket, changeset: changeset, description: test_params["description"])}
  end

  # Edit
  def handle_event("update", %{"test" => test_params}, socket) do
    updated_tracks =
      test_params["tracks"]
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        unless Map.has_key?(t, "temp_id") == false do
          case uploaded_entries(socket, String.to_atom("track" <> t["temp_id"])) do
            {[_|_] = entries, []} ->
              [{original_filename, filename}] = for entry <- entries do
                consume_uploaded_entry(socket, entry, fn %{path: path} ->
                  filename_dest =
                    Integer.to_string(DateTime.to_unix(DateTime.now!("Etc/UTC"))) <>
                    "_" <>
                    Base.encode16(:crypto.hash(:sha, entry.client_name)) <>
                    Path.extname(entry.client_name)

                  dest = Path.join([:code.priv_dir(:funkyabx), "static", "uploads", filename_dest])
                  File.cp!(path, dest)
                  {entry.client_name, filename_dest}
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
        {:noreply,
         socket
         |> assign(test: test)
         |> put_flash(:success, "Your test has been updated !")
         |> redirect(
           to:
             Routes.test_edit_path(
               FunkyABXWeb.Endpoint,
               FunkyABXWeb.TestFormLive,
               test.slug,
               test.password
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # New
  def handle_event("save", %{"test" => test_params}, socket) do
    updated_tracks =
      test_params["tracks"]
      |> Enum.reduce(%{}, fn {k, t}, acc ->
        [{original_filename, filename}] =
          consume_uploaded_entries(socket, String.to_atom("track" <> t["temp_id"]), fn %{path: path}, entry ->
            filename_dest =
              Integer.to_string(DateTime.to_unix(DateTime.now!("Etc/UTC"))) <>
                "_" <>
                Base.encode16(:crypto.hash(:sha, entry.client_name)) <>
                Path.extname(entry.client_name)

            dest = Path.join([:code.priv_dir(:funkyabx), "static", "uploads", filename_dest])
            File.cp!(path, dest)
            {entry.client_name, filename_dest}
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
        {:noreply,
         socket
         |> assign(action: "update", test: test)
         |> put_flash(:success, "Your test has been successfully created !")
         |> redirect(
           to:
             Routes.test_edit_path(
               FunkyABXWeb.Endpoint,
               FunkyABXWeb.TestFormLive,
               test.slug,
               test.password
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("delete_test", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
  end

  # ---------- TRACKS ----------

  def handle_event("add_track", _value, socket) do
    temp_id = UUID.generate()

    tracks =
      Map.get(socket.assigns.changeset.changes, :tracks, socket.assigns.test.tracks)
      |> Enum.concat([
        Track.changeset(%Track{test_id: socket.assigns.test.id, temp_id: temp_id}, %{})
      ])

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:tracks, tracks)

    {:noreply,
     socket
     |> assign(changeset: changeset)
     |> allow_upload(String.to_atom("track" <> temp_id),
       accept: ~w(.wav .mp3 .aac),
       max_entries: 1
     )}
  end

  # Persisted tracks
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

    {:noreply, assign(socket, %{changeset: changeset, tracks_to_delete: updated_tracks_to_delete})}
  end

  # New tracks
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
end
