defmodule FunkyABXWeb.GalleryLive do
  use FunkyABXWeb, :live_view
  alias FunkyABX.Cldr
  alias FunkyABX.Repo
  alias FunkyABX.Tests
  alias FunkyABX.Accounts

  @impl true
  def render(assigns) do
    ~H"""
      <h3 class="mb-4 mt-0 header-chemyretro" id="test-form-header">Gallery</h3>
      <div class="d-flex flex-wrap justify-content-center">
        <%= for test <- @tests do %>
          <div class="gallery-test align-self-stretch rounded me-2 mb-2 d-flex flex-column">
            <div class="gallery-test-title p-2 px-3">
              <h6 class="mb-0 header-typographica"><%= test.title %></h6>
            </div>
            <%= unless test.author == nil do %>
              <div class="gallery-test-by p-2 px-3">
                <h7 class="mb-0 header-neon text-truncate">By <%= test.author %></h7>
              </div>
            <% end %>
            <%= unless test.description == nil do %>
              <TestDescriptionComponent.format wrapper_class="flex-fill gallery-test-description p-2 px-3" description_markdown={test.description_markdown} description={test.description} />
            <% end %>
            <div class="mt-auto py-1 text-center gallery-test-link">
              <%= link "View", to: Routes.test_public_path(@socket, FunkyABXWeb.TestLive, test.slug) %>
            </div>
          </div>
        <% end %>
      </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    tests = Tests.get_for_gallery()

    {:ok,
     assign(socket, %{
       tests: tests
     })}
  end

  defp format_date(datetime) do
    {:ok, date_string} = Cldr.DateTime.to_string(datetime, format: :short)
    date_string
  end
end
