defmodule FunkyABX.Tests do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test
  alias FunkyABX.Rank
  alias FunkyABX.Ranks
  alias FunkyABX.Pick
  alias FunkyABX.Picks
  alias FunkyABX.Identification
  alias FunkyABX.Identifications

  @min_test_created_minutes 15

  # ---------- GET ----------

  def get(id) when is_binary(id) do
    Repo.get(Test, id)
    |> Repo.preload([:tracks])
  end

  def get_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Test, slug: slug)
    |> Repo.preload([:tracks])
  end

  def get_edit(slug, key) when is_binary(slug) and is_binary(key) do
    Repo.get_by!(Test, slug: slug, password: key)
    |> Repo.preload([:tracks])
  end

  def get_for_gallery() do
    query =
      from t in Test,
        where:
          t.public == true and is_nil(t.closed_at) and is_nil(t.deleted_at) and
            t.inserted_at < ago(@min_test_created_minutes, "minute"),
        order_by: [desc: t.inserted_at],
        select: t

    Repo.all(query)
  end

  # ---------- VOTES ----------

  def has_tests_taken?(test_id) do
    query =
      from t in Test,
        left_join: r in Rank,
        on: t.id == r.test_id,
        left_join: p in Pick,
        on: t.id == p.test_id,
        left_join: i in Identification,
        on: t.id == i.test_id,
        where: t.id == ^test_id,
        group_by: [t.id],
        select: %{
          id: t.id,
          has_ranks:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              r.rank
            ),
          has_picking:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              p.picked
            ),
          has_identifications:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              i.count
            )
        }

    Repo.one(query)
    |> case do
      %{has_identifications: true} = _data -> true
      %{has_ranks: true} = _data -> true
      _ -> false
    end
  end

  def get_how_many_taken(test) do
    ranks = Ranks.get_ranks(test)
    picking = Picks.get_picks(test)
    identifications = Identifications.get_identification(test)
    get_how_many_taken(ranks, picking, identifications)
  end

  def get_how_many_taken(rankings, picking, identifications) do
    [
      Ranks.get_how_many_taken(rankings),
      Picks.get_how_many_taken(picking),
      Identifications.get_how_many_taken(identifications)
    ]
    |> Enum.max()
  end
end
