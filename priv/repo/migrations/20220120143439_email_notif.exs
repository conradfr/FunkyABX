defmodule FunkyABX.Repo.Migrations.EmailNotif do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :email_notification, :boolean, default: false
    end
  end
end
