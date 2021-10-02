defmodule FunkyABX.Repo.Migrations.UserTest do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :user_id, references("users", on_delete: :delete_all)
    end
  end
end
