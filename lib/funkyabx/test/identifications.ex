defmodule FunkyABX.Identifications do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Identification

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
end
