defmodule FunkyABXWeb.FlashLive do
  use FunkyABXWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h4 class="header-chemyretro">{dgettext("test", "What do you want to do now ?")}</h4>
      <p><a href={~p"/test"}>{dgettext("test", "Create a new test")}</a></p>
      <p><a href={~p"/gallery"}>{dgettext("test", "Visit the gallery")}</a></p>
    </div>
    """
  end

  @impl true
  def mount(_params, %{}, socket) do
    {:ok, socket}
  end
end
