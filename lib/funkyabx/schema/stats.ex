defmodule FunkyABX.Stats do
  use Ecto.Schema

  @primary_key false

  schema "stats" do
    field(:name, :string, primary_key: true)
    field(:counter, :integer)
  end
end
