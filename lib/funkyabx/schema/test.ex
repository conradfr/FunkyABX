defmodule FunkyABX.Test do
  import Ecto.Changeset
  use Ecto.Schema
  alias Ecto.UUID
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test.TitleSlug
  alias FunkyABX.{Track, RankDetails, PickDetails, IdentificationDetails}
  alias FunkyABX.Tests.Validators
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
    field(:local, :boolean, virtual: true, default: false)
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
      local: false,
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

  def new_local() do
    %Test{
      id: UUID.generate(),
      local: true,
      title: "Local test",
      type: :regular,
      rating: true,
      regular_type: :pick,
      ranking_only_extremities: false,
      identification: false,
      nb_of_rounds: 1,
      tracks: []
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
    |> Validators.validate_general_type()
    |> Validators.ensure_regular_type()
    |> Validators.ensure_not_public_when_password_and_encode()
    |> Validators.ensure_no_notification_when_not_logged()
    |> Validators.validate_ranking_extremities(@minimum_tracks_for_extremities_ranking)
    |> Validators.validate_nb_rounds()
    |> Validators.validate_anonymized()
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
    |> Validators.validate_general_type()
    |> Validators.ensure_regular_type()
    |> Validators.ensure_not_public_when_password_and_encode()
    |> Validators.ensure_no_notification_when_not_logged()
    |> Validators.validate_ranking_extremities(@minimum_tracks_for_extremities_ranking)
    |> Validators.validate_nb_rounds()
    |> Validators.validate_anonymized()
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

  def changeset_local(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :type,
      :rating,
      :regular_type,
      :ranking_only_extremities,
      :identification
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2)
    |> Validators.validate_general_type()
    |> Validators.ensure_regular_type()
    |> Validators.validate_ranking_extremities(@minimum_tracks_for_extremities_ranking)
    |> validate_required([:type])
    |> validate_length(:tracks,
      min: @minimum_tracks,
      message: "A test needs to have at least two tracks."
    )
  end

  # ---------- DATA ----------

  defp reclaim_slug_when_test_private(changeset) do
    public = get_field(changeset, :public)
    slug = get_field(changeset, :slug)

    case public do
      true -> changeset
      false -> put_change(changeset, :slug, slug <> "_" <> UUID.generate())
    end
  end
end
