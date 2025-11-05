defmodule FunkyABXWeb.GalleryLive do
  use FunkyABXWeb, :live_view

  alias FunkyABX.Tests
  alias FunkyABX.Test

  @impl true
  def render(assigns) do
    ~H"""
    <h2 class="mb-4 mt-0 header-chemyretro" id="test-form-header">
      {dgettext("test", "Gallery")}
    </h2>

    <ul class="nav nav-tabs mb-3" id="galleryTab" role="tablist">
      <li class="nav-item" role="presentation">
        <button
          class={["nav-link", @active == "regular" && "active"]}
          aria-selected={if @active == "regular", do: "true", else: "false"}
          id="regular-tab"
          type="button"
          role="tab"
          aria-controls="regular-tab-pane"
          phx-click="switch"
          phx-value-type="regular"
        >
          {dgettext("site", "Audio tests")}
        </button>
      </li>
      <li class="nav-item" role="presentation">
        <button
          class={["nav-link", @active == "abx" && "active"]}
          aria-selected={if @active == "abx", do: "true", else: "false"}
          id="abx-tab"
          data-bs-toggle="tab"
          data-bs-target="#abx-tab-pane"
          type="button"
          role="tab"
          aria-controls="abx-tab-pane"
          phx-click="switch"
          phx-value-type="abx"
        >
          {dgettext("site", "ABX tests")}
        </button>
      </li>
      <li class="nav-item" role="presentation">
        <button
          class={["nav-link", @active == "listening" && "active"]}
          aria-selected={if @active == "listening", do: "true", else: "false"}
          id="listening-tab"
          type="button"
          role="tab"
          aria-controls="listening-tab-pane"
          phx-click="switch"
          phx-value-type="listening"
        >
          {dgettext("site", "Listening")}
        </button>
      </li>
    </ul>

    <div>
      <div class="tab-content" id="galleryTabContent">
        <div
          class="tab-pane fade show active"
          role="tabpanel"
          tabindex="0"
        >
          <div class="d-flex flex-wrap justify-content-center">
            <%= for test <- @tests do %>
              <div class="gallery-test align-self-stretch rounded me-2 mb-2 d-flex flex-column">
                <div class="gallery-test-title text-center p-2 px-3">
                  <.link
                    href={~p"/test/#{test.slug}"}
                    class="header-funky-simple"
                  >
                    {test.title}
                  </.link>
                </div>
                <%= unless test.author == nil do %>
                  <div class="gallery-test-by p-2 px-3 text-center">
                    <h7 class="mb-0 header-neon text-truncate">
                      {dgettext("test", "By %{author}", author: test.author)}
                    </h7>
                  </div>
                <% end %>
                <%= unless test.description == nil do %>
                  <TestDescriptionComponent.format
                    wrapper_class="flex-fill gallery-test-description p-2 px-3"
                    description_markdown={test.description_markdown}
                    description={test.description}
                  />
                <% else %>
                  <div class="test-tracklist mt-2 mb-4 p-3 py-2">
                    <p><strong>{dgettext("site", "Tracks:")}</strong></p>
                    <%= for {track, i} <- test.tracks |> Enum.with_index(1) do %>
                      <div class="test-tracklist-one">{i}.&nbsp;&nbsp;{track.title}</div>
                    <% end %>
                  </div>
                <% end %>
                <div :if={is_test_closed?(test)} class="mt-auto">
                  <div class="py-1 text-center gallery-test-closed">
                    {dgettext("test", "Test is closed")}
                  </div>
                </div>
                <div class="mt-auto">
                  <div :if={test.type != :listening} class="py-1 text-center gallery-test-taken">
                    {dngettext(
                      "test",
                      "Test taken %{count} time",
                      "Test taken %{count} times",
                      test.taken
                    )}
                  </div>
                  <div class="py-1 text-center gallery-test-link">
                    <.link href={~p"/test/#{test.slug}"}>
                      {dgettext("site", "View test")}
                    </.link>
                  </div>
                </div>
              </div>
            <% end %>
            <%= if length(@tests) == 0 do %>
              <div>{dgettext("test", "No public tests yet :(")}</div>
            <% end %>
          </div>
          <div>&nbsp;</div>
        </div>
      </div>
    </div>

    <nav class="m-auto my-3" aria-label={dgettext("site", "Tests pagination")}>
      <ul class="pagination justify-content-center">
        <li class={["page-item", @page == 1 && "disabled"]}>
          <a
            class="page-link"
            href="#"
            aria-label={dgettext("site", "Previous")}
            phx-click="page"
            phx-value-page={@page - 1}
          >
            <span aria-hidden="true">&laquo; {dgettext("site", "Previous")}</span>
          </a>
        </li>
        <li class={["page-item", @page >= @pages && "disabled"]}>
          <a
            class="page-link"
            href="#"
            aria-label={dgettext("site", "Next")}
            phx-click="page"
            phx-value-page={@page + 1}
          >
            <span aria-hidden="true">{dgettext("site", "Next")} &raquo;</span>
          </a>
        </li>
      </ul>
    </nav>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    tests = Tests.get_for_gallery()
    pages = Tests.pages_for_gallery()
    active = "regular"
    page = 1

    {:ok,
     assign(
       socket,
       %{
         page_title: dgettext("site", "Gallery"),
         tests: tests,
         pages: pages,
         page: page,
         active: active
       }
     )}
  end

  @impl true
  def handle_event("switch", %{"type" => type}, socket) do
    active = type
    page = 1

    pages =
      type
      |> String.to_atom()
      |> Tests.pages_for_gallery()

    tests =
      type
      |> String.to_atom()
      |> Tests.get_for_gallery(page)

    {:noreply,
     socket
     |> assign(tests: tests, active: active, pages: pages, page: page)}
  end

  @impl true
  def handle_event("page", %{"page" => page}, %{assigns: %{active: type}} = socket) do
    page = String.to_integer(page)

    pages =
      type
      |> String.to_atom()
      |> Tests.pages_for_gallery()

    tests =
      type
      |> String.to_atom()
      |> Tests.get_for_gallery(page)

    {:noreply,
     socket
     |> assign(tests: tests, pages: pages, page: page)}
  end

  defp is_test_closed?(%Test{} = test) do
    Tests.is_closed?(test)
  end
end
