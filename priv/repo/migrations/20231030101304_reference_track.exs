defmodule FunkyABX.Repo.Migrations.ReferenceTrack do
  use Ecto.Migration

  def change do
    alter table("track") do
      add :reference_track, :boolean, default: false
    end
  end
end
