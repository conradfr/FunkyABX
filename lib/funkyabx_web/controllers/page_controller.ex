defmodule FunkyABXWeb.PageController do
  use FunkyABXWeb, :controller

  alias FunkyABX.Contact
  alias FunkyABX.Tests
  alias FunkyABX.Utils

  @locale_cookie "locale"
  @locale_cookie_max_age 365 * 24 * 60 * 60

  def home(conn, _params) do
    tests_gallery = Tests.get_homepage()

    render(conn, :index, tests_gallery: tests_gallery)
  end

  def set_locale(conn, %{"locale" => locale} = params) do
    if locale in Cldr.known_gettext_locale_names(FunkyABX.Cldr) do
      return_to =
        case Map.get(params, "return_to") do
          "/" <> _ = path -> path
          _ -> "/"
        end

      conn
      |> put_resp_cookie(@locale_cookie, locale,
        max_age: @locale_cookie_max_age,
        same_site: "Lax"
      )
      |> redirect(to: return_to)
    else
      redirect(conn, to: "/")
    end
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

  def contact(conn, _params) do
    changeset = Contact.changeset(%Contact{})

    render(conn, :contact, changeset: changeset)
  end

  def contact_submit(conn, %{"contact" => form_params} = params) do
    changeset = Contact.changeset(%Contact{}, form_params)
    recaptcha_token = Map.get(params, "g-recaptcha-response")

    conn =
      if changeset.valid? == true and Utils.parse_recaptcha_token(recaptcha_token) == true do
        try do
          {:ok, data} = Ecto.Changeset.apply_action(changeset, :insert)

          case FunkyABX.Notifier.Email.contact(data) do
            {:ok, _} ->
              conn
              |> put_flash(:success, dgettext("site", "Your message has been sent."))

            {:error, _} ->
              conn
              |> put_flash(:error, "Sorry, an error has occurred. Please try again.")
          end
        rescue
          _ ->
            conn
            |> put_flash(:error, "Sorry, an error has occurred. Please try again.")
        end
      else
        conn
        |> put_flash(:error, "Sorry, an error has occurred. Please try again.")
      end

    changeset = Contact.changeset(%Contact{})

    render(conn, :contact, changeset: changeset)
  end
end
