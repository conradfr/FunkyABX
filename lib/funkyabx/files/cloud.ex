defmodule FunkyABX.Files.Cloud do
  def save(src_path, dest_path) when is_binary(src_path) and is_binary(dest_path) do
    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.put_object(dest_path, File.read!(src_path), acl: "public-read")
    |> ExAws.request!()
  end

  # Delete all from test
  def delete_all(test_id) do
    stream =
      Application.fetch_env!(:funkyabx, :bucket)
      |> ExAws.S3.list_objects_v2(prefix: test_id)
      |> ExAws.stream!()
      |> Stream.map(& &1.key)

    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.delete_all_objects(stream)
    |> ExAws.request()
  end

  # Delete a file or a list of files
  def delete(filename, test_id)

  def delete(filename, test_id) when is_list(filename) do
    filename
    |> Enum.map(fn file ->
      delete(file, test_id)
      file
    end)
  end

  def delete(filename, test_id) when is_binary(filename) do
    object =
      Application.fetch_env!(:funkyabx, :bucket)
      |> ExAws.S3.list_objects_v2(prefix: test_id)
      |> ExAws.request!()

    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.delete_object(object)
    |> ExAws.request()

    filename
  end
end
