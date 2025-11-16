defmodule FunkyABX.Repo.Migrations.Comments do
  use Ecto.Migration

  def change do
    create table(:comment) do
      add :author, :string, size: 100
      add :comment, :string, size: 5000
      add :ip_address, :binary

      add :user_id, references("users", on_delete: :delete_all, on_delete: :delete_all),
        null: true

      add :test_id, references("test", type: :binary_id, on_delete: :delete_all), null: false
      timestamps()
    end

    alter table("test") do
      add :email_notification_comments, :boolean, null: false, default: false
      add :allow_comments, :boolean, null: false, default: true
    end
  end
end
