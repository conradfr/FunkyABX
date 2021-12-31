defmodule FunkyABXWeb.TestResultsLive do
  use FunkyABXWeb, :live_view
  alias FunkyABX.Tests

  @title_max_length 100

  @impl true
  def render(assigns) do
    ~H"""
      <div class="row">
        <div class="col-sm-6">
          <h3 class="mb-0 header-typographica" id="test-results-header" phx-hook="TestResults" data-testid={@test.id}>
          <%= @test.title %></h3>
          <%= if @test.author != nil do %>
            <h6 class="header-typographica">By <%= @test.author %></h6>
          <% end %>
        </div>
        <div class="col-sm-6 text-start text-sm-end pt-1 pt-sm-3">
          <span class="fs-7 text-muted header-texgyreadventor">Test taken <strong><%= @test_taken_times %></strong> times</span>
        </div>
      </div>

      <%= if @test.description != nil do %>
        <%= if @view_description == false do %>
          <div class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_description">View description&nbsp;&nbsp;<i class="bi bi-arrow-right-circle"></i></div>
        <% else %>
          <div class="fs-8 mt-2 cursor-link text-muted" phx-click="toggle_description">Hide description&nbsp;&nbsp;<i class="bi bi-arrow-down-circle"></i></div>
          <TestDescriptionComponent.format wrapper_class="my-2 p-3 test-description" description_markdown={@test.description_markdown} description={@test.description} />
        <% end %>
      <% end %>

      <%= for module <- @result_modules do %>
        <.live_component module={module} id={Atom.to_string(module)} test={@test} visitor_choices={@visitor_choices} play_track_id={@play_track_id} test_taken_times={@test_taken_times} />
      <% end %>

    """
  end

  # Password given by query string / url
  @impl true
  def mount(%{"slug" => slug, "key" => key} = params, %{}, socket) do
    test = Tests.get_by_slug(slug)
    # will throw an error if password is incorrect
    true = test.password == key

    params
    |> Map.delete("key")
    |> mount(%{}, socket)
  end

  @impl true
  def mount(%{"slug" => slug} = _params, session, socket) do
    with test when not is_nil(test) <- Tests.get_by_slug(slug),
         true <-
           Map.get(session, "test_taken_" <> slug, false) or
             (Map.get(session, "current_user_id") == test.user_id and test.user_id != nil) do
      result_modules = Tests.get_result_modules(test)

      FunkyABXWeb.Endpoint.subscribe(test.id)

      {:ok,
       assign(socket, %{
         page_title: "Test results - " <> String.slice(test.title, 0..@title_max_length),
         test: test,
         result_modules: result_modules,
         current_user_id: Map.get(session, "current_user_id"),
         view_description: false,
         visitor_choices: %{},
         play_track_id: nil,
         test_taken_times: Tests.get_how_many_taken(test)
       })}
    else
      _ ->
        {:ok,
         socket
         |> put_flash(:info, "Please take the test before checking the results.")
         |> assign(test_already_taken: false)
         |> redirect(to: Routes.test_public_path(socket, FunkyABXWeb.TestLive, slug))}
    end
  end

  @impl true
  def handle_event("test_not_taken", _params, socket) do
    with false <- socket.assigns.current_user_id == socket.assigns.test.user_id do
      {:noreply,
       socket
       |> redirect(
         to:
           Routes.test_public_path(
             socket,
             FunkyABXWeb.TestLive,
             socket.assigns.test.slug
           )
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  # ---------- EVENTS ----------

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
     |> redirect(
       to:
         Routes.info_path(
           socket,
           FunkyABXWeb.FlashLive
         )
     )}
  end

  @impl true
  def handle_info(%{event: _event} = _payload, socket) do
    {:noreply, socket}
  end
end
