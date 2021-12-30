defmodule FunkyABX.Repo.Migrations.TestRefactor do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :regular_type, :integer
      add :rating, :boolean, default: false
    end

    execute("UPDATE test SET regular_type=1 WHERE ranking = TRUE")
    execute("UPDATE test SET regular_type=2 WHERE picking = TRUE")
    execute("UPDATE test SET regular_type=3 WHERE starring = TRUE")
    execute("UPDATE test SET rating=true WHERE regular_type is not null")

    alter table("test") do
      remove :ranking
      remove :picking
      remove :starring
    end
  end
end
