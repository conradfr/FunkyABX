defmodule FunkyABX.Identifications do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Rank
  alias FunkyABX.Identification

  def get_identification(test) do
    query =
      from i in Identification,
        where: i.test_id == ^test.id,
        order_by: [asc: i.track_id, desc: i.count],
        select: %{
          track_id: i.track_id,
          track_guessed_id: i.track_guessed_id,
          count: i.count
        }

    Repo.all(query)
  end
end
