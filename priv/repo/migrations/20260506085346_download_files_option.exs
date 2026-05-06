defmodule FunkyABX.Repo.Migrations.DownloadFilesOption do
  use Ecto.Migration

  def change do
    alter table("test") do
      add :allow_download_files, :boolean, default: false
      add :download_files_counter, :integer, default: 0
    end
  end
end
