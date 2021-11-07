defmodule FunkyABX.Account do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Accounts.User

  schema "account" do
    field :role, Ecto.Enum, values: [:god, :premium, :user]
    belongs_to(:user, User)
  end

  def changeset(account, attrs \\ %{}) do
    account
    |> cast(attrs, [
      :role
    ])
    |> cast_assoc(:user)
  end
end
