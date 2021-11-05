defmodule FunkyABX.Repo.Migrations.Init do
  use Ecto.Migration

  def change do
    create table("test", primary_key: false) do
      add :id, :uuid, primary_key: true, autogenerate: false
      add :title, :string, size: 255, null: false
      add :author, :string, size: 100
      add :description, :string, size: 2000
      add :slug, :string, size: 255, null: false
      add :public, :boolean, default: true
      add :password, :string, size: 255, null: false
      add :ranking, :boolean
      add :identification, :boolean
      add :type, :integer, null: false
      add :ip_address, :binary
      timestamps()
    end

    create unique_index("test", [:slug])

    create table("track", primary_key: false) do
      add :id, :uuid, primary_key: true, autogenerate: true
      add :filename, :string, null: false
      add :original_filename, :string, null: false
      add :title, :string, null: false
      add :test_id, references("test", on_delete: :delete_all, type: :binary_id)
    end
  end
end
