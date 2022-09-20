defmodule FunkyABX.Track do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test
  alias FunkyABX.Pick

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "track" do
    field(:title, :string)
    field(:filename, :string)
    field(:original_filename, :string)
    field(:temp_id, :string, virtual: true)
    field(:delete, :boolean, virtual: true)
    field(:fake_id, :integer, virtual: true)
    field(:hash, :string, virtual: true)
    field(:width, :string, virtual: true)
    field(:url, :string, virtual: true)
    belongs_to(:test, Test, type: :binary_id)
    has_many(:pick, Pick)
  end

  def changeset(track, attrs \\ %{}) do
    track
    |> Map.put(:temp_id, track.temp_id || attrs["temp_id"] || nil)
    |> cast(attrs, [:title, :filename, :original_filename, :delete, :temp_id])
    |> validate_required([:title])
    |> maybe_mark_for_deletion()
  end

  defp maybe_mark_for_deletion(changeset) do
    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end
end
