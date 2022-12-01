defmodule FunkyABX.Repo.Migrations.ClosedEnable do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :to_close_at_enabled, :boolean, default: false
    end
  end
end
