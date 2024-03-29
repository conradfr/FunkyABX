defmodule FunkyABX.Tests.Regular do
  alias FunkyABX.Test

  @behaviour FunkyABX.Tests.Type

  # ---------- TEST MODULES ----------

  @impl true
  def get_test_modules(%Test{} = test) do
    module = get_rating_module(test)
    identification_module = get_identification_module(test)

    module ++ identification_module
  end

  defp get_rating_module(%Test{} = test) when test.rating == false do
    []
  end

  defp get_rating_module(%Test{} = test) do
    test.regular_type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&("Elixir.FunkyABX." <> &1 <> "s")).()
    |> String.to_atom()
    |> List.wrap()
  end

  defp get_identification_module(%Test{} = test) when test.identification == false do
    []
  end

  defp get_identification_module(_test) do
    [FunkyABX.Identifications]
  end

  # ---------- CHOICE MODULES ----------

  @impl true
  def get_choices_modules(%Test{} = test) do
    module = get_rating_choice_module(test)
    identification_module = get_identification_choice_module(test)

    module ++ identification_module
  end

  defp get_rating_choice_module(%Test{} = test) when test.rating == false do
    []
  end

  defp get_rating_choice_module(%Test{} = test) do
    test.regular_type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&("Elixir.FunkyABXWeb.TestTrack" <> &1 <> "Component")).()
    |> String.to_atom()
    |> List.wrap()
  end

  defp get_identification_choice_module(%Test{} = test) when test.identification == false do
    []
  end

  defp get_identification_choice_module(_test) do
    [FunkyABXWeb.TestTrackIdentificationComponent]
  end

  # ---------- RESULT MODULES ----------

  @impl true
  def get_result_modules(%Test{} = test) do
    module = get_rating_result_module(test)
    identification_module = get_identification_result_module(test)

    module ++ identification_module
  end

  defp get_rating_result_module(%Test{} = test) when test.rating == false do
    []
  end

  defp get_rating_result_module(%Test{} = test) do
    test.regular_type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&("Elixir.FunkyABXWeb.TestResult" <> &1 <> "Component")).()
    |> String.to_atom()
    |> List.wrap()
  end

  defp get_identification_result_module(%Test{} = test) when test.identification == false do
    []
  end

  defp get_identification_result_module(_test) do
    [FunkyABXWeb.TestResultIdentificationComponent]
  end

  # ---------- PARAMS ----------

  @impl true
  def get_test_params(_test) do
    %{
      has_choices: true,
      draw_waveform: true
    }
  end

  @impl true
  def can_have_reference_track?(), do: true

  @impl true
  def can_have_player_on_results_page?(), do: true

  # ---------- TAKEN ----------

  @impl true
  def get_how_many_taken(%Test{} = test) do
    test
    |> get_test_modules()
    |> Kernel.hd()
    |> Kernel.apply(:get_how_many_taken, [test])
  end

  # ---------- TRACKS ----------

  def prep_tracks(tracks, test, tracks_order \\ nil)

  # from results page, sort the tracks to what they were in the test page
  @impl true
  def prep_tracks(tracks, _test, tracks_order) when is_list(tracks) and is_map(tracks_order) do
    tracks
    |> Enum.filter(fn t -> t.reference_track == false end)
    |> Enum.sort_by(&Map.fetch(tracks_order, &1.id), :asc)
    |> maybe_add_reference_track(tracks)
  end

  @impl true
  def prep_tracks(tracks, _test, _tracks_order) when is_list(tracks) do
    tracks
    |> Enum.filter(fn t -> t.reference_track == false end)
    |> Enum.shuffle()
    |> maybe_add_reference_track(tracks)
  end

  # add reference track at the top if any
  defp maybe_add_reference_track(processed_tracks, tracks) do
    if length(processed_tracks) < length(tracks) do
      reference_track = Enum.find(tracks, fn t -> t.reference_track == true end)
      [reference_track | processed_tracks]
    else
      processed_tracks
    end
  end

  # ---------- FORM ----------

  @impl true
  def is_valid?(_test, round, choices) when is_map_key(choices, round) == false, do: false

  @impl true
  def is_valid?(%Test{} = test, round, choices) do
    test
    |> get_test_modules()
    |> Enum.reduce([], fn m, acc ->
      [Kernel.apply(m, :is_valid?, [test, round, choices]) | acc]
    end)
    |> Enum.all?()
  end

  # ---------- SAVE ----------

  # Current assumption here and for all "regular" test code is that there is only one round

  @impl true
  def clean_choices(%{1 => choices} = _all_choices, tracks, %Test{} = test) do
    test
    |> get_test_modules()
    |> Enum.reduce(choices, fn m, acc ->
      Kernel.apply(m, :clean_choices, [acc, tracks, test])
    end)
  end

  @impl true
  def submit(%Test{} = test, choices, session_id, ip_address) do
    test
    |> get_test_modules()
    |> Enum.reduce([], fn m, acc ->
      [Kernel.apply(m, :submit, [test, choices, session_id, ip_address]) | acc]
    end)
  end

  # ---------- RESULTS ----------

  # not used, submodules are accessed directly

  @impl true
  def get_results(_test, _session_id), do: %{}
end
