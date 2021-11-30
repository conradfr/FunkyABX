defmodule FunkyABX.Repo.Migrations.MoreFields do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :to_closed_at, :naive_datetime, null: true
      add :closed_at, :naive_datetime, null: true
      add :deleted_at, :naive_datetime, null: true
    end

    alter table("track") do
      add :description, :string, size: 200, null: true
      add :url, :string, size: 500, null: true
    end
  end
end
