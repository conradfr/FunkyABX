defmodule FunkyABX.Accounts.UserNotifier do
  import Swoosh.Email
  alias FunkyABX.Mailer

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

  @doc """
  Deliver welcome email
  """
  def deliver_welcome(user) do
    deliver(
      user.email,
      "Welcome on FunkyABX",
      """
        Hello,

        You have registered an account on >FunkyABX.
        If that's not you, you can change the password here http://link and then delete the account.

        Regards,
        FunkyABX
      """,
      """
        <p>Hello,</p>
        <p>You have registered an account on <a href=\"#\">FunkyABX</a>.</p>
        <p>If that's not you, you can change the password here and then delete the account.</p>
        <p>Regards,<br>FunkyABX</p>
      """
    )
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "FunkyABX - Reset password instructions", """
    Hi #{user.email},

    A password reset has been requested for this email on FunkyABX.

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Regards,
    FunkyABX
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "FunkyABX - Update email instructions", """
    Hi #{user.email},

    An email change has been requested for this email on FunkyABX.

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    Regards,
    FunkyABX
    """)
  end

  @doc """
  Deliver account deleted email
  """
  def deliver_account_deleted(email) do
    deliver(email, "FunkyABX - account deleted", """
    Hi #{email},

    As requested, your account has been successfully deleted.

    Regards,
    FunkyABX
    """)
  end
end
