defmodule FunkyABX.Tests.FormUtils do
  alias FunkyABX.Tests

  # ---------- TEST PARAMS ----------

  def update_test_params("ranking", %{"ranking" => ranking} = test_params)
      when ranking == "true" do
    test_params
    |> Map.put("picking", false)
    |> Map.put("starring", false)
  end

  def update_test_params("picking", %{"picking" => picking} = test_params)
      when picking == "true" do
    test_params
    |> Map.put("ranking", false)
    |> Map.put("starring", false)
  end

  def update_test_params("starring", %{"starring" => starring} = test_params)
      when starring == "true" do
    test_params
    |> Map.put("ranking", false)
    |> Map.put("picking", false)
  end

  def update_test_params(_target, test_params), do: test_params

  # ---------- REFERENCE TRACK PARAMS ----------

  def update_reference_track_params(test_params, target) when is_list(target) do
    case List.last(target) do
      "type" ->
        case Map.get(test_params, "type") |> Tests.can_have_reference_track?() do
          false ->
            # ensure no reference track
            tracks_updated =
              test_params
              |> Map.get("tracks", %{})
              |> Map.new(fn {k, v} -> {k, Map.put(v, "reference_track", "false")} end)

            Map.put(test_params, "tracks", tracks_updated)

          _ ->
            test_params
        end

      "reference_track" ->
        track_number = Enum.at(target, 2)

        case Map.get(test_params["tracks"][track_number], "reference_track") do
          "true" ->
            # ensure it's the only one selected
            tracks_updated =
              test_params
              |> Map.get("tracks", %{})
              |> Map.new(fn
                {k, v} when k == track_number -> {track_number, v}
                {k, v} -> {k, Map.put(v, "reference_track", "false")}
              end)

            Map.put(test_params, "tracks", tracks_updated)

          _ ->
            test_params
        end

      _ ->
        test_params
    end
  end

  # ---------- TRACKS POSITION ----------

  # Tracks params come as a map indexed by form position ("0", "1", ... "10")
  # or as a list once processed. Sets each track position to its order in the form.
  def put_tracks_position(%{"tracks" => tracks} = test_params)
      when is_map(tracks) or is_list(tracks) do
    tracks_with_position =
      tracks
      |> sorted_tracks_params()
      |> Enum.with_index()
      |> Enum.map(fn {track, index} -> Map.put(track, "position", index) end)

    Map.put(test_params, "tracks", tracks_with_position)
  end

  def put_tracks_position(test_params), do: test_params

  # Map keys are strings so "10" would be before "2" when iterating
  def sorted_tracks_params(tracks) when is_map(tracks) do
    tracks
    |> Enum.sort_by(fn {k, _t} -> params_index(k) end)
    |> Enum.map(fn {_k, t} -> t end)
  end

  def sorted_tracks_params(tracks) when is_list(tracks), do: tracks

  defp params_index(key) when is_binary(key) do
    case Integer.parse(key) do
      {index, ""} -> index
      _ -> key
    end
  end

  defp params_index(key), do: key
end
