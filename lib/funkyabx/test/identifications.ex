defmodule FunkyABX.Identifications do
  import Ecto.Query, only: [dynamic: 2, from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Tracks
  alias FunkyABX.Identification
  alias FunkyABX.IdentificationDetails

  # ---------- GET ----------

  def get_identification(test) do
    query =
      from i in Identification,
        inner_join: t in Track,
        on: t.id == i.track_id,
        inner_join: tg in Track,
        on: tg.id == i.track_guessed_id,
        where: i.test_id == ^test.id,
        group_by: [i.track_id, t.title],
        order_by: [desc: fragment("correct_count")],
        select: %{
          track_id: i.track_id,
          title: t.title,
          guesses:
            fragment(
              "JSON_AGG(JSON_BUILD_OBJECT('track_guessed_id', ?, 'title', ?, 'count', ?) ORDER BY (?) DESC)",
              i.track_guessed_id,
              tg.title,
              i.count,
              i.count
            ),
          correct_count:
            fragment(
              "MAX(CASE WHEN ? = ? THEN ? ELSE 0 END) as correct_count",
              i.track_id,
              i.track_guessed_id,
              i.count
            ),
          total_guess: fragment("SUM(?) as total_guess", i.count)
        }

    Repo.all(query)
  end

  def get_how_many_taken(test) do
    query =
      from id in IdentificationDetails,
        where: id.test_id == ^test.id,
        select: fragment("COUNT(*)")

    query
    |> Repo.one()
  end

  # ---------- FORM ----------

  def is_valid?(test, round, choices) when is_map_key(choices, round) do
    case Map.get(choices[round], :identification, %{})
         |> Map.values()
         |> Enum.count() do
      count when count < Kernel.length(test.tracks) -> false
      _ -> true
    end
  end

  def is_valid?(_test, _round, _choices), do: false

  # ---------- SAVE ----------

  def clean_choices(choices, _tracks, test) when test.identification == false, do: choices

  def clean_choices(%{identification: identification} = choices, tracks, _test) do
    identification_cleaned =
      identification
      |> Enum.reduce(%{}, fn {track_fake_id, track_guess_fake_id}, acc ->
        track_id = Tracks.find_track_id_from_fake_id(track_fake_id, tracks)
        track_guess_id = Tracks.find_track_id_from_fake_id(track_guess_fake_id, tracks)

        Map.put(acc, track_id, track_guess_id)
      end)

    Map.put(choices, :identification, identification_cleaned)
  end

  def submit(test, %{identification: identification} = _choices, ip_address) do
    Enum.each(identification, fn {track_id, track_id_guess} ->
      track = Tracks.find_track(track_id, test.tracks)
      track_guessed = Tracks.find_track(track_id_guess, test.tracks)

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
      ip_address: ip_address
    })
    |> Repo.insert()
  end
end
