defmodule FunkyABXWeb.BlacklistController do
  use FunkyABXWeb, :controller
  alias FunkyABX.Repo
  alias FunkyABX.{Invitation, EmailBlacklist, Invitations}
  alias FunkyABX.Notifier.Email

  def add(conn, %{"invitation_id" => invitation_id} = _params) do
    with %Invitation{} = invitation <- Invitations.get_invitation(invitation_id),
         false <- Invitations.is_email_blacklisted?(invitation.name_or_email),
         changeset <-
           EmailBlacklist.changeset(%EmailBlacklist{}, %{email: invitation.name_or_email}),
         {:ok, _} <- Repo.insert(changeset) do
      Email.blacklist_confirmation(invitation, conn)
      render(conn, "add.html", status: :ok, invitation_id: invitation_id)
    else
      _ -> render(conn, "add.html", status: :error)
    end
  end

  def remove(conn, %{"invitation_id" => invitation_id} = _params) do
    with %Invitation{} = invitation <- Invitations.get_invitation(invitation_id),
         %EmailBlacklist{} = email_blacklist <-
           Invitations.get_email_blacklist(invitation.name_or_email),
         {:ok, _} <- Repo.delete(email_blacklist) do
      render(conn, "remove.html", status: :ok)
    else
      _ -> render(conn, "remove.html", status: :error)
    end
  end
end
