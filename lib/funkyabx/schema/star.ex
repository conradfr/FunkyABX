defmodule FunkyABX.Star do
  use Ecto.Schema
  alias FunkyABX.Test
  alias FunkyABX.Track

  @primary_key false

  schema "star" do
    field(:star, :integer, primary_key: true)
    field(:count, :integer)
    belongs_to(:test, Test, primary_key: true, type: :binary_id)
    belongs_to(:track, Track, primary_key: true, type: :binary_id)
  end
end
