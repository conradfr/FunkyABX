defmodule FunkyABX.Files do
  alias FunkyABX.Files.Cloud
  alias FunkyABX.Files.Local

  @ext_to_flac [".wav"]
  @flac_ext ".flac"

  # TODO dynamic module instead of if

  # ---------- PUBLIC API ----------

  def get_destination_filename(filename) do
    Integer.to_string(DateTime.to_unix(DateTime.now!("Etc/UTC")))
    <> "_"
    <> Base.encode16(:crypto.hash(:sha, filename))
    <> Path.extname(filename)
  end

  def save(src_path, dest_path) do
    {real_src_path, real_dest_path} =
      if (Path.extname(dest_path) in @ext_to_flac) do
        flac_dest = flac_dest(dest_path)
        updated_dest_path = filename_to_flac(dest_path)

        ensure_folder_of_file_exists(flac_dest)

        System.cmd("flac", ["-4", "--output-name=#{flac_dest}", src_path])

        {flac_dest, updated_dest_path}
      else
        {src_path, dest_path}
      end

    if Application.fetch_env!(:funkyabx, :env) == :dev do
      Local.save(real_src_path, real_dest_path)
    else
      Cloud.save(real_src_path, real_dest_path)
    end

    if (Path.extname(dest_path) in @ext_to_flac), do: delete_folder_of_file(real_src_path)

    Path.basename(real_dest_path)
  end

  def delete(filename, test_id) do
    if Application.fetch_env!(:funkyabx, :env) == :dev do
      Local.delete(filename, test_id)
    else
      Cloud.delete(filename, test_id)
    end
  end

  def delete_all(test_id) do
    if Application.fetch_env!(:funkyabx, :env) == :dev do
      Local.delete_all(test_id)
    else
      Cloud.delete_all(test_id)
    end
  end

  # ---------- INTERNAL ----------

  defp filename_to_flac(filename) do
    String.replace_suffix(filename, Path.extname(filename), @flac_ext)
  end

  defp ensure_folder_of_file_exists(filepath) do
    filepath
    |> Path.dirname()
    |> File.mkdir_p()
  end

  defp delete_folder_of_file(filepath) do
    filepath
    |> Path.dirname()
    |> File.rm_rf()
  end

  defp flac_dest(dest_path) do
    Application.fetch_env!(:funkyabx, :flac_folder)
    <> String.replace_suffix(dest_path, Path.extname(dest_path), @flac_ext)
  end

end
