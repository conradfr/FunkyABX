defmodule FunkyABX.Repo.Migrations.Flag do
  use Ecto.Migration

  def change do
    create table("flag") do
      add :reason, :string, size: 255
      add :test_id, references("test", on_delete: :delete_all, type: :binary_id)
      timestamps()
    end
  end
end
