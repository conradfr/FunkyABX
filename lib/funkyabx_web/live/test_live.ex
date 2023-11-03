defmodule FunkyABXWeb.TestLive do
  require Logger
  use FunkyABXWeb, :live_view

  alias Ecto.UUID
  alias FunkyABXWeb.PlayerComponent
  alias FunkyABX.{Utils, Tests, Tracks, Invitations}
  alias FunkyABX.Test

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
    <div class="row" id="test-global" phx-hook="Global">
      <div class="col-sm-6">
        <h3 class="mb-0 header-typographica" id="test-header" phx-hook="Test" data-testid={@test.id}>
          <%= @test.title %>
        </h3>
        <h6 :if={@test.author != nil} class="header-typographica">
          <%= dgettext("test", "By %{author}", author: @test.author) %>
        </h6>
      </div>
      <div class="col-sm-6 text-start text-sm-end pt-1 mb-1 mb-md-0">
        <div
          :if={@test.local == false and @test.type != :listening}
          class="fs-7 text-body-secondary header-texgyreadventor"
          title={
            if @test.view_count != nil,
              do:
                dngettext(
                  "test",
                  "Test played %{count} time",
                  "Test played %{count} times",
                  @test.view_count
                ),
              else: ""
          }
        >
          <%= raw(
            dngettext(
              "test",
              "Test taken <strong>%{count}</strong> time",
              "Test taken <strong>%{count}</strong> times",
              @test_taken_times
            )
          ) %>
        </div>

        <div :if={@test.local == false} class="d-flex justify-content-start justify-content-md-end">
          <div class="fs-7 me-2 text-white-50 header-texgyreadventor">
            <time title={@test.inserted_at} datetime={@test.inserted_at}>
              <small>
                <%= raw(
                  dgettext(
                    "test",
                    "Test created on <time datetime=\"%{created_at}\">%{created_at_format}</time>",
                    created_at: @test.inserted_at,
                    created_at_format:
                      format_date(@test.inserted_at, timezone: @timezone, format: :short)
                  )
                ) %>
              </small>
            </time>
          </div>
          <.live_component module={TestFlagComponent} id="flag" test={@test} />
        </div>

        <div
          :if={
            @test.local == false and @test.to_close_at_enabled == true and
              Tests.is_closed?(@test) == false
          }
          class="fs-7 text-white-50 header-texgyreadventor"
        >
          <time
            class="header-texgyreadventor text-white-50"
            title={@test.to_close_at}
            datetime={@test.to_close_at}
          >
            <small>
              <%= raw(
                dgettext(
                  "test",
                  "Test closing on <time datetime=\"%{to_close_at}\">%{to_close_at_format}</time>",
                  to_close_at: @test.to_close_at,
                  to_close_at_format: format_date_time(@test.to_close_at, timezone: @timezone)
                )
              ) %>
            </small>
          </time>
        </div>
      </div>
    </div>

    <TestDescriptionComponent.format
      :if={@test.description != nil}
      wrapper_class="mt-2 p-3 test-description"
      description_markdown={@test.description_markdown}
      description={@test.description}
    />

    <%= if @view_tracklist == false do %>
      <div class="fs-8 mt-2 mb-2 cursor-link text-body-secondary" phx-click="toggle_tracklist">
        Tracklist&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i>
      </div>
    <% else %>
      <div class="fs-8 mt-2 cursor-link text-body-secondary" phx-click="toggle_tracklist">
        Hide tracklist&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i>
      </div>
      <div class="test-tracklist-bg mt-2 mb-4 p-3 py-2">
        <%= for track <- @test.tracks do %>
          <div class="test-tracklist-one">- <%= track.title %></div>
        <% end %>
      </div>
    <% end %>

    <.live_component
      module={PlayerComponent}
      id="player"
      test={@test}
      tracks={@tracks}
      current_round={@current_round}
      choices_taken={@choices_taken}
      test_already_taken={@test_already_taken}
    />

    <div class="mt-3">
      <div class="d-flex flex-row align-items-center justify-content-between">
        <%= unless @test_params.has_choices == false do %>
          <div :if={@test.local == true} class="results-actions">
            <i :if={@tracks_loaded == true} class="bi bi-arrow-left color-action"></i>&nbsp;<.link
              navigate={~p"/local_test/edit/#{@test_data}"}
              replace={true}
            ><%= dgettext "test", "Go back to the test form" %></.link>
          </div>
          <div :if={@test.local == true} class="results-actions">
            <i class="bi bi-plus color-action"></i>&nbsp;<.link
              href={~p"/local_test"}
              class="color-action"
            ><%= dgettext "test", "Create a new local test" %></.link>
          </div>
          <%= unless @test_already_taken == true or Tests.is_closed?(@test) == true do %>
            <%= unless @test.local == true do %>
              <div class="px-1">
                <button
                  phx-click="no_participate"
                  class="btn btn-sm btn-outline-dark"
                  data-confirm={
                    dgettext(
                      "test",
                      "Are you sure you want to check the results? You won't be able to participate afterwards."
                    )
                  }
                >
                  <%= gettext("Check the results without participating") %>
                </button>
              </div>
            <% end %>
            <div class="text-end px-1 _flex-fill">
              <button
                phx-click="submit"
                class={"btn btn-primary#{unless (@valid == true), do: " disabled"}"}
              >
                <%= dgettext("test", "Submit my choices") %>
              </button>
            </div>
          <% else %>
            <div class="text-end px-1 flex-fill">
              <.link
                :if={@test.local == false}
                href={~p"/results/#{@test.slug}"}
                class="btn btn-primary"
              >
                <%= dgettext("test", "Check the results") %>
              </.link>
            </div>
          <% end %>
        <% else %>
          <div class="px-1">
            <button
              :if={@test.anonymized_track_title == false}
              phx-click="hide_and_shuffle_tracks"
              class="btn btn-sm btn-outline-dark"
            >
              <%= dgettext("test", "Hide titles and shuffle tracks") %>
            </button>
            <button
              :if={@test.anonymized_track_title == true}
              phx-click="hide_and_shuffle_tracks"
              class="btn btn-sm btn-outline-dark"
            >
              <%= dgettext("test", "Reveal tracks' titles") %>
            </button>
          </div>
        <% end %>
      </div>
    </div>

    <DisqusComponent.load :if={@disqus} test={@test} />
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

    {:ok,
     socket
     |> assign(%{
       page_title: "Local test",
       test_data: data,
       test: test,
       tracks: tracks,
       tracks_loaded: false,
       test_params: test_params,
       current_round: 1,
       current_track: nil,
       changeset: changeset,
       choices_taken: %{},
       valid: false,
       #       test_already_taken: Map.get(session, "test_taken_" <> slug, false),
       test_already_taken: false,
       view_tracklist: false,
       disqus: false
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

    if connected?(socket) do
      FunkyABXWeb.Endpoint.subscribe(test.id)
      Tests.update_last_viewed(test)
    end

    tracks =
      test.tracks
      |> Tracks.prep_tracks(test)
      |> Tests.prep_tracks(test)

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

    embed = Map.get(session, "embed", false)

    {:ok,
     assign(socket, %{
       page_title: String.slice(test.title, 0..@title_max_length),
       page_id: Utils.get_page_id_from_socket(socket),
       timezone: timezone,
       ip_address: Map.get(session, "visitor_ip", nil),
       test: test,
       tracks: tracks,
       tracks_loaded: false,
       test_params: test_params,
       session_id: session_id,
       current_round: 1,
       current_track: nil,
       changeset: changeset,
       choices_taken: %{},
       valid: false,
       flag_display: false,
       test_taken_times: Tests.get_how_many_taken(test),
       test_already_taken: test_already_taken,
       view_tracklist: test.description == nil,
       embed: embed,
       invitation_id: invitation_id,
       disqus: test.type == :listening and test.local == false and embed != true
     })
     |> then(fn s ->
       if Tests.is_closed?(test) == true do
         link = url(~p"/results/#{s.assigns.test.slug}")

         put_flash(
           s,
           :info,
           dgettext(
             "test",
             "This test is closed. <a href=\"%{link}\">Check the results</a>",
             link: link
           )
           |> raw()
         )
       else
         s
       end
     end)
     |> then(fn s ->
       if test_already_taken == true and invitation_id != nil do
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
  def handle_info(%{event: "test_taken", payload: page_id} = _payload, socket) do
    unless page_id == socket.assigns.page_id,
      do:
        dgettext("test", "Someone just took this test!")
        |> Utils.send_success_toast(socket.assigns.page_id)

    {:noreply, assign(socket, :test_taken_times, socket.assigns.test_taken_times + 1)}
  end

  @impl true
  def handle_info(%{event: "test_opened"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "This test has been reopened.")
     |> redirect(to: ~p"/test/#{socket.assigns.test.slug}")}
  end

  @impl true
  def handle_info(%{event: "test_closed"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(
       :info,
       dgettext(
         "test",
         "This test is closed. <a href=\"%{results_url}\">Check the results</a>",
         results_url: ~p"/results/#{socket.assigns.test.slug}"
       )
       |> raw()
     )
     |> redirect(to: ~p"/test/#{socket.assigns.test.slug}")}
  end

  @impl true
  def handle_info(%{event: "test_deleted"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:error, dgettext("test", "This test has been deleted :("))
     |> redirect(to: ~p"/info")}
  end

  @impl true
  def handle_info(%{event: "test_updated"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(
       :info,
       dgettext("test", "Test has been updated by its creator, so the page has been reloaded.")
     )
     |> redirect(to: ~p"/test/#{socket.assigns.test.slug}")}
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

      tracks_order =
        if test.type == :regular do
          tracks
          |> Enum.with_index(1)
          |> Enum.reduce(%{}, fn {track, i}, acc ->
            Map.put(acc, track.id, i)
          end)
          |> Jason.encode!()
          |> Base.url_encode64()
        end

      url =
        ~p"/local_test/results/#{socket.assigns.test_data}/#{choices_cleaned}"
        |> then(fn url ->
          case tracks_order do
            nil -> url
            _ -> url <> "/" <> tracks_order
          end
        end)

      {:noreply,
       socket
       |> push_redirect(
         to: url,
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
      Logger.info("Test taken (#{test.slug})")

      choices_cleaned = Tests.clean_choices(choices, tracks, test)

      tracks_order =
        if test.type == :regular do
          tracks
          |> Enum.filter(fn t -> t.reference_track == false end)
          |> Enum.with_index(1)
          |> Enum.reduce(%{}, fn {track, i}, acc ->
            Map.put(acc, track.id, i)
          end)
        end

      Tests.submit(test, choices_cleaned, session_id, ip_address)

      spawn(fn ->
        FunkyABXWeb.Endpoint.broadcast!(test.id, "test_taken", socket.assigns.page_id)
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
       |> push_event("store_test", %{
         choices: choices_cleaned,
         session_id: session_id,
         tracks_order: tracks_order
       })
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
end
