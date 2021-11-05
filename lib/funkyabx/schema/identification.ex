defmodule FunkyABX.Identification do
  use Ecto.Schema
  alias FunkyABX.Test
  alias FunkyABX.Track

  @primary_key false

  schema "identification" do
    field(:count, :integer)
    belongs_to(:test, Test, primary_key: true, type: :binary_id)
    belongs_to(:track, Track, primary_key: true, type: :binary_id)
    belongs_to(:track_guessed, Track, primary_key: true, type: :binary_id)
  end
end
