defmodule TestDescriptionComponent do
  use Phoenix.Component
  use Phoenix.HTML

  attr :wrapper_class, :string, required: false, default: ""
  attr :description_markdown, :boolean, required: false, default: false
  attr :description, :string, required: true

  def format(assigns) do
    ~H"""
      <div class={@wrapper_class}>
        <%= if @description_markdown == true do %>
          <%= raw(Earmark.as_html!(@description, escape: false, inner_html: true)) %>
        <% else %>
          <%= @description |> html_escape() |> safe_to_string() |> AutoLinker.link(rel: false, scheme: true) |> text_to_html([escape: false]) %>
        <% end %>
      </div>
    """
  end
end
