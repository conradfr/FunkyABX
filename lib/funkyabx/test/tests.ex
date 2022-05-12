defmodule FunkyABX.Tests do
  import Ecto.Query, only: [from: 2]
  use Nebulex.Caching

  alias FunkyABX.Repo
  alias FunkyABX.Cache
  alias FunkyABX.Test
  alias FunkyABX.Accounts.User

  @min_test_created_minutes 15

  @cache_test_ttl :timer.hours(1)
  @cache_user_ttl :timer.minutes(5)
  @cache_gallery_ttl :timer.minutes(5)
  @cache_gallery_home_ttl :timer.minutes(1)
  @cache_gallery_key "gallery"
  @cache_gallery_key "gallery_home"

  @demo_slugs ["demo", "abx-demo"]

  # ---------- GET ----------

  @decorate cacheable(cache: Cache, key: {Test, id}, opts: [ttl: @cache_test_ttl])
  def get(id) when is_binary(id) do
    Repo.get(Test, id)
    |> Repo.preload([:tracks])
  end

  @decorate cacheable(cache: Cache, key: {Test, slug}, opts: [ttl: @cache_test_ttl])
  def get_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Test, slug: slug)
    |> Repo.preload([:tracks])
  end

  def get_edit(slug, key) when is_binary(slug) and is_binary(key) do
    Repo.get_by!(Test, slug: slug, password: key)
    |> Repo.preload([:tracks])
  end

  # todo also use limit as key
  @decorate cacheable(cache: Cache, key: "user_test_#{user.id}", opts: [ttl: @cache_user_ttl])
  def get_of_user(user, limit) do
    query =
      from(t in Test,
        where: t.user_id == ^user.id and is_nil(t.deleted_at),
        order_by: [desc: t.inserted_at],
        limit: ^limit,
        select: t
      )

    Repo.all(query)
  end

  @decorate cacheable(cache: Cache, key: @cache_gallery_key, opts: [ttl: @cache_gallery_ttl])
  def get_for_gallery() do
    query =
      from t in Test,
        where:
          t.public == true and is_nil(t.closed_at) and is_nil(t.deleted_at) and
            t.inserted_at < ago(@min_test_created_minutes, "minute"),
        order_by: [desc: t.inserted_at],
        select: t,
        preload: [tracks: :test]

    query
    |> Repo.all()
    # todo: one query, will do for now w/ caching & small number of tests
    |> Enum.map(fn t ->
      taken = get_how_many_taken(t)
      Map.put(t, :taken, taken)
    end)
  end

  @decorate cacheable(
              cache: Cache,
              key: [@cache_gallery_home_ttl, number],
              opts: [ttl: @cache_gallery_home_ttl]
            )
  def get_random(number \\ 3) do
    query =
      from t in Test,
        where:
          t.public == true and is_nil(t.closed_at) and is_nil(t.deleted_at) and
            t.inserted_at < ago(@min_test_created_minutes, "minute") and
            t.slug not in @demo_slugs,
        order_by: fragment("RANDOM()"),
        limit: ^number,
        select: t,
        preload: [tracks: :test]

    query
    |> Repo.all()
  end

  # ---------- CACHE ----------

  def clean_get_test_cache(%Test{} = test) do
    Cache.delete({Test, test.id})
    Cache.delete({Test, test.slug})

    if test.public == true do
      Cache.delete(@cache_gallery_key)
    end
  end

  def clean_get_user_cache(%User{} = user) do
    Cache.delete("user_test_#{user.id}")
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

  # ---------- PASSWORD ----------

  def valid_password?(%Test{password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
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

  # ---------- UTILS ----------

  def assign_new(choices, round, key, default \\ %{}) do
    case is_map_key(choices, round) do
      true -> Map.get(choices[round], key, default)
      false -> default
    end
  end
end
