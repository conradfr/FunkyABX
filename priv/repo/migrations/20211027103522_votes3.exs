defmodule FunkyABX.Repo.Migrations.Votes3 do
  use Ecto.Migration

  def up do
    execute("CREATE INDEX rank_votes ON rank_details USING GIN(votes)")
    execute("CREATE INDEX identification_votes ON identification_details USING GIN(votes)")
  end
end
