defmodule BsModalComponent do
  use FunkyABXWeb, :live_component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :title, :string, required: true

  def render(assigns) do
    ~H"""
    <div id={@id} class="modal fade" tabindex="-1" phx-hook="BsModal" data-id={@id}>
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title"><%= @title %></h5>
            <button
              type="button"
              class="btn-close"
              phx-click={JS.dispatch("close_modal", to: "body")}
              aria-label={dgettext("site", "Close")}
            >
            </button>
          </div>
          <div class="modal-body">
            <%= render_slot(@inner_block) %>
          </div>
          <div class="modal-footer">
            <button
              type="button"
              class="btn btn-primary"
              phx-click={JS.dispatch("close_modal", to: "body")}
            >
              <%= dgettext("site", "Close") %>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
