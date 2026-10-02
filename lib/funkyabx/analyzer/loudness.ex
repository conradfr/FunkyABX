defmodule FunkyABX.Analyzer.Loudness do
  require Logger

  # EBU R128 measurement done with ffmpeg's loudnorm filter (analysis only, nothing is written).
  # Stored values:
  # - integrated: integrated loudness (LUFS)
  # - true_peak: true peak (dBTP)
  # - lra: loudness range (LU)
  # - threshold: relative gating threshold (LUFS)
  # A value is nil when it can't be measured (e.g. "-inf" for a silent file).

  @fields %{
    "input_i" => "integrated",
    "input_tp" => "true_peak",
    "input_lra" => "lra",
    "input_thresh" => "threshold"
  }

  # ---------- PUBLIC API ----------

  def analyze(path) when is_binary(path) do
    case System.cmd(
           "ffmpeg",
           [
             "-hide_banner",
             "-nostats",
             "-i",
             path,
             "-vn",
             "-af",
             "loudnorm=print_format=json",
             "-f",
             "null",
             "-"
           ],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        parse(output, path)

      {output, status} ->
        Logger.warning("Loudness analysis failed (#{status}) for #{path}: #{output}")
        nil
    end
  rescue
    e ->
      Logger.warning("Loudness analysis error for #{path}: #{Exception.message(e)}")
      nil
  end

  # ---------- INTERNAL ----------

  # loudnorm prints its json report at the end of ffmpeg's output
  defp parse(output, path) do
    with [json | _] <- ~r/\{[^{}]*\}/s |> Regex.scan(output) |> List.last([]),
         {:ok, report} <- Jason.decode(json) do
      Map.new(@fields, fn {report_key, key} -> {key, to_float(report[report_key])} end)
    else
      _ ->
        Logger.warning("Loudness analysis: no report found for #{path}")
        nil
    end
  end

  # loudnorm returns numbers as strings, and "-inf" / "inf" when not measurable
  defp to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> float
      _ -> nil
    end
  end

  defp to_float(value) when is_number(value), do: value / 1
  defp to_float(_value), do: nil
end
