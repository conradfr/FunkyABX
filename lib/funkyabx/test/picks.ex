defmodule FunkyABX.Picks do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Pick

  def get_picks(test) do
    query =
      from t in Track,
        left_join: p in Pick,
        on: t.id == p.track_id,
        where: t.test_id == ^test.id,
        order_by: [
          desc: fragment("picked"),
          asc: t.title
        ],
        select: %{
          track_id: t.id,
          track_title: t.title,
          picked: fragment("COALESCE(?, 0) as picked", p.picked)
        }

    query
    |> Repo.all()
  end
end
