defmodule FunkyABX.Test do
  import Ecto.Changeset
  use Ecto.Schema
  alias Ecto.UUID
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test.TitleSlug
  alias FunkyABX.{Tests, Track, RankDetails, PickDetails, IdentificationDetails, Invitation}
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
    field(:hide_global_results, :boolean, default: false)
    field(:to_close_at_enabled, :boolean, default: false)
    field(:to_close_at, :naive_datetime)
    field(:to_close_at_timezone, :string, virtual: true, default: "Etc/UTC")
    field(:closed_at, :naive_datetime)
    field(:deleted_at, :naive_datetime)
    field(:normalization, :boolean)
    field(:email_notification, :boolean, default: false)
    field(:upload_url, :string, virtual: true)
    field(:local, :boolean, virtual: true, default: false)
    field(:embed, :boolean, virtual: true, default: false)
    field(:view_count, :integer, default: 0)
    field(:last_viewed_at, :naive_datetime)
    field(:archived, :boolean, default: false)
    has_many(:tracks, Track, on_replace: :delete_if_exists)
    has_many(:invitations, Invitation, on_replace: :delete_if_exists)
    has_many(:rank_details, RankDetails)
    has_many(:pick_details, PickDetails)
    has_many(:identification_details, IdentificationDetails)
    belongs_to(:user, User)
    timestamps()
  end

  def new(params \\ %{}) do
    %Test{
      id: UUID.generate(),
      local: false,
      type: :regular,
      author: Map.get(params, :author, nil),
      access_key: Map.get(params, :access_key, nil),
      password_length: nil,
      upload_url: nil,
      tracks: [],
      normalization: false,
      user: Map.get(params, :user, nil),
      nb_of_rounds: @default_rounds,
      anonymized_track_title: true,
      hide_global_results: false,
      ip_address: Map.get(params, :ip_address, nil),
      to_close_at_timezone: Map.get(params, :to_close_at_timezone, nil),
      invitations: []
    }
  end

  def new_local() do
    %Test{
      id: UUID.generate(),
      type: :regular,
      local: true,
      title: "Local test",
      nb_of_rounds: 10,
      anonymized_track_title: false,
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
      :hide_global_results,
      :to_close_at_enabled,
      :to_close_at,
      :email_notification,
      :upload_url,
      :ip_address
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2, required: true)
    |> cast_assoc(:user)
    |> Validators.validate_general_type()
    |> Validators.ensure_regular_type()
    |> Validators.ensure_not_public_when_password_and_encode()
    |> Validators.ensure_no_notification_when_not_logged()
    |> Validators.ensure_no_to_close_at_when_listening()
    #    |> Validators.ensure_not_public_when_listening()
    |> Validators.validate_ranking_extremities(@minimum_tracks_for_extremities_ranking)
    |> Validators.validate_nb_rounds()
    |> Validators.validate_anonymized()
    |> Validators.validate_max_reference_track()
    |> Validators.validate_nb_tracks(@minimum_tracks)
    |> validate_required([:type, :title, :nb_of_rounds, :anonymized_track_title])
    #    |> validate_length(:tracks,
    #      min: @minimum_tracks,
    #      message: "A test needs to have at least two tracks."
    #    )
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
      :hide_global_results,
      :to_close_at_enabled,
      :to_close_at,
      :email_notification,
      :upload_url
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2, required: true)
    |> Validators.validate_general_type()
    |> Validators.ensure_regular_type()
    |> Validators.ensure_not_public_when_password_and_encode()
    |> Validators.ensure_no_notification_when_not_logged()
    |> Validators.ensure_no_to_close_at_when_listening()
    #    |> Validators.ensure_not_public_when_listening()
    |> Validators.validate_ranking_extremities(@minimum_tracks_for_extremities_ranking)
    |> Validators.validate_nb_rounds()
    |> Validators.validate_anonymized()
    |> Validators.validate_max_reference_track()
    |> Validators.validate_nb_tracks(@minimum_tracks)
    |> validate_required([:type, :title, :nb_of_rounds, :anonymized_track_title])

    #    |> validate_length(:tracks,
    #      min: @minimum_tracks,
    #      message: "A test needs to have at least two tracks."
    #    )
  end

  def changeset_close(test, _attrs \\ %{}) do
    value =
      case Tests.is_closed?(test) do
        true -> nil
        false -> NaiveDateTime.utc_now()
      end

    test
    |> cast(%{"closed_at" => value}, [:closed_at])
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
    #    |> Validators.validate_nb_tracks(@minimum_tracks)
    |> cast(%{upload_url: nil}, [:upload_url])
  end

  def changeset_last_viewed(test, attrs \\ %{}) do
    test
    |> cast(attrs, [:last_viewed_at])
  end

  def changeset_archived(test, attrs \\ %{}) do
    test
    |> cast(attrs, [:archived, :last_viewed_at])
  end

  def changeset_tracks(test) do
    test
    |> cast(%{}, [])
    |> Validators.validate_max_reference_track()
    |> Validators.validate_nb_tracks(@minimum_tracks)
  end

  def changeset_local(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :type,
      :nb_of_rounds,
      :anonymized_track_title,
      :rating,
      :regular_type,
      :ranking_only_extremities,
      :identification,
      :upload_url
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2)
    |> Validators.validate_general_type()
    |> Validators.ensure_regular_type()
    |> Validators.validate_nb_rounds()
    |> Validators.validate_anonymized()
    |> Validators.validate_ranking_extremities(@minimum_tracks_for_extremities_ranking)
    |> validate_required([:type, :nb_of_rounds])
    |> Validators.validate_nb_tracks(@minimum_tracks)

    #    |> validate_length(:tracks,
    #      min: @minimum_tracks,
    #      message: "A test needs to have at least two tracks."
    #    )
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
