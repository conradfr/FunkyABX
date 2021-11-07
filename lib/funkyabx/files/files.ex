defmodule FunkyABX.Files do
  alias FunkyABX.Files.Cloud

  def get_destination_filename(filename) do
    Integer.to_string(DateTime.to_unix(DateTime.now!("Etc/UTC")))
    <> "_"
    <> Base.encode16(:crypto.hash(:sha, filename))
    <> Path.extname(filename)
  end

  def upload(src_path, dest_path) do
    Cloud.upload(src_path, dest_path)
  end

  def delete(filename, test_id) do
    Cloud.delete(filename, test_id)
  end

  def delete_all(test_id) do
    Cloud.delete_all(test_id)
  end

end
