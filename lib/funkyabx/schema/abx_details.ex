defmodule FunkyABX.AbxDetails do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test

  schema "abx_details" do
    field(:rounds, :map)
    field(:session_id, :binary_id)
    field(:ip_address, :binary)
    belongs_to(:test, Test, type: :binary_id)
  end

  def changeset(abx, attrs \\ %{}) do
    abx
    |> cast(attrs, [:rounds, :ip_address, :session_id])
    #    |> cast_assoc(:test)
    |> validate_required([:rounds])
    |> assoc_constraint(:test)
  end
end
