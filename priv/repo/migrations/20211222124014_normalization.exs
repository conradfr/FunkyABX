defmodule FunkyABX.Repo.Migrations.Normalization do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :normalization, :boolean, null: false, default: false
    end
  end
end
