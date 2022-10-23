defmodule FunkyABX.Test do
  import Ecto.Changeset
  use Ecto.Schema
  alias Ecto.UUID
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test.TitleSlug
  alias FunkyABX.{Track, RankDetails, PickDetails, IdentificationDetails, Invitation}
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
    field(:description_markdown, :boolean, default: false)
    field(:slug, TitleSlug.Type)
    field(:public, :boolean, default: false)
    field(:access_key, :string)
    field(:password_enabled, :boolean, default: false)
    field(:password, :string)
    field(:password_length, :integer)
    field(:password_input, :string, virtual: true, default: nil)
    field(:type, Ecto.Enum, values: [regular: 1, abx: 2, listening: 3], default: :regular)
    field(:regular_type, Ecto.Enum, values: [rank: 1, pick: 2, star: 3], default: :pick)
    field(:anonymized_track_title, :boolean)
    field(:rating, :boolean, default: true)
    field(:ranking_only_extremities, :boolean, default: false)
    field(:identification, :boolean, default: false)
    field(:nb_of_rounds, :integer)
    field(:ip_address, :binary)
    field(:to_closed_at, :naive_datetime)
    field(:closed_at, :naive_datetime)
    field(:deleted_at, :naive_datetime)
    field(:normalization, :boolean)
    field(:email_notification, :boolean, default: false)
    field(:upload_url, :string, virtual: true)
    field(:local, :boolean, virtual: true, default: false)
    field(:embed, :boolean, virtual: true, default: false)
    has_many(:tracks, Track, on_replace: :delete_if_exists)
    has_many(:invitations, Invitation, on_replace: :delete_if_exists)
    has_many(:rank_details, RankDetails)
    has_many(:pick_details, PickDetails)
    has_many(:identification_details, IdentificationDetails)
    belongs_to(:user, User)
    timestamps()
  end

  def new(user \\ nil) do
    %Test{
      id: UUID.generate(),
      local: false,
      type: :regular,
      author: nil,
      access_key: nil,
      password_length: nil,
      upload_url: nil,
      tracks: [],
      normalization: false,
      user: user,
      nb_of_rounds: @default_rounds,
      anonymized_track_title: true,
      ip_address: nil,
      invitations: []
    }
  end

  def new_local() do
    %Test{
      id: UUID.generate(),
      local: true,
      title: "Local test",
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
