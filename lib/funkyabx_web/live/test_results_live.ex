defmodule FunkyABXWeb.TestResultsLive do
  use FunkyABXWeb, :live_view

  alias FunkyABXWeb.PlayerComponent
  alias FunkyABX.{Utils, Tests, Tracks}
  alias FunkyABX.Test
  alias FunkyABX.Tests.Image

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="row" id="test-results-global" phx-hook="Global">
        <div class="col-12">
          <div class="d-flex justify-content-between">
            <div class="flex-grow-1">
              <h3
                class="mb-2 header-funky"
                id="test-results-header"
                phx-hook="TestResults"
                data-testid={@test.id}
              >
                {@test.title}
              </h3>
              <h5 :if={@test.author != nil} class="header-funky">
                {dgettext("test", "By %{author}", author: @test.author)}
              </h5>
            </div>
            <div class="text-end">
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
                {raw(
                  dngettext(
                    "test",
                    "Test taken <strong>%{count}</strong> time",
                    "Test taken <strong>%{count}</strong> times",
                    @test_taken_times
                  )
                )}
              </div>

              <div
                :if={@test.local == false}
                class="d-flex justify-content-start justify-content-md-end"
              >
                <div class="fs-7 me-2 text-white-50 header-texgyreadventor">
                  <time title={@test.inserted_at} datetime={@test.inserted_at}>
                    <small>
                      {raw(
                        dgettext(
                          "test",
                          "Test created on <time datetime=\"%{created_at}\">%{created_at_format}</time>",
                          created_at: @test.inserted_at,
                          created_at_format:
                            format_date(@test.inserted_at, timezone: @timezone, format: :short)
                        )
                      )}
                    </small>
                  </time>
                </div>
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
                    {raw(
                      dgettext(
                        "test",
                        "Test closing on <time datetime=\"%{to_close_at}\">%{to_close_at_format}</time>",
                        to_close_at: @test.to_close_at,
                        to_close_at_format: format_date_time(@test.to_close_at, timezone: @timezone)
                      )
                    )}
                  </small>
                </time>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%= if @test.description != nil do %>
        <%= if @view_description == false do %>
          <div class="fs-8 mt-2 cursor-link text-body-secondary" phx-click="toggle_description">
            {dgettext("test", "View description")}&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i>
          </div>
        <% else %>
          <div class="fs-8 mt-2 cursor-link text-body-secondary" phx-click="toggle_description">
            {dgettext("test", "Hide description")}&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i>
          </div>
          <TestDescriptionComponent.format
            wrapper_class="my-2 p-3 test-description"
            description_markdown={@test.description_markdown}
            description={@test.description}
          />
        <% end %>
      <% end %>

      <%= if Tests.can_have_player_on_results_page?(@test)
        and @tracks != nil and @tracks_order != nil and @is_another_session == false do %>
        <%= if @view_test_tracks == false do %>
          <div class="fs-8 mt-3 cursor-link text-body-secondary" phx-click="toggle_test_tracks">
            {dgettext("test", "View your test")}&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i>
          </div>
        <% else %>
          <div class="fs-8 mt-3 cursor-link text-body-secondary" phx-click="toggle_test_tracks">
            {dgettext("test", "Hide your test")}&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i>
          </div>

          <.live_component
            module={PlayerComponent}
            id="player"
            test={@test}
            tracks={@tracks}
            choices_taken={@visitor_choices}
            test_already_taken={true}
            increment_view_counter={false}
          />
        <% end %>
      <% end %>

      <div
        :if={@test.local == false and @is_another_session == false and @session_id != nil}
        class="row"
      >
        <div class="col-12">
          <h5 class="mt-4 header-neon">{dgettext("test", "Your test:")}</h5>
          <div class="your-test rounded p-2 mb-3" style="max-width: 300px;">
            <div class="mb-1">
              <i class="bi bi-share"></i>&nbsp;&nbsp;{dgettext("test", "Share:")}
              <a href={url(~p"/results/#{@test.slug}?s=#{ShortUUID.encode!(@session_id)}") <> Utils.embedize_url(@embed, "&")}>
                {dgettext("test", "link to my results")}
              </a>
            </div>
            <div>
              <i class="bi bi-image"></i>&nbsp;&nbsp;{dgettext("test", "Image:")}
              <a target="_blank" href={url(~p"/img/results/#{Image.get_filename(@session_id)}")}>
                {dgettext("test", "my results")}
              </a>
            </div>
          </div>
        </div>
      </div>

      <%= for module <- @result_modules do %>
        <.live_component
          module={module}
          id={Atom.to_string(module)}
          test={@test}
          visitor_choices={@visitor_choices}
          is_another_session={@is_another_session}
          play_track_id={@play_track_id}
          test_taken_times={@test_taken_times}
          tracks_order={@tracks_order}
        />
      <% end %>

      <div :if={@test.hide_global_results == true} class="mt-3 text-muted">
        <small>{dgettext("test", "Global results have been hidden by test creator.")}</small>
      </div>

      <div :if={@test.local == true} class="mt-3 d-flex justify-content-between results-actions">
        <div>
          <i class="bi bi-arrow-left color-action"></i>&nbsp;<.link
            navigate={~p"/local_test/edit/#{@test_data}"}
            replace={true}
          >{dgettext "test", "Go back to the test form"}</.link>
        </div>
        <div>
          <i class="bi bi-arrow-repeat color-action"></i>&nbsp;<.link
            navigate={~p"/local_test/#{@test_data}"}
            replace={true}
          >{dgettext "test", "Take the test again"}</.link>
        </div>
        <div>
          <i class="bi bi-plus color-action"></i>&nbsp;<.link
            href={~p"/local_test"}
            class="color-action"
          >{dgettext "test", "Create a new local test"}</.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Local test
  @impl true
  def mount(%{"data" => data, "choices" => choices} = params, _session, socket) do
    test_data =
      data
      |> Base.url_decode64!()
      |> Jason.decode!()

    choices_taken =
      choices
      |> Base.url_decode64!()
      |> Jason.decode!()

    tracks_order =
      case Map.get(params, "tracks_order") do
        order when is_binary(order) ->
          order
          |> Base.url_decode64!()
          |> Jason.decode!()

        _ ->
          nil
      end

    {:ok, test} =
      Test.new_local()
      |> Test.changeset_local(test_data)
      |> Ecto.Changeset.apply_action(:update)

    tracks =
      test.tracks
      |> Tracks.prep_tracks(test, tracks_order)
      |> Tests.prep_tracks(test, tracks_order)

    result_modules = Tests.get_result_modules(test)

    {:ok,
     socket
     |> assign(%{
       page_title: dgettext("test", "Local test results"),
       test: test,
       tracks: tracks,
       result_modules: result_modules,
       current_user_id: nil,
       view_description: false,
       view_test_tracks: false,
       visitor_choices: choices_taken,
       play_track_id: nil,
       test_taken_times: nil,
       test_data: data,
       tracks_order: tracks_order,
       is_another_session: false,
       embed: nil
     })
     |> push_event("set_warning_local_test_reload", %{set: true})}
  end

  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    embed = Map.get(session, "embedded")

    with %Test{} = test <- Tests.get_by_slug(slug) do
      result_modules = Tests.get_result_modules(test)

      if connected?(socket) do
        FunkyABXWeb.Endpoint.subscribe(test.id)
        Tests.update_last_viewed(test)
      end

      timezone =
        case get_connect_params(socket) do
          nil -> "Etc/UTC"
          params -> Map.get(params, "timezone", "Etc/UTC")
        end

      {is_another_session, session_id, choices} =
        case Tests.parse_session_id(Map.get(params, "s")) do
          nil ->
            {false, nil, %{}}

          session_id ->
            choices = Tests.get_results_of_session(test, session_id)
            {true, session_id, choices}
        end

      {:ok,
       assign(socket, %{
         page_title:
           dgettext("test", "Test results - %{test_title}",
             test_title: String.slice(test.title, 0..@title_max_length)
           ),
         timezone: timezone,
         test: test,
         tracks: nil,
         result_modules: result_modules,
         current_user_id: Map.get(session, "current_user_id"),
         view_description: false,
         view_test_tracks: false,
         visitor_choices: choices,
         session_id: session_id,
         tracks_order: nil,
         is_another_session: is_another_session,
         test_taken_times: Tests.get_how_many_taken(test),
         play_track_id: nil,
         embed: embed,
         is_test_creator_or_has_access_key:
           (Map.get(session, "current_user_id") == test.user_id and test.user_id != nil) or
             (Map.get(params, "key") != nil and Map.get(params, "key") == test.access_key)
       })}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(
           :info,
           dgettext("test", "Please take the test before checking the results.")
         )
         |> assign(test_already_taken: false)
         |> redirect(to: ~p"/test/#{slug}" <> Utils.embedize_url(embed))}
    end
  end

  @impl true
  def handle_event("test_not_taken", _params, socket) do
    with false <- socket.assigns.test.local,
         true <- Map.get(socket.assigns, :is_test_creator_or_has_access_key) != true,
         false <- Tests.is_closed?(socket.assigns.test) do
      {:noreply,
       socket
       |> put_flash(
         :info,
         dgettext("test", "Please take the test before checking the results.")
       )
       |> redirect(
         to: ~p"/test/#{socket.assigns.test.slug}" <> Utils.embedize_url(socket.assigns.embed)
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  # ---------- EVENTS ----------

  # discard when when fetch another session
  @impl true
  def handle_event("results", _params, socket) when socket.assigns.is_another_session == true,
    do: {:noreply, socket}

  @impl true
  def handle_event("results", params, socket) do
    {
      :noreply,
      socket
      |> assign(:visitor_choices, params)
      #     |> assign(
      #       :visitor_identification_score,
      #       calculate_identification_score(Map.get(params, "identification", %{}))
      #     )
    }
  end

  # discard when when fetch another session
  @impl true
  def handle_event("session_id", _params, socket) when socket.assigns.is_another_session == true,
    do: {:noreply, socket}

  @impl true
  def handle_event("session_id", params, socket) do
    {:noreply, assign(socket, :session_id, params)}
  end

  # discard when when fetch another session
  @impl true
  def handle_event("tracks_order", _params, socket)
      when socket.assigns.is_another_session == true,
      do: {:noreply, socket}

  @impl true
  def handle_event("tracks_order", params, socket) do
    tracks =
      socket.assigns.test.tracks
      |> Tracks.prep_tracks(socket.assigns.test, params)
      |> Tests.prep_tracks(socket.assigns.test, params)

    {:noreply, assign(socket, %{tracks_order: params, tracks: tracks})}
  end

  # ---------- PLAYER ----------

  @impl true
  def handle_event("playing_audio", %{"track_id" => track_id} = _params, socket) do
    {:noreply, assign(socket, :play_track_id, track_id)}
  end

  @impl true
  def handle_event("stopping_audio", _params, socket) do
    {:noreply, assign(socket, :play_track_id, nil)}
  end

  # ---------- UI ----------

  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
  end

  def handle_event("toggle_test_tracks", _value, socket) do
    toggle = !socket.assigns.view_test_tracks

    {:noreply, assign(socket, view_test_tracks: toggle)}
  end

  # todo move to component

  #  def handle_event("toggle_identification_detail", _value, socket) do
  #    toggle = !socket.assigns.identification_detail
  #
  #    {:noreply, assign(socket, identification_detail: toggle)}
  #  end

  # ---------- PUB/SUB EVENTS ----------

  @impl true
  def handle_info(%{event: "test_updated"} = _payload, socket) do
    test = Tests.get(socket.assigns.test.id)

    {:noreply,
     assign(socket, %{
       test: test
     })}
  end

  @impl true
  def handle_info(%{event: "test_taken"} = _payload, socket) do
    # todo manage refresh of the data on components
    {:noreply,
     socket
     |> put_flash(:info, dgettext("test", "Someone just took this test!"))
     |> assign(%{
       test_taken_times: socket.assigns.test_taken_times + 1
     })}
  end

  @impl true
  def handle_info(%{event: "test_deleted"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:error, dgettext("test", "This test has been deleted :("))
     |> redirect(to: ~p"/info" <> Utils.embedize_url(socket.assigns.embed))}
  end

  @impl true
  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
  end
end
