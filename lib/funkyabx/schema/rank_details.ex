defmodule FunkyABX.RankDetails do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test

  schema "rank_details" do
    field(:votes, :map)
    field(:ip_address, :binary)
    belongs_to(:test, Test, type: :binary_id)
  end

  def changeset(rank, attrs \\ %{}) do
    rank
    |> cast(attrs, [:votes, :ip_address])
    #    |> cast_assoc(:test)
    |> validate_required([:votes])
    |> assoc_constraint(:test)
  end
end
