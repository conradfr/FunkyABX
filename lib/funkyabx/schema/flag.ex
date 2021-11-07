defmodule FunkyABX.Flag do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test

  schema "flag" do
    field(:reason, :string)
    belongs_to(:test, Test, type: :binary_id)
    timestamps()
  end

  def changeset(flag, attrs \\ %{}) do
    flag
    |> cast(attrs, [:reason])
    |> validate_required([:reason])
  end
end
