defmodule FunkyABX.Repo.Migrations.UserApiKey do
  use Ecto.Migration

  def change do
    create table("api_key", primary_key: false) do
      add :id, :uuid, primary_key: true, autogenerate: true
      add :user_id, references("users", on_delete: :delete_all), null: false
      timestamps()
    end
  end
end
