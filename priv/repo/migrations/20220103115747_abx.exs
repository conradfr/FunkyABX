defmodule FunkyABX.Repo.Migrations.Abx do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :nb_of_rounds, :integer, default: 1
      add :anonymized_track_title, :boolean, default: true
    end

    create table(:abx, primary_key: false) do
      add :test_id, references("test", on_delete: :delete_all, type: :binary_id),
        primary_key: true,
        null: false

      add :correct, :integer, primary_key: true, null: false
      add :count, :integer, null: false
    end

    create table(:abx_details) do
      add :rounds, :map, default: %{}, null: false
      add :ip_address, :binary
      add :test_id, references("test", type: :binary_id, on_delete: :delete_all)
    end

    execute("UPDATE test SET anonymized_track_title=FALSE WHERE type = 3")
  end
end
