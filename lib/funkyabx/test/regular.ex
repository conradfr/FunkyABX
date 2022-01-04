defmodule FunkyABX.Tests.Regular do
  @behaviour FunkyABX.Tests.Type

  # ---------- TEST MODULES ----------

  @impl true
  def get_test_modules(test) do
    module = get_rating_module(test)
    identification_module = get_identification_module(test)

    module ++ identification_module
  end

  defp get_rating_module(test) when test.rating == false do
    []
  end

  defp get_rating_module(test) do
    test.regular_type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&("Elixir.FunkyABX." <> &1 <> "s")).()
    |> String.to_atom()
    |> List.wrap()
  end

  defp get_identification_module(test) when test.identification == false do
    []
  end

  defp get_identification_module(_test) do
    [FunkyABX.Identifications]
  end

  # ---------- CHOICE MODULES ----------

  @impl true
  def get_choices_modules(test) do
    module = get_rating_choice_module(test)
    identification_module = get_identification_choice_module(test)

    module ++ identification_module
  end

  defp get_rating_choice_module(test) when test.rating == false do
    []
  end

  defp get_rating_choice_module(test) do
    test.regular_type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&("Elixir.FunkyABXWeb.TestTrack" <> &1 <> "Component")).()
    |> String.to_atom()
    |> List.wrap()
  end

  defp get_identification_choice_module(test) when test.identification == false do
    []
  end

  defp get_identification_choice_module(_test) do
    [FunkyABXWeb.TestTrackIdentificationComponent]
  end

  # ---------- RESULT MODULES ----------

  @impl true
  def get_result_modules(test) do
    module = get_rating_result_module(test)
    identification_module = get_identification_result_module(test)

    module ++ identification_module
  end

  defp get_rating_result_module(test) when test.rating == false do
    []
  end

  defp get_rating_result_module(test) do
    test.regular_type
    |> Atom.to_string()
    |> String.capitalize()
    |> (&("Elixir.FunkyABXWeb.TestResult" <> &1 <> "Component")).()
    |> String.to_atom()
    |> List.wrap()
  end

  defp get_identification_result_module(test) when test.identification == false do
    []
  end

  defp get_identification_result_module(_test) do
    [FunkyABXWeb.TestResultIdentificationComponent]
  end

  # ---------- PARAMS ----------

  @impl true
  def get_test_params(_test) do
    %{
      has_choices: true
    }
  end

  # ---------- TAKEN ----------

  @impl true
  def get_how_many_taken(test) do
    test
    |> get_test_modules()
    |> Kernel.hd()
    |> Kernel.apply(:get_how_many_taken, [test])
  end

  # ---------- TRACKS ----------

  @impl true
  def prep_tracks(tracks, _test) do
    Enum.shuffle(tracks)
  end

  # ---------- FORM ----------

  @impl true
  def is_valid?(_test, round, choices) when is_map_key(choices, round) == false, do: false

  @impl true
  def is_valid?(test, round, choices) do
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
  def clean_choices(%{1 => choices} = _all_choices, tracks, test) do
    test
    |> get_test_modules()
    |> Enum.reduce(choices, fn m, acc ->
      Kernel.apply(m, :clean_choices, [acc, tracks, test])
    end)
  end

  @impl true
  def submit(test, choices, ip_address) do
    test
    |> get_test_modules()
    |> Enum.reduce([], fn m, acc ->
      [Kernel.apply(m, :submit, [test, choices, ip_address]) | acc]
    end)
  end
end
