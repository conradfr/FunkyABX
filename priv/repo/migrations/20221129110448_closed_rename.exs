defmodule FunkyABX.Repo.Migrations.ClosedRename do
  use Ecto.Migration

  def change do
    rename table("test"), :to_closed_at, to: :to_close_at
  end
end
