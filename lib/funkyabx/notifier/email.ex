defmodule FunkyABX.Notifier.Email do
  import Swoosh.Email

  alias FunkyABXWeb.Router.Helpers, as: Routes
  alias FunkyABX.{Repo, Mailer}
  alias FunkyABX.{Test, Contact}

  # todo queue etc

  def test_taken(%Test{} = test, _socket_or_conn) when test.email_notification == false, do: false

  def test_taken(%Test{} = test, socket_or_conn) do
    test = Repo.preload(test, [:user])
    url = Routes.test_results_public_url(socket_or_conn, FunkyABXWeb.TestResultsLive, test.slug)

    deliver(
      test.user.email,
      "Test taken - " <> test.title,
      """
      Hi #{test.user.email},

      Someone completed your test #{test.title}!

      You can check the results here: #{url}

      If you don't want to receive this email you can uncheck the "Notify me by email when a test is taken" option when editing the test.

      Regards,
      FunkyABX
      """
    )
  end

  def contact(%Contact{} = contact) do
    message = """
    Hi,

    Someone sent a message !

    Name: #{contact.name}
    #{unless contact.email == nil, do: "Email:" <> contact.email, else: ""}

    Message:
    #{contact.message}

    Regards,
    FunkyABX
    """

    deliver(
      Application.fetch_env!(:funkyabx, :email_to),
      "FunkyABX - Contact form",
      message
    )
  end

  defp get_from() do
    {"FunkyABX", Application.fetch_env!(:funkyabx, :email_from)}
  end

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body, body_html \\ nil) do
    email =
      new()
      |> to(recipient)
      |> from(get_from())
      |> subject(subject)
      |> text_body(body)

    email =
      case body_html do
        nil -> email
        _ -> email |> html_body(body_html)
      end

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
