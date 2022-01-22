defmodule FunkyABX.Repo.Migrations.Password2 do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :password_enabled, :boolean, default: false
      add :password_length, :integer, null: true
    end
  end
end
