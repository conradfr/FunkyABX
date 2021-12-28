defmodule FunkyABX.Repo.Migrations.Stars do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :starring, :boolean
    end

    create table(:star, primary_key: false) do
      add :test_id, references("test", on_delete: :delete_all, type: :binary_id),
          primary_key: true,
          null: false

      add :track_id, references("track", on_delete: :delete_all, type: :binary_id),
          primary_key: true,
          null: false

      add :star, :integer, primary_key: true, null: false
      add :count, :integer, null: false
    end

    create table(:star_details) do
      add :stars, :map, default: %{}, null: false
      add :ip_address, :binary
      add :test_id, references("test", type: :binary_id, on_delete: :delete_all)
    end

    execute("CREATE INDEX star_votes ON star_details USING GIN(stars)")
  end
end
