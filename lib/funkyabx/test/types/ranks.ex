defmodule FunkyABX.Ranks do
  import Ecto.Query, only: [dynamic: 2, from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.Tests.Image
  alias FunkyABX.Tests
  alias FunkyABX.{Test, Track, Rank, RankDetails}

  # ---------- GET ----------

  def get_ranks(%Test{} = test, visitor_choices) when test.local == true do
    test
    |> Map.get(:tracks, [])
    |> Tests.filter_reference_track()
    |> Enum.map(fn t ->
      %{
        track_id: t.id,
        track_title: t.title,
        rank: Map.get(visitor_choices["rank"], t.id, 0),
        count: (Map.get(visitor_choices["rank"], t.id, 0) != 0 && 1) || 0,
        total_rank: Map.get(visitor_choices["rank"], t.id, 0)
      }
    end)
    |> Enum.reject(&(&1.rank == 0))
    |> Enum.sort(fn curr, prev -> curr.rank < prev.rank end)
  end

  # todo: maybe revisit the query since adding the details
  def get_ranks(%Test{} = test, _visitor_choices) do
    query =
      from r in Rank,
        join: t in Track,
        on: t.id == r.track_id,
        where: r.test_id == ^test.id and t.reference_track != true,
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
        add_to_rank_details(r, acc)
      else
        _ -> [r | acc]
      end
    end)
    |> Enum.sort(fn curr, prev -> curr.rank < prev.rank end)
  end

  defp already_has_rank?(rank, acc), do: Enum.any?(acc, fn r -> r.rank == rank end)

  defp already_has_track?(track_id, acc), do: Enum.any?(acc, fn r -> r.track_id == track_id end)

  defp add_to_rank_details(rank, acc) do
    Enum.reduce(acc, [], fn
      r, acc when r.track_id != rank.track_id ->
        [r | acc]

      r, acc ->
        other_ranks =
          [rank | Map.get(r, :other_ranks, [])]
          |> Enum.sort(fn curr, prev -> curr.count < prev.count end)

        rank_updated = Map.put(r, :other_ranks, other_ranks)

        [rank_updated | acc]
    end)
  end

  def get_how_many_taken(%Test{} = test) do
    query =
      from rd in RankDetails,
        where: rd.test_id == ^test.id,
        select: fragment("COUNT(*)")

    query
    |> Repo.one()
  end

  # ---------- FORM ----------

  def is_valid?(%Test{} = test, round, choices) when is_map_key(choices, round) do
    choices
    |> Map.get(round, %{})
    |> Map.get(:rank, %{})
    |> Map.values()
    |> Enum.uniq()
    |> Enum.count()
    |> is_valid_count?(test)
  end

  def is_valid?(_test, _round, _choices), do: false

  defp is_valid_count?(count, %Test{} = test) when test.ranking_only_extremities == true,
    do: count == 6

  defp is_valid_count?(count, %Test{} = test) do
    count == Tests.tracks_count(test)
  end

  # ---------- SAVE ----------

  def clean_choices(choices, _tracks, _test), do: choices

  def submit(%Test{} = test, %{rank: ranks} = _choices, session_id, ip_address) do
    Enum.each(ranks, fn {track_id, rank} ->
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
      votes: ranks,
      session_id: session_id,
      ip_address: ip_address
    })
    |> Repo.insert()
  end

  # ---------- RESULTS ----------

  def get_results(%Test{} = test, session_id) when is_binary(session_id) do
    query =
      from rd in RankDetails,
        where: rd.test_id == ^test.id and rd.session_id == ^session_id,
        select: rd.votes

    result =
      query
      |> Repo.one()

    case result do
      nil -> %{}
      _ -> %{"rank" => result}
    end
  end

  def results_to_img(mogrify_params, %Test{} = test, session_id, choices)
      when is_binary(session_id) do
    with ranks when ranks != nil <- Map.get(choices, "rank", nil) do
      track_count = Tests.tracks_count(test)

      {start, mogrify} = mogrify_params

      {index, mogrify} =
        mogrify
        |> Image.type_title(start, "Ranking")
        |> then(fn mogrify ->
          test
          |> Map.get(:tracks, [])
          |> Tests.filter_reference_track()
          |> Enum.sort_by(fn t ->
            Map.get(ranks, t.id, track_count / 2)
          end)
          |> Enum.reduce({1, mogrify}, fn t, acc ->
            {index, mogrify} = acc

            mogrify =
              Image.type_track(
                mogrify,
                start,
                index,
                "##{Map.get(ranks, t.id, "-")} : #{t.title}"
              )

            {index + 1, mogrify}
          end)
        end)

      {start + 24 + 16 * index, mogrify}
    else
      _ -> mogrify_params
    end
  end
end
