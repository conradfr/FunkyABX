defmodule FunkyABX.Ranks do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Rank

  def get_ranks(test) do
    query =
      from r in Rank,
        join: t in Track,
        on: t.id == r.track_id,
        where: r.test_id == ^test.id,
        order_by: [
          desc: r.count,
          asc: r.rank,
          asc: fragment("SUM(?) OVER (PARTITION BY ?)", r.rank, r.track_id),
          desc: r.track_id
        ],
        select: %{
          track_id: r.track_id,
          track_title: t.title,
          rank: r.rank,
          count: r.count,
          total_rank: fragment("SUM(?) OVER (PARTITION BY ?) as total_rank", r.rank, r.track_id)
        }

    # Can't make a sql query that avoids duplicate track or rank so we clean the data here instead
    query
    |> Repo.all()
    |> Enum.reduce([], fn r, acc ->
      with true <-
             already_has_rank?(r.rank, acc) or
               already_has_track?(r.track_id, acc) do
        acc
      else
        _ -> [r | acc]
      end
    end)
    |> Enum.sort(fn curr, prev -> curr.rank < prev.rank end)
  end

  defp already_has_rank?(rank, acc) do
    acc
    |> Enum.any?(fn r -> r.rank == rank end)
  end

  defp already_has_track?(track_id, acc) do
    acc
    |> Enum.any?(fn t -> t.track_id == track_id end)
  end
end
