defmodule FunkyABX.Invitations do
  require Logger

  alias Ecto.UUID
  alias FunkyABX.{Repo, Test, Invitation, EmailBlacklist}
  alias FunkyABX.Notifier.Email

  def add(%Test{} = test, name_or_email) when is_binary(name_or_email) do
    with false <- is_already_invited?(test, name_or_email) do
      Logger.info("Invitation added")

      %Invitation{}
      |> Invitation.changeset(%{
        id: UUID.generate(),
        name_or_email: name_or_email,
        test: test
      })
      |> Repo.insert!()
    else
      _ -> :error
    end
  end

  def send(%Invitation{} = invitation, socket_or_conn) do
    Logger.info("Invitation sent")
    Email.test_invitation(invitation, socket_or_conn)
  end

  def invitation_clicked(invitation_id, test) when is_binary(invitation_id) do
    Logger.info("Invitation clicked")
    invitation = get_invitation(invitation_id)

    unless invitation == nil or invitation.test.id != test.id do
      invitation
      |> Invitation.changeset(%{test: test, clicked: true})
      |> Repo.update()
    end
  end

  def invitation_clicked(_invitation_id, _test), do: false

  def test_taken(invitation_id, test) when is_binary(invitation_id) do
    Logger.info("Invitation test taken")
    invitation = get_invitation(invitation_id)

    unless invitation == nil or invitation.test.id != test.id do
      invitation
      |> Invitation.changeset(%{test: test, test_taken: true})
      |> Repo.update()
    end
  end

  def test_taken(_invitation_id, _test), do: false

  def is_email_blacklisted?(email) when is_binary(email) do
    Repo.get(EmailBlacklist, email) != nil
  end

  def is_already_invited?(%Test{} = test, name_or_email) when is_binary(name_or_email) do
    Repo.get_by(Invitation, test_id: test.id, name_or_email: name_or_email) != nil
  end

  def get_invitation(invitation_id) do
    Invitation
    |> Repo.get(invitation_id)
    |> Repo.preload([:test])
  end

  def get_email_blacklist(email) when is_binary(email) do
    Repo.get(EmailBlacklist, email)
  end
end
