defmodule FunkyABX.DeleteUserWorker do
  import Ecto.Query, warn: false, only: [from: 2]
  use Oban.Worker, queue: :user_delete

  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.Test
  alias FunkyABX.Accounts.User
  alias FunkyABX.Accounts.UserNotifier
  alias FunkyABX.{Accounts, Files}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = _args}) do
    with %User{} = user <- Repo.get(User, id) do
      old_email = user.email
      # Anonymize the account
      case Accounts.delete_account(user, %{"email" => UUID.generate()}) do
        {:ok, user} ->
          UserNotifier.deliver_account_deleted(old_email)
          # Delete audio tracks
          user = Repo.preload(user, :tests)

          user.tests
          |> Enum.filter(fn t ->
            t.closed_at == nil and t.to_closed_at != nil and t.to_close_at_enabled == true
          end)
          |> Enum.each(fn t ->
            remove_test_from_closing_queue(t)
          end)

          user.tests
          |> Enum.filter(fn t -> t.deleted_at == nil end)
          |> Enum.each(fn t ->
            Files.delete_all(t.id)
          end)

          :ok

        {:error, _changeset} ->
          :error
      end
    else
      _ -> :error
    end
  end

  def remove_test_from_closing_queue(%Test{} = test) do
    Oban.Job
    |> Ecto.Query.where(worker: "FunkyABX.TestClosingWorker")
    |> Ecto.Query.where(fragment("? = ANY (tags)", ^test.id))
    |> Oban.cancel_all_jobs()
  end
end
