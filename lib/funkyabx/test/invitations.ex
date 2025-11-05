defmodule FunkyABX.Invitations do
  require Logger

  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.{Test, Invitation}
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

  def clicked(invitation_id, %Test{} = test) when is_binary(invitation_id) do
    with %Invitation{} = invitation <- get_invitation(invitation_id),
         true <- invitation.test.id == test.id do
      Logger.info("Invitation clicked")

      invitation
      |> Invitation.changeset_clicked(%{clicked: true})
      |> Repo.update()
    else
      _ -> false
    end
  end

  def clicked(_invitation_id, _test), do: false

  def test_taken(invitation_id, test) when is_binary(invitation_id) do
    with %Invitation{} = invitation <- get_invitation(invitation_id),
         true <- invitation.test.id == test.id do
      Logger.info("Invitation test taken")

      invitation
      |> Invitation.changeset_test_taken(%{test_taken: true})
      |> Repo.update()
    else
      _ -> false
    end
  end

  def test_taken(_invitation_id, _test), do: false

  def is_already_invited?(%Test{} = test, name_or_email) when is_binary(name_or_email) do
    Repo.get_by(Invitation, test_id: test.id, name_or_email: name_or_email) != nil
  end

  def get_invitation(invitation_id) when invitation_id == nil, do: nil

  def get_invitation(invitation_id) when is_binary(invitation_id) do
    # Decode if short id
    invitation_id =
      unless String.contains?(invitation_id, "-") == true do
        ShortUUID.decode!(invitation_id)
      else
        invitation_id
      end

    Invitation
    |> Repo.get(invitation_id)
    |> Repo.preload([:test])
  end
end
