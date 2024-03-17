defmodule FunkyABX.Files do
  @ext_to_flac [".wav"]
  @flac_ext ".flac"

  # TODO Move the encoding part to another file

  # ---------- PUBLIC API ----------

  def get_destination_filename_for_local_url(url) when is_binary(url) do
    Base.encode16(:crypto.hash(:sha, url)) <>
      Path.extname(url)
  end

  def get_destination_filename(filename) when is_binary(filename) do
    Integer.to_string(DateTime.to_unix(DateTime.now!("Etc/UTC"))) <>
      "_" <>
      Base.encode16(:crypto.hash(:sha, filename)) <>
      Path.extname(filename)
  end

  def save(src_path, dest_path, opts \\ [], normalization \\ false)
      when is_binary(src_path) and is_binary(dest_path) do
    {real_src_path, real_dest_path} =
      if Path.extname(dest_path) in @ext_to_flac do
        flac_dest = flac_dest(dest_path)
        updated_dest_path = filename_to_flac(dest_path)

        ensure_folder_of_file_exists(flac_dest)

        # System.cmd("flac", ["-4", "--output-name=#{flac_dest}", src_path])
        System.cmd("ffmpeg", [
          "-i",
          src_path,
          "-hide_banner",
          "-loglevel",
          "error",
          "-compression_level",
          "6",
          "-af",
          filter(normalization),
          flac_dest
        ])

        {flac_dest, updated_dest_path}
      else
        {src_path, dest_path}
      end

    Application.fetch_env!(:funkyabx, :file_module)
    |> Kernel.apply(:save, [real_src_path, real_dest_path, opts])

    if Path.extname(dest_path) in @ext_to_flac, do: delete_folder_of_file(real_src_path)

    Path.basename(real_dest_path)
  end

  def exists?(filename) when is_binary(filename) do
    Application.fetch_env!(:funkyabx, :file_module)
    |> Kernel.apply(:exists?, [filename])
  end

  def delete(filename, test_id) when is_binary(filename) or is_list(filename) do
    Application.fetch_env!(:funkyabx, :file_module)
    |> Kernel.apply(:delete, [filename, test_id])
  end

  def delete_all(test_id) do
    Application.fetch_env!(:funkyabx, :file_module)
    |> Kernel.apply(:delete_all, [test_id])
  end

  def is_cached?(path) when is_binary(path) do
    final_path = filename_to_flac_if_needed(path)

    Application.fetch_env!(:funkyabx, :file_module)
    |> Kernel.apply(:is_cached?, [final_path])
  end

  # ---------- INTERNAL ----------

  def filename_to_flac_if_needed(filename) when is_binary(filename) do
    if Path.extname(filename) in @ext_to_flac do
      String.replace_suffix(filename, Path.extname(filename), @flac_ext)
    else
      filename
    end
  end

  defp filename_to_flac(filename) when is_binary(filename) do
    String.replace_suffix(filename, Path.extname(filename), @flac_ext)
  end

  defp ensure_folder_of_file_exists(filepath) when is_binary(filepath) do
    filepath
    |> Path.dirname()
    |> File.mkdir_p()
  end

  defp delete_folder_of_file(filepath) when is_binary(filepath) do
    filepath
    |> Path.dirname()
    |> File.rm_rf()
  end

  defp flac_dest(dest_path) when is_binary(dest_path) do
    Application.fetch_env!(:funkyabx, :flac_folder) <>
      String.replace_suffix(dest_path, Path.extname(dest_path), @flac_ext)
  end

  defp filter(true) do
    "loudnorm=TP=-1, aformat=s16:48000"
  end

  defp filter(_normalization) do
    "aformat=s16:48000"
  end
end
