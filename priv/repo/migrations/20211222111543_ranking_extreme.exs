defmodule FunkyABX.Repo.Migrations.RankingExtreme do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :ranking_only_extremities, :boolean, null: false, default: false
    end
  end
end
