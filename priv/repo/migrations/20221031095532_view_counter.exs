defmodule FunkyABX.Repo.Migrations.ViewCounter do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :view_count, :integer, default: nil
    end
  end
end
