defmodule FunkyABX.Tests do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test
  alias FunkyABX.Tracks
  alias FunkyABX.Rank
  alias FunkyABX.Ranks
  alias FunkyABX.Pick
  alias FunkyABX.Picks
  alias FunkyABX.Star
  alias FunkyABX.Stars
  alias FunkyABX.Identification
  alias FunkyABX.Identifications

  @min_test_created_minutes 15

  # TODO dynamic module loading w/ behavior

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

  # ---------- BUILD ----------

  def get_test_modules(test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_test_modules, [test])
  end

  def get_choices_modules(test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_choices_modules, [test])
  end

  def get_result_modules(test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_result_modules, [test])
  end

  defp get_test_module(test) do
    case test.type do
      :regular ->
        FunkyABX.Tests.Regular

      # :abx ->
      #   FunkyABX.Tests.ABX

      :listening ->
        FunkyABX.Tests.Listening
    end
  end

  # ---------- PARAMS ----------

  def get_test_params(test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_test_params, [test])
  end

  # ---------- FORM ----------

  def is_valid?(test, choices) do
    test
    |> get_test_module()
    |> Kernel.apply(:is_valid?, [test, choices])
  end

  # ---------- SAVE ----------

  def clean_choices(choices, tracks, test) do
    test
    |> get_test_module()
    |> IO.inspect()
    |> Kernel.apply(:clean_choices, [choices, tracks, test])
  end

  # todo wrap everything in a transaction

  def submit(test, choices, ip_address) do
    test
    |> get_test_module()
    |> Kernel.apply(:submit, [test, choices, ip_address])
  end

  # ---------- VOTES ----------

  # todo dynamic query from modules

  def has_tests_taken?(test_id) do
    query =
      from t in Test,
        left_join: r in Rank,
        on: t.id == r.test_id,
        left_join: p in Pick,
        on: t.id == p.test_id,
        left_join: s in Star,
        on: t.id == s.test_id,
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
          has_picks:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              p.picked
            ),
          has_stars:
            fragment(
              "CASE WHEN SUM(CASE WHEN ? IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN TRUE ELSE FALSE END",
              s.star
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
      %{has_picks: true} = _data -> true
      %{has_stars: true} = _data -> true
      _ -> false
    end
  end

  def get_how_many_taken(test) do
    ranks = Ranks.get_ranks(test)
    picks = Picks.get_picks(test)
    stars = Stars.get_stars(test)
    identifications = Identifications.get_identification(test)
    get_how_many_taken(ranks, picks, stars, identifications)
  end

  def get_how_many_taken(ranks, picks, stars, identifications) do
    [
      Ranks.get_how_many_taken(ranks),
      Picks.get_how_many_taken(picks),
      Stars.get_how_many_taken(stars),
      Identifications.get_how_many_taken(identifications)
    ]
    |> Enum.max()
  end
end
