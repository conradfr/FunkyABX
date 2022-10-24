defmodule FunkyABX.Invitation do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Test

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "invitation" do
    field(:name_or_email, :string)
    field(:clicked, :boolean, default: false)
    field(:test_taken, :boolean, default: false)
    belongs_to(:test, Test, type: :binary_id)
  end

  def changeset(invitation, attrs \\ %{}) do
    invitation
    |> cast(attrs, [:id, :name_or_email, :clicked, :test_taken])
    |> put_assoc(:test, attrs.test)
    |> validate_required([:name_or_email])

    #    |> validate_format(:name_or_email, ~r/@/)
  end
end
