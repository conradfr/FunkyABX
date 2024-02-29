defmodule FunkyABX.Notifier.Email do
  import Swoosh.Email

  alias FunkyABXWeb.Router.Helpers, as: Routes
  alias FunkyABX.{Repo, Mailer}
  alias FunkyABX.{Test, Contact, Invitation, Invitations}

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

  def test_invitation(%Invitation{} = invitation, socket_or_conn) do
    with false <- Invitations.is_email_blacklisted?(invitation.name_or_email) do
      test = Repo.preload(invitation.test, [:user])

      test_url =
        Routes.test_public_url(socket_or_conn, FunkyABXWeb.TestLive, invitation.test.slug,
          i: ShortUUID.encode!(invitation.id)
        )

      blacklist_url = Routes.blacklist_url(socket_or_conn, :add, invitation.id)

      deliver(
        invitation.name_or_email,
        "Blind test invitation : " <> test.title,
        """
        Hi #{invitation.name_or_email},

        You have been invited by #{test.user.email} to take the blind audio test: #{test.title}

        Click here to take the test: #{test_url}

        Regards,
        FunkyABX

        If you don't want to receive email invitations from us, you can add your email to the blacklist here : #{blacklist_url}
        """
      )
    end
  end

  def blacklist_confirmation(%Invitation{} = invitation, socket_or_conn) do
    blacklist_url = Routes.blacklist_url(socket_or_conn, :remove, invitation.id)

    deliver(
      invitation.name_or_email,
      "FunkyABX - Email blacklisted",
      """
      Hi #{invitation.name_or_email},

      Your email has been successfully added to the blacklist.

      If you want to revert your decision later, use this link: #{blacklist_url}

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
    #{unless contact.email == nil, do: "Email: " <> contact.email, else: ""}

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
        _ ->
          email
          |> html_body(body_html)
      end

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    else
      _ -> {:error, nil}
    end
  end
end
