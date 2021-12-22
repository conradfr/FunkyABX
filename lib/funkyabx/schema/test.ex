defmodule FunkyABX.Test do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test.TitleSlug
  alias FunkyABX.Track
  alias FunkyABX.RankDetails
  alias FunkyABX.PickDetails
  alias FunkyABX.IdentificationDetails

  @minimum_tracks 2
  @minimum_tracks_for_extremities_ranking 10

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "test" do
    field(:title, :string)
    field(:author, :string)
    field(:description, :string)
    field(:description_markdown, :boolean)
    field(:slug, TitleSlug.Type)
    field(:public, :boolean)
    field(:password, :string)
    field(:ranking, :boolean)
    field(:ranking_only_extremities, :boolean)
    field(:picking, :boolean)
    field(:identification, :boolean)
    field(:type, Ecto.Enum, values: [regular: 1, abx: 2, listening: 3])
    field(:ip_address, :binary)
    field(:to_closed_at, :naive_datetime)
    field(:closed_at, :naive_datetime)
    field(:deleted_at, :naive_datetime)
    timestamps()
    belongs_to(:user, User)
    has_many(:tracks, Track, on_replace: :delete_if_exists)
    has_many(:rank_details, RankDetails)
    has_many(:pick_details, PickDetails)
    has_many(:identification_details, IdentificationDetails)
  end

  def changeset(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :title,
      :author,
      :description,
      :description_markdown,
      :public,
      :password,
      :type,
      :ranking,
      :ranking_only_extremities,
      :picking,
      :identification
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2)
    |> cast_assoc(:user)
    |> validate_required([:type, :title])
    |> validate_general_type()
    |> validate_ranking_extremities()
    #    |> validate_length(:tracks, min: @minimum_tracks)
    |> validate_minimum_tracks()
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
      :password,
      :type,
      :ranking,
      :ranking_only_extremities,
      :picking,
      :identification
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2)
    |> validate_required([:type, :title])
    |> validate_general_type()
    |> validate_ranking_extremities()
    |> validate_length(:tracks, min: @minimum_tracks)
  end

  def changeset_delete(test, _attrs \\ %{}) do
    test
    |> cast(%{"deleted_at" => NaiveDateTime.utc_now()}, [:deleted_at])
  end

  def changeset_to_user(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :password
    ])
    |> put_assoc(:user, attrs["user"])
  end

  def validate_general_type(changeset) do
    ranking = get_field(changeset, :ranking)
    picking = get_field(changeset, :picking)
    identification = get_field(changeset, :identification)
    type = get_field(changeset, :type)

    case type do
      :regular ->
        changeset
        |> at_least_one_regular(ranking, picking, identification)
        |> ranking_or_picking(ranking, picking)

      _ ->
        changeset
    end
  end

  defp validate_ranking_extremities(changeset) do
    tracks = get_field(changeset, :tracks)
    ranking = get_field(changeset, :ranking)
    ranking_only_extremities = get_field(changeset, :ranking_only_extremities)

    if ranking == true and Kernel.length(tracks) < @minimum_tracks_for_extremities_ranking
       and ranking_only_extremities == true do
      add_error(changeset, :type, "Ranking only top/worst tracks ins only allowed with 10+ tracks")
    else
      changeset
    end
  end

  def validate_minimum_tracks(changeset) do
    tracks = get_field(changeset, :tracks)

    if Kernel.length(tracks) < @minimum_tracks do
      add_error(changeset, :tracks, "A test needs to have at least two tracks.")
    else
      changeset
    end
  end

  defp at_least_one_regular(changeset, ranking, picking, identification) do
    if ranking == true or picking == true or identification == true do
      changeset
    else
      add_error(changeset, :type, "Select at least one option.")
    end
  end

  defp ranking_or_picking(changeset, ranking, picking) do
    if ranking == true and picking == true do
      add_error(changeset, :type, "Pick and rank can't be selected at the same time.")

    else
      changeset
    end
  end
end
