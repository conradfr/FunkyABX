defmodule FunkyABX.Abx do
  use Ecto.Schema
  alias FunkyABX.Test

  @primary_key false

  schema "abx" do
    field(:correct, :integer, primary_key: true)
    field(:count, :integer)
    belongs_to(:test, Test, primary_key: true, type: :binary_id)
  end
end
