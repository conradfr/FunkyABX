defmodule FunkyABX.Comment do
  import Ecto.Changeset
  use Ecto.Schema
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test
  alias __MODULE__

  schema "comment" do
    field(:author, :string)
    field(:comment, :string)
    field(:ip_address, :binary)
    belongs_to(:user, User)
    belongs_to(:test, Test, type: :binary_id)
    timestamps()
  end

  def new(params \\ %{}) do
    %Comment{
      author: Map.get(params, :author, ""),
      comment: "",
      test: params.test,
      ip_address: params.ip_address,
      user: Map.get(params, :user)
    }
  end

  def changeset(comment, attrs \\ %{}) do
    comment
    |> cast(attrs, [:author, :comment, :ip_address])
    |> validate_required([:author, :comment, :ip_address])
    |> cast_assoc(:user)
    |> assoc_constraint(:test)
  end
end
