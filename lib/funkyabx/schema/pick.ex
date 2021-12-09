defmodule FunkyABX.Pick do
  use Ecto.Schema
  alias FunkyABX.Test
  alias FunkyABX.Track

  @primary_key false

  schema "pick" do
    field(:picked, :integer)
    belongs_to(:test, Test, primary_key: true, type: :binary_id)
    belongs_to(:track, Track, primary_key: true, type: :binary_id)
  end
end
