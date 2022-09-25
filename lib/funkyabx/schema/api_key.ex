defmodule FunkyABX.ApiKey do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "api_key" do
    timestamps()
    belongs_to(:user, User)
  end

  def changeset(api_key, attrs \\ %{}) do
    api_key
    |> cast(attrs, [])

    #    |> cast_assoc(:user)
  end
end
