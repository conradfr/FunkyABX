defmodule FunkyABX.Tests do
  import Ecto.Query, only: [from: 2, dynamic: 2, limit: 3]
  import Ecto.Changeset, only: [get_field: 2]
  use Nebulex.Caching

  alias Ecto.UUID
  alias Ecto.Changeset
  alias FunkyABX.Repo
  alias FunkyABX.{Cache, Test, Stats}
  alias FunkyABX.{PickDetails, StarDetails, RankDetails, IdentificationDetails, AbxDetails}
  alias FunkyABX.Accounts.User

  @min_test_created_minutes 15

  @cache_test_ttl :timer.minutes(15)
  @cache_tests_ttl :timer.minutes(5)
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
    |> Repo.preload([:tracks, :user, :invitations])
  end

  @decorate cacheable(cache: Cache, key: {Test, slug}, opts: [ttl: @cache_test_ttl])
  def get_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Test, slug: slug)
    |> Repo.preload([:tracks, :user, :invitations])
  end

  # no cache for edit
  def get_edit(slug) when is_binary(slug) do
    Repo.get_by(Test, slug: slug)
    |> Repo.preload([:tracks, :user, :invitations], force: true)
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
          t.public == true and is_nil(t.deleted_at) and
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

  def find_from_session_id(session_id) when is_binary(session_id) do
    query =
      from(t in Test,
        left_join: p in PickDetails,
        on: t.id == p.test_id,
        left_join: s in StarDetails,
        on: t.id == s.test_id,
        left_join: r in RankDetails,
        on: t.id == r.test_id,
        left_join: i in IdentificationDetails,
        on: t.id == i.test_id,
        left_join: a in AbxDetails,
        on: t.id == a.test_id,
        where:
          p.session_id == ^session_id or s.session_id == ^session_id or
            r.session_id == ^session_id or i.session_id == ^session_id or
            a.session_id == ^session_id,
        limit: 1,
        select: t,
        preload: [tracks: :test]
      )

    Repo.one(query)
  end

  # todo also use limit as key
  @decorate cacheable(
              cache: Cache,
              key: "tests_list_#{:crypto.hash(:sha256, test_ids)}",
              opts: [ttl: @cache_tests_ttl]
            )
  def get_tests_from_ids(test_ids, limit \\ nil) do
    query =
      from(t in Test,
        where: t.id in ^test_ids and is_nil(t.deleted_at),
        order_by: [desc: t.inserted_at],
        select: t
      )

    query =
      unless limit == nil do
        limit(query, [t], ^limit)
      else
        query
      end

    Repo.all(query)
  end

  # todo also use limit as key
  @decorate cacheable(
              cache: Cache,
              key: "tests_access_list_#{:crypto.hash(:sha256, test_ids ++ access_key_ids)}",
              opts: [ttl: @cache_tests_ttl]
            )
  def get_tests_from_ids_and_access_key_ids(test_ids, access_key_ids, limit \\ nil) do
    query =
      from(t in Test,
        where: t.id in ^test_ids and t.access_key in ^access_key_ids and is_nil(t.deleted_at),
        order_by: [desc: t.inserted_at],
        select: t
      )

    query =
      unless limit == nil do
        limit(query, [t], ^limit)
      else
        query
      end

    Repo.all(query)
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

  def get_test_modules(%Test{} = test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_test_modules, [test])
  end

  def get_choices_modules(%Test{} = test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_choices_modules, [test])
  end

  def get_result_modules(%Test{} = test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_result_modules, [test])
  end

  defp get_test_module(%Test{} = test) do
    test
    |> Map.get(:type)
    |> Atom.to_string()
    |> get_test_module()
  end

  defp get_test_module(%Changeset{} = changeset) do
    changeset
    |> get_field(:type)
    |> Atom.to_string()
    |> get_test_module()
  end

  defp get_test_module(type) when is_binary(type) do
    type
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

  def get_test_params(%Test{} = test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_test_params, [test])
  end

  # ---------- TRACKS ----------

  # from result page
  def prep_tracks(tracks, %Test{} = test, tracks_order) when is_list(tracks) do
    test
    |> get_test_module()
    |> Kernel.apply(:prep_tracks, [tracks, test, tracks_order])
  end

  def prep_tracks(tracks, %Test{} = test) when is_list(tracks) do
    test
    |> get_test_module()
    |> Kernel.apply(:prep_tracks, [tracks, test])
  end

  def get_reference_track(%Test{} = test) do
    Enum.find(test.tracks, fn t -> t.reference_track == true end)
  end

  def can_have_reference_track?(%Changeset{} = changeset) do
    changeset
    |> get_test_module()
    |> Kernel.apply(:can_have_reference_track?, [])
  end

  def can_have_reference_track?(test_type) when is_binary(test_type) do
    test_type
    |> get_test_module()
    |> Kernel.apply(:can_have_reference_track?, [])
  end

  def can_have_reference_track?(_params) do
    true
  end

  def can_have_player_on_results_page?(%Test{} = test) do
    test
    |> get_test_module()
    |> Kernel.apply(:can_have_player_on_results_page?, [])
  end

  def can_have_player_on_results_page?(_test), do: false

  def tracks_count(%Test{} = test) do
    test
    |> Map.get(:tracks, [])
    |> filter_reference_track()
    |> Kernel.length()
  end

  # ---------- FORM ----------

  def is_valid?(%Test{} = test, round, choices) do
    test
    |> get_test_module()
    |> Kernel.apply(:is_valid?, [test, round, choices])
  end

  def form_data_from_session(session) do
    %{
      identification: Map.get(session, "identification", false),
      rating: Map.get(session, "rating", true),
      regular_type: Map.get(session, "regular_type", :pick),
      tracks: Map.get(session, "tracks", []),
      type: Map.get(session, "type", :regular)
    }
  end

  def form_data_from_params(data, params) do
    %{
      identification:
        Map.get(params, "identification", false) || Map.get(data, "identification", false),
      rating: Map.get(params, "rating") || Map.get(data, "rating", true),
      regular_type: Map.get(params, "regular_type") || Map.get(data, "regular_type", :pick),
      tracks: data["tracks"],
      type: Map.get(params, "type") || Map.get(data, "type", :regular)
    }
  end

  # ---------- SAVE ----------

  def clean_choices(choices, tracks, %Test{} = test) when is_list(tracks) do
    test
    |> get_test_module()
    |> Kernel.apply(:clean_choices, [choices, tracks, test])
  end

  # todo wrap everything in a transaction

  def submit(%Test{} = test, choices, session_id, ip_address) do
    test
    |> get_test_module()
    |> Kernel.apply(:submit, [test, choices, session_id, ip_address])
  end

  def update_close_at(%Test{} = test)
      when test.to_close_at_enabled == false or test.to_close_at == nil do
  end

  def update_last_viewed(%Test{} = test) do
    params = %{
      "last_viewed_at" => NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    test
    |> Test.changeset_last_viewed(params)
    |> Repo.update()
  end

  # ---------- VIEWED ----------

  # we don't update old tests with no view counter
  def increment_view_counter(%Test{} = test) when test.view_count == nil, do: :ok

  def increment_view_counter(%Test{} = test) do
    Ecto.Adapters.SQL.query!(
      Repo,
      "UPDATE test SET view_count = view_count+1 where id = $1",
      [UUID.dump!(test.id)]
    )
  end

  # ---------- TAKEN ----------

  def has_tests_taken?(%Test{} = test) do
    get_how_many_taken(test) > 0
  end

  def get_how_many_taken(%Test{} = test) do
    test
    |> get_test_module()
    |> Kernel.apply(:get_how_many_taken, [test])
  end

  def increment_local_test_counter() do
    # we insert a new entry or increase the counter if the name exists
    on_conflict = [set: [counter: dynamic([s], fragment("? + ?", s.counter, 1))]]

    {:ok, _updated} =
      Repo.insert(%Stats{name: "local_test", counter: 1},
        on_conflict: on_conflict,
        conflict_target: :name
      )
  end

  # ---------- RESULTS ----------

  def parse_session_id(session_id) when session_id == nil, do: nil

  def parse_session_id(session_id) when is_binary(session_id) do
    unless String.contains?(session_id, "-") == true do
      ShortUUID.decode!(session_id)
    else
      session_id
    end
  end

  def get_results_of_session(%Test{} = test, session_id) when is_binary(session_id) do
    get_test_modules(test)
    |> Enum.reduce(%{}, fn module, acc ->
      Kernel.apply(module, :get_results, [test, session_id])
      |> Map.merge(acc)
    end)
  end

  # ---------- UTILS ----------

  def is_closed?(%Test{} = test) when test.closed_at == nil, do: false

  def is_closed?(%Test{} = test) do
    compare =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.compare(test.closed_at)

    compare != :lt
  end

  def has_reference_track?(%Test{} = test) do
    Enum.any?(test.tracks, fn t -> t.reference_track == true end)
  end

  def filter_reference_track(tracks) when is_list(tracks) do
    Enum.filter(tracks, fn t -> t.reference_track != true end)
  end

  def assign_new(choices, round, key, default \\ %{})

  # test page
  def assign_new(choices, round, key, default) when is_map_key(choices, round),
    do: Map.get(choices[round], key, default)

  # result page (from js, keys are string)
  def assign_new(choices, _round, key, default) do
    key_string = Atom.to_string(key)

    case is_map_key(choices, key_string) do
      true -> Map.get(choices, key_string, default)
      _ -> default
    end
  end
end
