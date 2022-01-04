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

    query
    |> Repo.all()
  end

  def get_how_many_taken(test) do
    query =
      from sd in StarDetails,
        where: sd.test_id == ^test.id,
        select: fragment("COUNT(*)")

    query
    |> Repo.one()
  end

  # ---------- FORM ----------

  def is_valid?(test, round, choices) when is_map_key(choices, round) do
    map_size(choices[round][:star] || %{}) == Kernel.length(test.tracks)
  end

  def is_valid?(_test, _round, _choices), do: false

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
