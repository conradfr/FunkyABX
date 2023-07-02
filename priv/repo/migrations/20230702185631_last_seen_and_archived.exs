defmodule FunkyABX.Repo.Migrations.LastSeenAndArchived do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :last_viewed_at, :naive_datetime, null: true
      add :archived, :boolean, null: false, default: false
    end
  end
end
