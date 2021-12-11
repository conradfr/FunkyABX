defmodule FunkyABX.Repo.Migrations.AddChooseBest do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :picking, :boolean
    end

    create table(:pick, primary_key: false) do
      add :test_id, references("test", on_delete: :delete_all, type: :binary_id),
        primary_key: true,
        null: false

      add :track_id, references("track", on_delete: :delete_all, type: :binary_id),
        primary_key: true,
        null: false

      add :picked, :integer, null: false
    end

    create table(:pick_details) do
      add :track_id, references("track", on_delete: :delete_all, type: :binary_id),
        primary_key: true,
        null: false

      add :ip_address, :binary
      add :test_id, references("test", type: :binary_id, on_delete: :delete_all)
    end
  end
end
