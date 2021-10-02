defmodule FunkyABX.Repo.Migrations.Votes2 do
  use Ecto.Migration

  def change do
    create table(:rank_details) do
      add :votes, :map, default: %{}, null: false
      add :ip_address, :binary
      add :test_id, references("test", type: :binary_id, on_delete: :delete_all)
    end

    create table(:identification_details) do
      add :votes, :map, default: %{}, null: false
      add :ip_address, :binary
      add :test_id, references("test", type: :binary_id, on_delete: :delete_all)
    end
  end
end
