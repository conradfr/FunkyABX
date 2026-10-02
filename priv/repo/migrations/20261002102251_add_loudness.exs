defmodule FunkyABX.Repo.Migrations.AddLoudness do
  use Ecto.Migration

  def change do
    alter table("track") do
      add :loudness, :map, default: nil, null: true
    end
  end
end
