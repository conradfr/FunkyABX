defmodule FunkyABX.Stars do
  import Ecto.Query, only: [dynamic: 2, from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.Tests.Image
  alias FunkyABX.Tests
  alias FunkyABX.{Test, Track, Star, StarDetails}

  # ---------- GET ----------

  def get_stars(%Test{} = test, visitor_choices) when test.local == true do
    test
    |> Map.get(:tracks, [])
    |> Tests.filter_reference_track()
    |> Enum.map(fn t ->
      %{
        track_id: t.id,
        track_title: t.title,
        rank: Map.get(visitor_choices["star"], t.id, 0),
        total_star_5: (Map.get(visitor_choices["star"], t.id, 0) == 5 && 1) || 0,
        total_star_4: (Map.get(visitor_choices["star"], t.id, 0) == 4 && 1) || 0,
        total_star_3: (Map.get(visitor_choices["star"], t.id, 0) == 3 && 1) || 0,
        total_star_2: (Map.get(visitor_choices["star"], t.id, 0) == 2 && 1) || 0,
        total_star_1: (Map.get(visitor_choices["star"], t.id, 0) == 1 && 1) || 0
      }
    end)
    |> Enum.sort_by(&Map.fetch(&1, :rank), :desc)
  end

  def get_stars(%Test{} = test, _visitor_choices) do
    query =
      from t in Track,
        join: s in Star,
        on: t.id == s.track_id,
        where: s.test_id == ^test.id and t.reference_track != true,
        group_by: [t.id, s.track_id],
        order_by: [
          desc: fragment("rank_decimal"),
          desc: fragment("total_star_5"),
          desc: fragment("total_star_4"),
          desc: fragment("total_star_3"),
          desc: fragment("total_star_2"),
          desc: fragment("total_star_1"),
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
          total_star: fragment("SUM(?)", s.count),
          # todo do better
          total_star_5:
            fragment("SUM(CASE WHEN ? = ? THEN ? ELSE 0 END) as total_star_5", s.star, 5, s.count),
          total_star_4:
            fragment("SUM(CASE WHEN ? = ? THEN ? ELSE 0 END) as total_star_4", s.star, 4, s.count),
          total_star_3:
            fragment("SUM(CASE WHEN ? = ? THEN ? ELSE 0 END) as total_star_3", s.star, 3, s.count),
          total_star_2:
            fragment("SUM(CASE WHEN ? = ? THEN ? ELSE 0 END) as total_star_2", s.star, 2, s.count),
          total_star_1:
            fragment("SUM(CASE WHEN ? = ? THEN ? ELSE 0 END) as total_star_1", s.star, 1, s.count)
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

  def is_valid?(%Test{} = test, round, choices) when is_map_key(choices, round) do
    map_size(choices[round][:star] || %{}) == Tests.tracks_count(test)
  end

  def is_valid?(_test, _round, _choices), do: false

  # ---------- SAVE ----------

  def clean_choices(choices, _tracks, _test), do: choices

  def submit(%Test{} = test, %{star: stars} = _choices, session_id, ip_address) do
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
      session_id: session_id,
      ip_address: ip_address
    })
    |> Repo.insert()
  end

  # ---------- RESULTS ----------

  def get_results(%Test{} = test, session_id) when is_binary(session_id) do
    query =
      from sd in StarDetails,
        where: sd.test_id == ^test.id and sd.session_id == ^session_id,
        select: sd.stars

    result =
      query
      |> Repo.one()

    case result do
      nil -> %{}
      _ -> %{"star" => result}
    end
  end

  def results_to_img(mogrify_params, %Test{} = test, session_id, choices)
      when is_binary(session_id) do
    with stars when stars != nil <- Map.get(choices, "star", nil) do
      {start, mogrify} = mogrify_params

      {index, mogrify} =
        mogrify
        |> Image.type_title(start, "Rating")
        |> then(fn mogrify ->
          test
          |> Map.get(:tracks, [])
          |> Tests.filter_reference_track()
          |> Enum.sort_by(
            fn t ->
              Map.get(stars, t.id)
            end,
            :desc
          )
          |> Enum.reduce({1, mogrify}, fn t, acc ->
            {index, mogrify} = acc

            stars_text = String.pad_leading("", Map.get(stars, t.id), "*")
            mogrify = Image.type_track(mogrify, start, index, "#{t.title}: #{stars_text}")

            {index + 1, mogrify}
          end)
        end)

      {start + 24 + 16 * index, mogrify}
    else
      _ -> mogrify_params
    end
  end
end
