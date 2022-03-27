defmodule FunkyABX.CustomS3 do
  use Ecto.Schema

  schema "custom_s3" do
    field(:rank, :integer, primary_key: true)
    field(:count, :integer)
    belongs_to(:test, Test, primary_key: true, type: :binary_id)
    belongs_to(:track, Track, primary_key: true, type: :binary_id)
  end
end
