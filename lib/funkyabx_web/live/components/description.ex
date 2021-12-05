defmodule TestDescriptionComponent do
  use Phoenix.Component
  use Phoenix.HTML

  def format(assigns) do
    assigns = assign_new(assigns, :wrapper_class, fn -> "" end)

    ~H"""
      <div class={@wrapper_class}>
        <%= if @description_markdown == true do %>
          <%= raw(Earmark.as_html!(@description, escape: true, inner_html: true)) %>
        <% else %>
          <%= @description |> html_escape() |> safe_to_string() |> AutoLinker.link(rel: false, scheme: true) |> text_to_html([escape: false]) %>
        <% end %>
      </div>
    """
  end
end
