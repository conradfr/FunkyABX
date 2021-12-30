defmodule FunkyABX.Stars do
  import Ecto.Query, only: [dynamic: 2, from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Star
  alias FunkyABX.StarDetails

  # ---------- GET ----------

  def get_stars(test) do
    query =
      from t in Track,
        join: s in Star,
        on: t.id == s.track_id,
        where: s.test_id == ^test.id,
        order_by: [
          desc: s.star,
          desc: s.count,
          asc: t.title,
          desc: s.track_id
        ],
        select: %{
          track_id: s.track_id,
          track_title: t.title,
          star: s.star,
          count: s.count
        }

    # Can't make a sql query that avoids duplicate track or star so we clean the data here instead
    query
    |> Repo.all()
    |> Enum.reduce([], fn s, acc ->
      #             already_has_rank?(r.rank, acc) or
      with true <-
             already_has_track?(s.track_id, acc) do
        acc
      else
        _ -> [s | acc]
      end
    end)
    |> Enum.sort(fn curr, prev -> curr.star < prev.star end)
  end

  defp already_has_track?(track_id, acc) do
    acc
    |> Enum.any?(fn t -> t.track_id == track_id end)
  end

  def get_how_many_taken(starring) when is_nil(starring) or length(starring) == 0, do: 0

  def get_how_many_taken(starring) do
    starring
    |> List.first(%{})
    |> Map.get(:count, 0)
  end

  # ---------- FORM ----------

  def is_valid?(test, choices) when is_map_key(choices, :star) do
    map_size(choices.star) == Kernel.length(test.tracks)
  end

  def is_valid?(_test, _choices) do
    false
  end

  # ---------- SAVE ----------

  def clean_choices(choices, _tracks, _test), do: choices

  def submit(test, %{star: stars} = _choices, ip_address) do
    Enum.each(stars, fn {track_id, star} ->
      track = Enum.find(test.tracks, fn t -> t.id == track_id end)

      # we insert a new entry or increase the count if this combination of test + track + star exists
      on_conflict = [set: [count: dynamic([r], fragment("? + ?", r.count, 1))]]

      {:ok, _updated} =
        Repo.insert(%Star{test: test, track: track, star: star, count: 1},
          on_conflict: on_conflict,
          conflict_target: [:test_id, :track_id, :star]
        )
    end)

    %StarDetails{test: test}
    |> StarDetails.changeset(%{
      stars: stars,
      ip_address: ip_address
    })
    |> Repo.insert()
  end
end
