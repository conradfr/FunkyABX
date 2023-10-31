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
end
