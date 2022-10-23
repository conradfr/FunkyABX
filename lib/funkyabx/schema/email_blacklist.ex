defmodule FunkyABX.EmailBlacklist do
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false

  schema "email_blacklist" do
    field(:email, :string, primary_key: true)
    timestamps()
  end

  def changeset(email_blacklist, attrs \\ %{}) do
    email_blacklist
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
  end
end
