defmodule TestResultTrackHeaderComponent do
  use Phoenix.Component
  use Phoenix.HTML

  def display(assigns) do
    ~H"""
      <div class="p-2">
        <button type="button" class="btn btn-dark px-2">
          <%= if @playing do %>
            <i class="bi bi-stop-fill"></i>
          <% else %>
            <i class="bi bi-play-fill"></i>
          <% end %>
        </button>
      </div>
      <div class="p-2">
        <%= if (@rank < 4) do %>
          <i class={"bi bi-trophy-fill trophy-#{@rank}"}></i>
        <% else %>
          #<%= @rank %>
        <% end %>
      </div>
      <div class="p-2 flex-grow-1 text-truncate cursor-link"><%= @title %></div>
    """
  end
end
