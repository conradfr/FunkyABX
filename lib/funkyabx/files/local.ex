defmodule FunkyABX.Files.Local do
  @behaviour FunkyABX.Files.Type

  @impl true
  def exists?(filename) when is_binary(filename) do
    Path.join([:code.priv_dir(:funkyabx), "static", "uploads", filename])
    |> File.exists?()
  end

  @impl true
  def save(src_path, dest_path, _opts) when is_binary(src_path) and is_binary(dest_path) do
    local_dest_path = local_path(dest_path)

    local_dest_path
    |> Path.dirname()
    |> File.mkdir_p()

    File.cp!(src_path, local_dest_path)
  end

  @impl true
  def delete_all(test_id) do
    test_id
    |> local_path()
    |> File.rm_rf()
  end

  # Delete a file or a list of files
  @impl true
  def delete(filename, test_id)

  @impl true
  def delete(filename, test_id) when is_list(filename) do
    filename
    |> Enum.map(fn file ->
      delete(file, test_id)
      file
    end)
  end

  @impl true
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
