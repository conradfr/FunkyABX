defmodule FunkyABX.Files.Local do
  def save(src_path, dest_path) when is_binary(src_path) and is_binary(dest_path) do
    local_dest_path = local_path(dest_path)

    local_dest_path
    |> Path.dirname()
    |> File.mkdir_p()

    File.cp!(src_path, local_dest_path)
  end

  def delete_all(test_id) do
    test_id
    |> local_path()
    |> File.rm_rf()
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
    test_id
    |> local_path()
    |> Path.join([filename])
    |> File.rm()

    filename
  end

  defp local_path(path) when is_binary(path) do
    Path.join([:code.priv_dir(:funkyabx), "static", "uploads", path])
  end
end
