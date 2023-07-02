defmodule FunkyABXWeb.TestResultsLive do
  use FunkyABXWeb, :live_view

  alias FunkyABX.{Utils, Tests, Test}
  alias FunkyABX.Tests.Image

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
    <div class="row">
      <div class="col-sm-6">
        <h3
          class="mb-0 header-typographica"
          id="test-results-header"
          phx-hook="TestResults"
          data-testid={@test.id}
        >
          <%= @test.title %>
        </h3>
        <h6 :if={@test.author != nil} class="header-typographica">
          <%= dgettext("test", "By %{author}", author: @test.author) %>
        </h6>
      </div>
      <%= unless @test.type == :listening or @test.local == true do %>
        <div class="col-sm-6 text-start text-sm-end pt-1 pt-sm-3">
          <span class="fs-7 text-body-secondary header-texgyreadventor">
            <%= raw(
              dngettext(
                "test",
                "Test taken <strong>%{count}</strong> time",
                "Test taken <strong>%{count}</strong> times",
                @test_taken_times
              )
            ) %>
          </span>
          <time
            :if={Tests.is_closed?(@test)}
            class="header-texgyreadventor text-body-secondary"
            title={@test.closed_at}
            datetime={@test.closed_at}
          >
            <br /><small><%= dgettext("test", "(test is closed)") %></small>
          </time>
        </div>
      <% end %>
    </div>

    <%= if @test.description != nil do %>
      <%= if @view_description == false do %>
        <div class="fs-8 mt-2 cursor-link text-body-secondary" phx-click="toggle_description">
          <%= dgettext("test", "View description") %>&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i>
        </div>
      <% else %>
        <div class="fs-8 mt-2 cursor-link text-body-secondary" phx-click="toggle_description">
          <%= dgettext("test", "Hide description") %>&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i>
        </div>
        <TestDescriptionComponent.format
          wrapper_class="my-2 p-3 test-description"
          description_markdown={@test.description_markdown}
          description={@test.description}
        />
      <% end %>
    <% end %>

    <div
      :if={@test.local == false and @is_another_session == false and @session_id != nil}
      class="row"
    >
      <div class="col-12 col-sm-3">
        <h5 class="mt-3 header-neon"><%= dgettext("test", "Your test:") %></h5>
        <div class="your-test rounded p-2 mb-4">
          <div class="mb-1">
            <i class="bi bi-share"></i>&nbsp;&nbsp;<%= dgettext("test", "Share:") %>
            <a href={url(~p"/results/#{@test.slug}?s=#{ShortUUID.encode!(@session_id)}")}>
              <%= dgettext("test", "link to my results") %>
            </a>
          </div>
          <div>
            <i class="bi bi-image"></i>&nbsp;&nbsp;<%= dgettext("test", "Image:") %>
            <a target="_blank" href={url(~p"/img/results/#{Image.get_filename(@session_id)}")}>
              <%= dgettext("test", "my results") %>
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

    <div :if={@test.local == true} class="mt-3 d-flex justify-content-between results-actions">
      <div>
        <i class="bi bi-arrow-left color-action"></i>&nbsp;<.link
          navigate={~p"/local_test/edit/#{@test_data}"}
          replace={true}
        ><%= dgettext "test", "Go back to the test form" %></.link>
      </div>
      <div>
        <i class="bi bi-arrow-repeat color-action"></i>&nbsp;<.link
          navigate={~p"/local_test/#{@test_data}"}
          replace={true}
        ><%= dgettext "test", "Take the test again" %></.link>
      </div>
      <div>
        <i class="bi bi-plus color-action"></i>&nbsp;<.link
          href={~p"/local_test"}
          class="color-action"
        ><%= dgettext "test", "Create a new local test" %></.link>
      </div>
    </div>

    <DisqusComponent.load :if={@test.local == false and @embed != true} test={@test} />
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

    result_modules = Tests.get_result_modules(test)

    {:ok,
     assign(socket, %{
       page_title: dgettext("test", "Local test results"),
       test: test,
       result_modules: result_modules,
       current_user_id: nil,
       view_description: false,
       visitor_choices: choices_taken,
       play_track_id: nil,
       test_taken_times: nil,
       test_data: data,
       tracks_order: tracks_order,
       is_another_session: false
     })}
  end

  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    with %Test{} = test <- Tests.get_by_slug(slug),
         true <-
           Tests.is_closed?(test) or
             Map.get(session, "test_taken_" <> slug, false) or
             ((Map.get(session, "current_user_id") == test.user_id and test.user_id != nil) or
                (Map.get(params, "key") != nil and Map.get(params, "key") == test.access_key)) do
      result_modules = Tests.get_result_modules(test)

      if connected?(socket) do
        FunkyABXWeb.Endpoint.subscribe(test.id)
        Tests.update_last_viewed(test)
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
         page_id: Utils.get_page_id_from_socket(socket),
         test: test,
         result_modules: result_modules,
         current_user_id: Map.get(session, "current_user_id"),
         view_description: false,
         visitor_choices: choices,
         session_id: session_id,
         tracks_order: nil,
         is_another_session: is_another_session,
         test_taken_times: Tests.get_how_many_taken(test),
         play_track_id: nil,
         embed: Map.get(session, "embed", false)
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
         |> redirect(to: ~p"/test/#{slug}")}
    end
  end

  @impl true
  def handle_event("test_not_taken", _params, socket) do
    with false <- socket.assigns.current_user_id == socket.assigns.test.user_id do
      {:noreply,
       socket
       |> redirect(to: ~p"/test/#{socket.assigns.test.slug}")}
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
    {:noreply, assign(socket, :tracks_order, params)}
  end

  # ---------- PLAYER ----------

  @impl true
  def handle_event("playing", %{"track_id" => track_id} = _params, socket) do
    {:noreply, assign(socket, :play_track_id, track_id)}
  end

  @impl true
  def handle_event("stopping", _params, socket) do
    {:noreply, assign(socket, :play_track_id, nil)}
  end

  # ---------- UI ----------

  def handle_event("toggle_description", _value, socket) do
    toggle = !socket.assigns.view_description

    {:noreply, assign(socket, view_description: toggle)}
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
    dgettext("test", "Someone just took this test !")
    |> Utils.send_success_toast(socket.assigns.page_id)

    # todo manage refresh of the data on components
    {:noreply,
     assign(socket, %{
       test_taken_times: socket.assigns.test_taken_times + 1
     })}
  end

  @impl true
  def handle_info(%{event: "test_deleted"} = _payload, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "This test has been deleted :(")
     |> redirect(to: ~p"/info")}
  end

  @impl true
  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
  end
end
