defmodule FunkyABX.Tests do
  import Ecto.Query, only: [dynamic: 2, from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test
  alias FunkyABX.Rank
  alias FunkyABX.Ranks
  alias FunkyABX.RankDetails
  alias FunkyABX.Pick
  alias FunkyABX.Picks
  alias FunkyABX.PickDetails
  alias FunkyABX.Identification
  alias FunkyABX.Identifications
  alias FunkyABX.IdentificationDetails

  @min_test_created_minutes 15

  # ---------- GET ----------

  def get(id) when is_binary(id) do
    Repo.get(Test, id)
    |> Repo.preload([:tracks])
  end

  def get_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Test, slug: slug)
    |> Repo.preload([:tracks])
  end

  def get_edit(slug, key) when is_binary(slug) and is_binary(key) do
    Repo.get_by!(Test, slug: slug, password: key)
    |> Repo.preload([:tracks])
  end

  def get_for_gallery() do
    query =
      from t in Test,
      where: t.public == true and is_nil(t.closed_at) and is_nil(t.deleted_at) and t.inserted_at < ago(@min_test_created_minutes, "minute"),
      order_by: [desc: t.inserted_at],
      select: t

    Repo.all(query)
  end

  # ---------- VOTES ----------

  def has_tests_taken?(test_id) do
    query =
      from t in Test,
        left_join: r in Rank,
        on: t.id == r.test_id,
        left_join: p in Pick,
        on: t.id == p.test_id,
        left_join: i in Identification,
        on: t.id == i.test_id,
        where: t.id == ^test_id,
        group_by: [t.id],
        select: %{
          id: t.id,
          has_ranks:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              r.rank
            ),
          has_picking:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              p.picked
            ),
          has_identifications:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              i.count
            )
        }

    Repo.one(query)
    |> case do
      %{has_identifications: true} = _data -> true
      %{has_ranks: true} = _data -> true
      _ -> false
    end
  end

  def get_how_many_taken(test) do
    ranks = Ranks.get_ranks(test)
    picking = Picks.get_picks(test)
    identifications = Identifications.get_identification(test)
    get_how_many_taken(ranks, picking, identifications)
  end

  def get_how_many_taken(rankings, picking, identifications) do
    [get_how_many_rankings_taken(rankings), get_how_many_pickings_taken(picking), get_how_many_identifications_taken(identifications)]
    |> Enum.max()
  end

  def get_how_many_rankings_taken(rankings) when is_nil(rankings) or length(rankings) == 0, do: 0

  def get_how_many_rankings_taken(rankings) do
    rankings
    |> List.first(%{})
    |> Map.get(:count, 0)
  end

  def get_how_many_pickings_taken(pickings) when is_nil(pickings) or length(pickings) == 0, do: 0

  def get_how_many_pickings_taken(pickings) do
    0
  end

  def get_how_many_identifications_taken(identifications) when is_nil(identifications) or length(identifications) == 0, do: 0

  def get_how_many_identifications_taken(identifications) do
    identifications
    |> List.first(%{})
    |> Map.get(:guesses, [])
    |> Enum.reduce(0, fn i, acc ->
      acc + i["count"]
    end)
  end

  def submit_ranking(test, ranking, ip_address) do
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
      ip_address: get_ip_as_binary(ip_address)
    })
    |> Repo.insert()
  end

  def submit_picking(test, track_id, ip_address) do
    track = Enum.find(test.tracks, fn t -> t.id == track_id end)

    # we insert a new entry or increase the count if this combination of test + track + rank exists
    on_conflict = [set: [picked: dynamic([r], fragment("? + ?", r.picked, 1))]]

    {:ok, _updated} =
      Repo.insert(%Pick{test: test, track: track, picked: 1},
        on_conflict: on_conflict,
        #          conflict_target: {:unsafe_fragment, "ON CONSTRAINT rank_pkey"}
        conflict_target: [:test_id, :track_id]
      )

    %PickDetails{test: test, track: track}
    |> PickDetails.changeset(%{
      ip_address: get_ip_as_binary(ip_address)
    })
    |> Repo.insert()
  end

  def submit_identification(test, identification, ip_address) do
    Enum.each(identification, fn {track_id, track_id_guess} ->
      track = find_track(test.tracks, track_id)
      track_guessed = find_track(test.tracks, track_id_guess)

      # we insert a new entry or increase the count if this combination of test + track + rank exists
      on_conflict = [set: [count: dynamic([i], fragment("? + ?", i.count, 1))]]

      {:ok, _updated} =
        Repo.insert(
          %Identification{test: test, track: track, track_guessed: track_guessed, count: 1},
          on_conflict: on_conflict,
          #          conflict_target: {:unsafe_fragment, "ON CONSTRAINT rank_pkey"}
          conflict_target: [:test_id, :track_id, :track_guessed_id]
        )
    end)

    %IdentificationDetails{test: test}
    |> IdentificationDetails.changeset(%{
      votes: identification,
      ip_address: get_ip_as_binary(ip_address)
    })
    |> Repo.insert()
  end

  # ---------- UTILS ----------

  defp find_track(tracks, track_id) do
    Enum.find(tracks, fn t ->
      t.id == track_id
    end)
  end

  defp get_ip_as_binary(nil), do: nil

  defp get_ip_as_binary(remote_ip) do
    remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
