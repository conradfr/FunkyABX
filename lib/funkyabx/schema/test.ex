defmodule FunkyABX.Test do
  import Ecto.Changeset
  use Ecto.Schema
  alias Ecto.UUID
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test.TitleSlug
  alias FunkyABX.Track
  alias FunkyABX.RankDetails
  alias FunkyABX.PickDetails
  alias FunkyABX.IdentificationDetails
  alias __MODULE__

  @minimum_tracks 2
  @minimum_tracks_for_extremities_ranking 10
  @default_rounds 10

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "test" do
    field(:title, :string)
    field(:author, :string)
    field(:description, :string)
    field(:description_markdown, :boolean)
    field(:slug, TitleSlug.Type)
    field(:public, :boolean)
    field(:access_key, :string)
    field(:password_enabled, :boolean)
    field(:password, :string)
    field(:password_length, :integer)
    field(:password_input, :string, virtual: true)
    field(:type, Ecto.Enum, values: [regular: 1, abx: 2, listening: 3])
    field(:regular_type, Ecto.Enum, values: [rank: 1, pick: 2, star: 3])
    field(:anonymized_track_title, :boolean)
    field(:rating, :boolean)
    field(:ranking_only_extremities, :boolean)
    field(:identification, :boolean)
    field(:nb_of_rounds, :integer)
    field(:ip_address, :binary)
    field(:to_closed_at, :naive_datetime)
    field(:closed_at, :naive_datetime)
    field(:deleted_at, :naive_datetime)
    field(:normalization, :boolean)
    field(:email_notification, :boolean)
    field(:upload_url, :string, virtual: true)
    timestamps()
    belongs_to(:user, User)
    has_many(:tracks, Track, on_replace: :delete_if_exists)
    has_many(:rank_details, RankDetails)
    has_many(:pick_details, PickDetails)
    has_many(:identification_details, IdentificationDetails)
  end

  def new(user \\ nil) do
    %Test{
      id: UUID.generate(),
      type: :regular,
      rating: true,
      regular_type: :pick,
      ranking_only_extremities: false,
      identification: false,
      author: nil,
      access_key: nil,
      password_enabled: false,
      password_length: nil,
      description_markdown: false,
      upload_url: nil,
      tracks: [],
      normalization: false,
      user: user,
      nb_of_rounds: @default_rounds,
      anonymized_track_title: true,
      email_notification: false,
      ip_address: nil
    }
  end

  def changeset(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :title,
      :author,
      :description,
      :description_markdown,
      :public,
      :access_key,
      :password_enabled,
      :password_length,
      :password_input,
      :password,
      :type,
      :nb_of_rounds,
      :anonymized_track_title,
      :rating,
      :regular_type,
      :ranking_only_extremities,
      :identification,
      :normalization,
      :email_notification,
      :upload_url
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2, required: true)
    |> cast_assoc(:user)
    |> validate_general_type()
    |> ensure_regular_type()
    |> ensure_not_public_when_password_and_encode()
    |> ensure_no_notification_when_not_logged()
    |> validate_ranking_extremities()
    |> validate_nb_rounds()
    |> validate_anonymized()
    |> validate_required([:type, :title, :nb_of_rounds, :anonymized_track_title])
    |> validate_length(:tracks,
      min: @minimum_tracks,
      message: "A test needs to have at least two tracks."
    )
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end

  def changeset_update(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :title,
      :author,
      :description,
      :description_markdown,
      :public,
      :access_key,
      :password_enabled,
      :password_length,
      :password_input,
      :password,
      :type,
      :nb_of_rounds,
      :anonymized_track_title,
      :rating,
      :regular_type,
      :ranking_only_extremities,
      :identification,
      :normalization,
      :email_notification,
      :upload_url
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2, required: true)
    |> validate_general_type()
    |> ensure_regular_type()
    |> ensure_not_public_when_password_and_encode()
    |> ensure_no_notification_when_not_logged()
    |> validate_ranking_extremities()
    |> validate_nb_rounds()
    |> validate_anonymized()
    |> validate_required([:type, :title, :nb_of_rounds, :anonymized_track_title])
    |> validate_length(:tracks,
      min: @minimum_tracks,
      message: "A test needs to have at least two tracks."
    )
  end

  def changeset_delete(test, _attrs \\ %{}) do
    test
    |> cast(%{"deleted_at" => NaiveDateTime.utc_now()}, [:deleted_at])
    |> reclaim_slug_when_test_private()
  end

  def changeset_to_user(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :access_key
    ])
    |> put_assoc(:user, attrs["user"])
  end

  def changeset_reset_upload_url(test) do
    test
    |> cast(%{upload_url: nil}, [:upload_url])
  end

  defp reclaim_slug_when_test_private(changeset) do
    public = get_field(changeset, :public)
    slug = get_field(changeset, :slug)

    case public do
      true -> changeset
      false -> put_change(changeset, :slug, slug <> "_" <> UUID.generate())
    end
  end

  defp ensure_regular_type(changeset) do
    rating = get_field(changeset, :rating)

    case rating do
      false -> put_change(changeset, :regular_type, nil)
      _ -> changeset
    end
  end

  defp ensure_not_public_when_password_and_encode(changeset) do
    changeset
    |> get_field(:password_enabled)
    |> password_values(changeset)
  end

  defp password_values(password_enabled, changeset) when password_enabled == false do
    changeset
    |> put_change(:password_enabled, password_enabled)
    |> put_change(:password_length, nil)
    |> put_change(:password, nil)
  end

  defp password_values(password_enabled, changeset) do
    current_password = get_field(changeset, :password_length)

    password =
      changeset
      |> get_field(:password_input)
      |> case do
        nil -> nil
        value -> String.trim(value)
      end
      |> case do
        nil -> nil
        "" -> nil
        value -> value
      end

    case password do
      nil when is_nil(current_password) ->
        add_error(changeset, :password_input, "Password can't be empty")

      nil ->
        changeset

      value ->
        changeset
        |> put_change(:password_length, String.length(value))
        |> put_change(:password_enabled, password_enabled)
        |> put_change(:password, Pbkdf2.hash_pwd_salt(value))
        |> put_change(:public, false)
    end
  end

  defp ensure_no_notification_when_not_logged(changeset) do
    case changeset.data.user_id do
      nil -> put_change(changeset, :email_notification, false)
      _ -> changeset
    end
  end

  defp validate_general_type(changeset) do
    type = get_field(changeset, :type)

    case type do
      :regular ->
        changeset
        |> at_least_one_regular()

      _ ->
        changeset
    end
  end

  defp validate_ranking_extremities(changeset) do
    tracks = get_field(changeset, :tracks)
    rating = get_field(changeset, :rating)
    regular_type = get_field(changeset, :regular_type)
    ranking_only_extremities = get_field(changeset, :ranking_only_extremities)

    if rating == true and regular_type == :raking and
         Kernel.length(tracks) < @minimum_tracks_for_extremities_ranking and
         ranking_only_extremities == true do
      add_error(changeset, :type, "Ranking only top/worst tracks is only allowed with 10+ tracks")
    else
      changeset
    end
  end

  defp validate_anonymized(changeset) do
    type = get_field(changeset, :type)

    case type do
      :regular -> put_change(changeset, :anonymized_track_title, true)
      :listening -> put_change(changeset, :anonymized_track_title, false)
      :abx -> changeset
    end
  end

  defp validate_nb_rounds(changeset) do
    type = get_field(changeset, :type)

    case type do
      :abx -> changeset
      _ -> put_change(changeset, :nb_of_rounds, 1)
    end
  end

  defp at_least_one_regular(changeset) do
    rating = get_field(changeset, :rating)
    identification = get_field(changeset, :identification)

    unless rating == false and identification == false do
      changeset
    else
      add_error(changeset, :type, "Select at least one option.")
    end
  end
end
