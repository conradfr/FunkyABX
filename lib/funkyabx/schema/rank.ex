defmodule FunkyABX.Rank do
  use Ecto.Schema
  alias FunkyABX.Test
  alias FunkyABX.Track

  @primary_key false

  schema "rank" do
    field(:rank, :integer, primary_key: true)
    field(:count, :integer)
    belongs_to(:test, Test, primary_key: true, type: :binary_id)
    belongs_to(:track, Track, primary_key: true, type: :binary_id)
  end
end
