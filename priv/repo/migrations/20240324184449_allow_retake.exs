defmodule FunkyABX.Repo.Migrations.AllowRetake do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :allow_retake, :boolean, default: false
    end
  end
end
