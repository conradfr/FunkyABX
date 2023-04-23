defmodule FunkyABXWeb.PageController do
  use FunkyABXWeb, :controller

  alias FunkyABX.Contact
  alias FunkyABX.Tests

  def index(conn, _params) do
    tests_gallery = Tests.get_random()

    render(conn, :index, tests_gallery: tests_gallery)
  end

  def gallery(conn, _params) do
    tests = Tests.get_for_gallery()

    render(conn, :gallery, tests: tests)
  end

  def contact(conn, _params) do
    changeset = Contact.changeset(%Contact{})

    render(conn, :contact, changeset: changeset)
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

    render(conn, :contact, changeset: changeset)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def faq(conn, _params) do
    render(conn, :faq)
  end

  def donate(conn, _params) do
    render(conn, :donate)
  end
end
