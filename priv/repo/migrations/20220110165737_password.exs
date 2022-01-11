defmodule FunkyABX.Repo.Migrations.Password do
  use Ecto.Migration

  def change do
    rename table("test"), :password, to: :access_key

    alter table("test") do
      add :password, :string, size: 255, null: true
    end
  end
end
