defmodule FunkyABX.Tests do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Test

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
    test.type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&"Elixir.FunkyABX.Tests.#{&1}").()
    |> String.to_atom()
  end

  # ---------- PARAMS ----------

  def get_test_params(test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_test_params, [test])
  end

  # ---------- TRACKS ----------

  def prep_tracks(tracks, test) do
    test
    |> get_test_module()
    |> Kernel.apply(:prep_tracks, [tracks, test])
  end

  # ---------- FORM ----------

  def is_valid?(test, round, choices) do
    test
    |> get_test_module()
    |> Kernel.apply(:is_valid?, [test, round, choices])
  end

  # ---------- SAVE ----------

  def clean_choices(choices, tracks, test) do
    test
    |> get_test_module()
    |> Kernel.apply(:clean_choices, [choices, tracks, test])
  end

  # todo wrap everything in a transaction

  def submit(test, choices, ip_address) do
    test
    |> get_test_module()
    |> Kernel.apply(:submit, [test, choices, ip_address])
  end

  # ---------- TAKEN ----------

  def has_tests_taken?(test) do
    get_how_many_taken(test) > 0
  end

  def get_how_many_taken(test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_how_many_taken, [test])
  end

  # ---------- TAKEN ----------

  def assign_new(choices, round, key, default \\ %{}) do
    case is_map_key(choices, round) do
      true -> Map.get(choices[round], key, default)
      false -> default
    end
  end
end
