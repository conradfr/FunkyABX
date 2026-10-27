defmodule TestDescriptionComponent do
  use Phoenix.Component
  import Phoenix.HTML
  use PhoenixHTMLHelpers

  attr :wrapper_class, :string, required: false, default: ""
  attr :description_markdown, :boolean, required: false, default: false
  attr :description, :string, required: true

  def format(assigns) do
    ~H"""
    <div :if={@description != nil} class={@wrapper_class}>
      <%= if @description_markdown == true do %>
        {raw(markdown_to_html(@description))}
      <% else %>
        {@description
        |> html_escape()
        |> safe_to_string()
        |> AutoLinker.link(rel: false, scheme: true)
        |> text_to_html(escape: false)}
      <% end %>
    </div>
    """
  end

  # Raw HTML is allowed in descriptions, but sanitized (scripts, event handlers... are removed)
  def markdown_to_html(markdown) when is_binary(markdown) do
    MDEx.to_html!(markdown,
      extension: [strikethrough: true, autolink: true, table: true],
      render: [unsafe: true],
      sanitize: MDEx.Document.default_sanitize_options()
    )
  end
end
