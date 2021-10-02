defmodule FunkyABX.Repo.Migrations.Account do
  use Ecto.Migration

  def change do
    create table("account") do
      add :role, :string, size: 50
      add :user_id, references("users", on_delete: :delete_all)
    end
  end
end
