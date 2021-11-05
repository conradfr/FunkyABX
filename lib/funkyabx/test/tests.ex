defmodule FunkyABX.Tests do
  import Ecto.Query, only: [dynamic: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test
  alias FunkyABX.Rank
  alias FunkyABX.Identification
  alias FunkyABX.RankDetails
  alias FunkyABX.IdentificationDetails

  # ---------- GET ----------

  def get(slug) when is_binary(slug) do
    Repo.get_by(Test, slug: slug)
    |> Repo.preload([:tracks])
  end

  def get_edit(slug, key) when is_binary(slug) and is_binary(key) do
    Repo.get_by!(Test, slug: slug, password: key)
    |> Repo.preload([:tracks])
  end

  # ---------- VOTES ----------

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

    RankDetails.changeset(%RankDetails{}, %{
      votes: ranking,
      ip_address: get_ip_as_binary(ip_address),
      test: test
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

    IdentificationDetails.changeset(%IdentificationDetails{}, %{
      votes: identification,
      ip_address: get_ip_as_binary(ip_address),
      test: test
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
