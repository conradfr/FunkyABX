defmodule FunkyABX.PickDetails do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test
  alias FunkyABX.Track

  schema "pick_details" do
    field(:ip_address, :binary)
    belongs_to(:track, Track, type: :binary_id)
    belongs_to(:test, Test, type: :binary_id)
  end

  def changeset(rank, attrs \\ %{}) do
    rank
    |> cast(attrs, [:ip_address])
#    |> cast_assoc(:test)
    |> assoc_constraint(:test)
    |> assoc_constraint(:track)
  end
end
