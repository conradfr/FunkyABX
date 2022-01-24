defmodule FunkyABX.Contact do
  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:email, :string)
    field(:message, :string)
  end

  def changeset(contact, attrs \\ %{}) do
    contact
    |> cast(attrs, [:name, :email, :message])
    |> validate_required([:name, :message])
  end
end
