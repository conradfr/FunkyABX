defmodule FunkyABX.Repo.Migrations.Votes4 do
  use Ecto.Migration

  def change do
    create table(:identification, primary_key: false) do
      add :test_id, references("test", type: :binary_id, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :track_id, references("track", on_delete: :delete_all, type: :binary_id),
        primary_key: true,
        null: false

      add :track_guessed_id, references("track", type: :binary_id), primary_key: true, null: false
      add :count, :integer, null: false
    end
  end
end
