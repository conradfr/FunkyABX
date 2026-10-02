defmodule FunkyABX.Repo.Migrations.AddNormalizationTracks do
  use Ecto.Migration

  def change do
    alter table("track") do
      add :normalization, :boolean, default: nil, null: true
    end
  end
end
