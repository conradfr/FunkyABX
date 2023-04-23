defmodule FunkyABXWeb.UserConfirmationHTML do
  use FunkyABXWeb, :html

  alias FunkyABXWeb.Router.Helpers, as: Routes

  embed_templates "user_confirmation_html/*"
end
