defmodule FunkyABX.IdentificationDetails do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test

  schema "identification_details" do
    field(:votes, :map)
    field(:ip_address, :binary)
    belongs_to(:test, Test, type: :binary_id)
  end

  def changeset(identification, attrs \\ %{}) do
    identification
    |> cast(attrs, [:votes, :ip_address])
    |> validate_required([:votes])
    |> assoc_constraint(:test)
  end
end
