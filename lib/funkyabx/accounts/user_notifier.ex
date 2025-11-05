defmodule FunkyABX.Accounts.UserNotifier do
  alias FunkyABX.Notifier.Email

  #  @doc """
  #  Deliver instructions to update a user email.
  #  """
  #  def deliver_update_email_instructions(user, url) do
  #    Email.deliver(user.email, "Update email instructions", """
  #      Hi #{user.email},
  #
  #      You can change your email by visiting the URL below:
  #
  #      #{url}
  #
  #      If you didn't request this change, please ignore this.
  #
  #      Regards,
  #      FunkyABX
  #    """)
  #  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    Email.deliver(user.email, "Log in instructions", """
      Hi #{user.email},

      Your account on FunkyABX has been registered.

      You can log using your email and password, or use the kink below:
      #{url}

      Regards,
      FunkyABX
    """)
  end

  def deliver_magic_link_instructions(user, url) do
    Email.deliver(user.email, "Log in instructions", """
      Hi #{user.email},

      You can log into your account by visiting the URL below:

      #{url}

      If you didn't request this email, please ignore this.

      Regards,
      FunkyABX
    """)
  end

  #  defp deliver_confirmation_instructions(user, url) do
  #    Email.deliver(user.email, "Confirmation instructions", """
  #      Hi #{user.email},
  #
  #      You can confirm your account by visiting the URL below:
  #
  #      #{url}
  #
  #      If you didn't create an account with us, please ignore this.
  #
  #      Regards,
  #      FunkyABX
  #    """)
  #  end

  @doc """
  Deliver account deleted email
  """
  def deliver_account_deleted(email) do
    Email.deliver(email, "FunkyABX - Account deleted", """
      Hi #{email},

      As requested, your account has been successfully deleted.

      Regards,
      FunkyABX
    """)
  end
end
