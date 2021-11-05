defmodule FunkyABX.Repo.Migrations.Votes do
  use Ecto.Migration

  def change do
    create table(:rank, primary_key: false) do
      add :test_id, references("test", type: :binary_id), primary_key: true, null: false

      add :track_id, references("track", on_delete: :delete_all, type: :binary_id),
        primary_key: true,
        null: false

      add :rank, :integer, primary_key: true, null: false
      add :count, :integer, null: false
    end
  end
end
