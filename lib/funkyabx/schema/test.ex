defmodule FunkyABX.Test do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test.TitleSlug
  alias FunkyABX.Track

  @minimum_tracks 2

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
    field(:identification, :boolean)
    field(:type, Ecto.Enum, values: [regular: 1, abx: 2, listening: 3])
    field(:ip_address, :binary)
    field(:to_closed_at, :naive_datetime)
    field(:closed_at, :naive_datetime)
    field(:deleted_at, :naive_datetime)
    timestamps()
    belongs_to(:user, User)
    has_many(:tracks, Track, on_replace: :delete_if_exists)
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
      :identification
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2)
    |> cast_assoc(:user)
    |> validate_required([:type, :title])
    |> validate_general_type()
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
      :identification
    ])
    |> cast_assoc(:tracks, with: &Track.changeset/2)
    |> validate_required([:type, :title])
    |> validate_general_type()
    |> validate_length(:tracks, min: @minimum_tracks)
  end

  def changeset_delete(test, _attrs \\ %{}) do
    test
    |> cast(%{"deleted_at" => NaiveDateTime.utc_now()}, [:deleted_at])
  end

  def changeset_to_user(test, attrs \\ %{}) do
    test
    |> cast(attrs, [
      :password,
    ])
    |> put_assoc(:user, attrs["user"])
  end

  def validate_general_type(changeset) do
    ranking = get_field(changeset, :ranking)
    identification = get_field(changeset, :identification)
    type = get_field(changeset, :type)

    case type do
      :regular ->
        if ranking == true or identification == true do
          changeset
        else
          add_error(changeset, :type, "Select at least one option.")
        end

      _ ->
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
end
