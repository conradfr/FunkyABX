defmodule FunkyABX.TestClosingWorker do
  import Ecto.Query, warn: false, only: [from: 2]
  use Oban.Worker, queue: :closing

  alias __MODULE__
  alias FunkyABX.Repo
  alias FunkyABX.Test

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = _args}) do
    with %Test{} = test <- Repo.get(Test, id),
         nil <- test.closed_at do
      test
      |> Test.changeset_close()
      |> Repo.update()

      FunkyABXWeb.Endpoint.broadcast!(test.id, "test_closed", nil)

      :ok
    else
      _ ->
        :ok
    end
  end

  # can't close a listening test
  def insert_test_to_closing_queue(%Test{} = test) when test.type == :listening do
    # nothing
  end

  def insert_test_to_closing_queue(%Test{} = test) do
    remove_test_from_closing_queue(test)
    scheduled_at = DateTime.from_naive!(test.to_close_at, test.to_close_at_timezone)

    %{id: test.id}
    |> TestClosingWorker.new(scheduled_at: scheduled_at, tags: [test.id])
    |> Oban.insert()
  end

  def remove_test_from_closing_queue(%Test{} = test) do
    Oban.Job
    |> Ecto.Query.where(worker: "FunkyABX.TestClosingWorker")
    |> Ecto.Query.where(fragment("? = ANY (tags)", ^test.id))
    |> Oban.cancel_all_jobs()
  end
end
