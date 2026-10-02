defmodule FunkyABX.Files do
  @ext_to_flac [".wav"]
  @flac_ext ".flac"
  @wav_sample_rate 48000
  @normalization_target_i -24.0
  @normalization_target_tp -1.0

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
    to_flac = to_flac?(dest_path, normalization)

    {real_src_path, real_dest_path} =
      if to_flac do
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
          # drop embedded cover art
          "-vn",
          "-compression_level",
          "6",
          "-af",
          filter(
            normalization_gain(normalization, src_path),
            output_sample_rate(src_path, dest_path)
          ),
          flac_dest
        ])

        {flac_dest, updated_dest_path}
      else
        {src_path, dest_path}
      end

    Application.fetch_env!(:funkyabx, :file_module)
    |> Kernel.apply(:save, [real_src_path, real_dest_path, opts])

    if to_flac, do: delete_folder_of_file(real_src_path)

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

  # Wav files are always converted, other formats only when they need to be normalized
  defp to_flac?(dest_path, normalization) when is_binary(dest_path) do
    Path.extname(dest_path) in @ext_to_flac or normalization == true
  end

  # Wav files are converted to 48k, other formats keep their original sample rate
  defp output_sample_rate(src_path, dest_path) do
    if Path.extname(dest_path) in @ext_to_flac do
      @wav_sample_rate
    else
      probe_sample_rate(src_path) || @wav_sample_rate
    end
  end

  defp probe_sample_rate(src_path) when is_binary(src_path) do
    case System.cmd("ffprobe", [
           "-v",
           "error",
           "-select_streams",
           "a:0",
           "-show_entries",
           "stream=sample_rate",
           "-of",
           "default=noprint_wrappers=1:nokey=1",
           src_path
         ]) do
      {output, 0} ->
        case Integer.parse(String.trim(output)) do
          {sample_rate, ""} when sample_rate > 0 -> sample_rate
          _ -> nil
        end

      _ ->
        nil
    end
  end

  # Two-pass linear normalization: loudnorm is only used to measure the file,
  # then a constant gain is applied so the dynamics are left untouched.
  # The gain is capped so the true peak never exceeds the target, which means quiet
  # but peaky files can end up below the integrated loudness target.
  defp normalization_gain(true, src_path) when is_binary(src_path) do
    with {:ok, measured_i, measured_tp} <- measure_loudness(src_path) do
      gain =
        min(
          @normalization_target_i - measured_i,
          @normalization_target_tp - measured_tp
        )

      Float.round(gain, 2)
    else
      _ -> nil
    end
  end

  defp normalization_gain(_normalization, _src_path), do: nil

  defp measure_loudness(src_path) when is_binary(src_path) do
    case System.cmd(
           "ffmpeg",
           [
             "-i",
             src_path,
             "-hide_banner",
             "-nostats",
             "-vn",
             "-af",
             "loudnorm=I=#{@normalization_target_i}:TP=#{@normalization_target_tp}:print_format=json",
             "-f",
             "null",
             "-"
           ],
           stderr_to_stdout: true
         ) do
      {output, 0} -> parse_loudnorm_output(output)
      _ -> :error
    end
  end

  # loudnorm prints its measurements as a JSON block at the end of the log
  defp parse_loudnorm_output(output) when is_binary(output) do
    with [_ | _] = blocks <- Regex.scan(~r/\{[^{}]*\}/s, output),
         [json] = List.last(blocks),
         {:ok, %{"input_i" => input_i, "input_tp" => input_tp}} <- Jason.decode(json),
         {measured_i, ""} <- Float.parse(input_i),
         {measured_tp, ""} <- Float.parse(input_tp) do
      {:ok, measured_i, measured_tp}
    else
      _ -> :error
    end
  end

  defp filter(gain, sample_rate) when is_float(gain) do
    "volume=#{gain}dB, aformat=s16:#{sample_rate}"
  end

  defp filter(_gain, sample_rate) do
    "aformat=s16:#{sample_rate}"
  end
end
