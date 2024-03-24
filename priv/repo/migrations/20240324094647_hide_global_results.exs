defmodule FunkyABX.Repo.Migrations.HideGlobalResults do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :hide_global_results, :boolean, default: false
    end
  end
end
