defmodule FunkyABX.Repo.Migrations.Invitation do
  use Ecto.Migration

  def change do
    create table("invitation", primary_key: false) do
      add :id, :uuid, primary_key: true, autogenerate: false
      add :name_or_email, :string, null: false
      add :clicked, :boolean, default: false
      add :test_taken, :boolean, default: false
      add :test_id, references("test", on_delete: :delete_all, type: :binary_id)
    end

    create unique_index(:invitation, [:name_or_email, :test_id])

    create table("email_list") do
      add :title, :string, null: false
      add :emails, :string, null: false
      add :user_id, references("users", on_delete: :delete_all)
      timestamps()
    end
  end
end
