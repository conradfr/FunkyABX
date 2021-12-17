defmodule FunkyABX.Ranks do
  import Ecto.Query, only: [dynamic: 2, from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Rank
  alias FunkyABX.RankDetails

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

  def get_how_many_taken(rankings) when is_nil(rankings) or length(rankings) == 0, do: 0

  def get_how_many_taken(rankings) do
    rankings
    |> List.first(%{})
    |> Map.get(:count, 0)
  end

  def is_valid?(ranking, test) do
    case test.ranking do
      true ->
        case ranking
             |> Map.values()
             |> Enum.uniq()
             |> Enum.count() do
          count when count < Kernel.length(test.tracks) -> false
          _ -> true
        end

      _ ->
        true
    end
  end

  def submit(test, _ranking, _ip_address) when test.ranking != true, do: %{}

  def submit(test, ranking, ip_address) do
    Enum.each(ranking, fn {track_id, rank} ->
      track = Enum.find(test.tracks, fn t -> t.id == track_id end)

      # we insert a new entry or increase the count if this combination of test + track + rank exists
      on_conflict = [set: [count: dynamic([r], fragment("? + ?", r.count, 1))]]

      {:ok, _updated} =
        Repo.insert(%Rank{test: test, track: track, rank: rank, count: 1},
          on_conflict: on_conflict,
          #          conflict_target: {:unsafe_fragment, "ON CONSTRAINT rank_pkey"}
          conflict_target: [:test_id, :track_id, :rank]
        )
    end)

    %RankDetails{test: test}
    |> RankDetails.changeset(%{
      votes: ranking,
      ip_address: ip_address
    })
    |> Repo.insert()

    ranking
  end
end
