defmodule FunkyABXWeb.PageController do
  use FunkyABXWeb, :controller
  alias FunkyABX.Contact
  alias FunkyABX.Tests

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def gallery(conn, _params) do
    tests = Tests.get_for_gallery()
    render(conn, "gallery.html", tests: tests)
  end

  def contact(conn, _params) do
    changeset = Contact.changeset(%Contact{})

    render(conn, "contact.html", changeset: changeset)
  end

  def contact_submit(conn, %{"contact" => form_params} = _params) do
    changeset = Contact.changeset(%Contact{}, form_params)

    conn =
      if changeset.valid? == true do
        try do
          {:ok, data} = Ecto.Changeset.apply_action(changeset, :insert)
          FunkyABX.Notifier.Email.contact(data)

          conn
          |> put_flash(:success, "Your message has been sent.")
        rescue
          _ ->
            conn
            |> put_flash(:error, "An error occurred.")
        end
      else
        conn
      end

    changeset = Contact.changeset(%Contact{})

    render(conn, "contact.html", changeset: changeset)
  end

  def about(conn, _params) do
    render(conn, "about.html")
  end
end
