defmodule FunkyABX.Repo.Migrations.Stats do
  use Ecto.Migration

  def change do
    create table(:stats, primary_key: false) do
      add :name, :string, primary_key: true, null: false
      add :counter, :integer, default: 0, null: false
    end
  end
end
