defmodule FunkyABXWeb.FlashLive do
  use FunkyABXWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <h4 class="header-chemyretro"><%= gettext "What do you want to do now ?" %></h4>
        <p><a href={Routes.test_new_path(@socket, FunkyABXWeb.TestFormLive)}><%= gettext "Create a new test" %></a></p>
      </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket) do
    {:ok, socket}
  end
end
