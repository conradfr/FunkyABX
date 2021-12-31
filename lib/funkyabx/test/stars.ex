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
        group_by: [t.id, s.track_id],
        order_by: [
          desc: fragment("rank_decimal"),
          asc: t.title,
          desc: s.track_id
        ],
        select: %{
          track_id: s.track_id,
          track_title: t.title,
          rank:
            fragment("ROUND((SUM(? * ?)::decimal / SUM(?)))::integer", s.star, s.count, s.count),
          rank_decimal:
            fragment("(SUM(? * ?)::decimal / SUM(?)) as rank_decimal", s.star, s.count, s.count),
          total_star: fragment("SUM(?)", s.count)
        }

    # Can't make a sql query that avoids duplicate track or star so we clean the data here instead
    query
    |> Repo.all()
  end

  def get_how_many_taken(stars) when is_nil(stars) or length(stars) == 0, do: 0

  def get_how_many_taken(stars) do
    stars
    |> Enum.reduce(0, fn s, acc -> acc + s.total_star end)
    |> Kernel.div(length(stars))
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
