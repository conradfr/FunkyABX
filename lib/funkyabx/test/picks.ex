defmodule FunkyABX.Picks do
  import Ecto.Query, only: [dynamic: 2, from: 2]

  alias FunkyABX.Repo
  alias FunkyABX.{Test, Track, Pick, PickDetails}

  # ---------- GET ----------

  def get_picks(%Test{} = test, visitor_choices) when test.local == true do
    test.tracks
    |> Enum.map(fn t ->
      picked =
        case Map.get(visitor_choices, "pick") do
          pick when pick == t.id -> 1
          _ -> 0
        end

      %{
        track_id: t.id,
        track_title: t.title,
        picked: picked
      }
    end)
  end

  def get_picks(%Test{} = test, _visitor_choices) do
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

  def get_how_many_taken(%Test{} = test) do
    query =
      from pd in PickDetails,
        where: pd.test_id == ^test.id,
        select: fragment("COUNT(*)")

    query
    |> Repo.one()
  end

  # ---------- FORM ----------

  def is_valid?(_test, round, choices) when is_map_key(choices, round) do
    Map.get(choices[round], :pick) != nil
  end

  def is_valid?(_test, _round, _choices), do: false

  # ---------- SAVE ----------

  def clean_choices(choices, _tracks, _test), do: choices

  def submit(test, %{pick: track_id} = _choices, session_id, ip_address) do
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
      session_id: session_id,
      ip_address: ip_address
    })
    |> Repo.insert()

    track_id
  end

  # ---------- RESULTS ----------

  def get_results(%Test{} = test, session_id) when is_binary(session_id) do
    query =
      from pd in PickDetails,
        where: pd.test_id == ^test.id and pd.session_id == ^session_id,
        select: pd.track_id

    result =
      query
      |> Repo.one()

    case result do
      nil -> %{}
      _ -> %{"pick" => result}
    end
  end
end
