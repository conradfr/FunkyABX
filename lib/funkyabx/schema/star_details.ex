defmodule FunkyABX.StarDetails do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test

  schema "star_details" do
    field(:stars, :map)
    field(:session_id, :binary_id)
    field(:ip_address, :binary)
    belongs_to(:test, Test, type: :binary_id)
  end

  def changeset(star, attrs \\ %{}) do
    star
    |> cast(attrs, [:stars, :ip_address, :session_id])
    #    |> cast_assoc(:test)
    |> validate_required([:stars])
    |> assoc_constraint(:test)
  end
end
