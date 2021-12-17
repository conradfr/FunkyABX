defmodule FunkyABX.Picks do
  import Ecto.Query, only: [dynamic: 2, from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Pick
  alias FunkyABX.PickDetails

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

  def get_how_many_taken(pickings) when is_nil(pickings) or length(pickings) == 0, do: 0

  def get_how_many_taken(pickings) do
    pickings
    |> Enum.reduce(0, fn p, acc -> acc + p.picked end)
  end

  def is_valid?(picking, test) do
    case test.picking do
      true -> picking != nil
      _ -> true
    end
  end

  def submit(test, _picking, _ip_address) when test.picking != true, do: %{}

  def submit(test, track_id, ip_address) do
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
      ip_address: ip_address
    })
    |> Repo.insert()

    track_id
  end
end
