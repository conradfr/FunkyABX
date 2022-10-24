defmodule FunkyABX.Repo.Migrations.DetailsId do
  use Ecto.Migration

  def change do
    alter table("abx_details") do
      add :session_id, :binary_id, null: true
    end

    alter table("identification_details") do
      add :session_id, :binary_id, null: true
    end

    alter table("pick_details") do
      add :session_id, :binary_id, null: true
    end

    alter table("rank_details") do
      add :session_id, :binary_id, null: true
    end

    alter table("star_details") do
      add :session_id, :binary_id, null: true
    end
  end
end
