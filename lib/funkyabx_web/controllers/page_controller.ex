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
    active = :regular

    render(conn, :gallery, tests: tests, active: active)
  end

  def contact(conn, _params) do
    changeset = Contact.changeset(%Contact{})

    render(conn, :contact, changeset: changeset)
  end

  def contact_submit(conn, %{"contact" => form_params} = params) do
    changeset = Contact.changeset(%Contact{}, form_params)
    recaptcha_token = Map.get(params, "g-recaptcha-response")

    conn =
      if changeset.valid? == true and parse_recaptcha_token(recaptcha_token) == true do
        try do
          {:ok, data} = Ecto.Changeset.apply_action(changeset, :insert)

          case FunkyABX.Notifier.Email.contact(data) do
            {:ok, _} ->
              conn
              |> put_flash(:success, "Your message has been sent.")

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

  @headers [
    {"Content-type", "application/x-www-form-urlencoded"},
    {"Accept", "application/json"}
  ]

  @verify_url "https://www.google.com/recaptcha/api/siteverify"

  # todo move repatcha code elsewhere

  defp parse_recaptcha_token(nil), do: false
  defp parse_recaptcha_token(token) do
    body =
      %{secret: Application.fetch_env!(:funkyabx, :recaptcha_private), response: token}
      |> URI.encode_query()

    case HTTPoison.post(@verify_url, body, @headers) |> IO.inspect() do
      {:ok, response} ->
        body = response.body |> Jason.decode!()
        if body["success"] do
          true
        else
          false
        end
      _ ->
        false
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
end
