defmodule FunkyABX.Tests.Listening do
  @behaviour FunkyABX.Tests.Type

  # ---------- TEST MODULES ----------

  @impl true
  def get_test_modules(_test) do
    []
  end

  # ---------- CHOICE MODULES ----------

  @impl true
  def get_choices_modules(_test) do
    []
  end

  @impl true
  def get_result_modules(_test) do
    []
  end

  # ---------- PARAMS ----------

  @impl true
  def get_test_params(_test) do
    %{
      has_choices: false
    }
  end

  # ---------- TAKEN ----------

  @impl true
  def get_how_many_taken(_test), do: 0

  # ---------- TRACKS ----------

  @impl true
  def prep_tracks(tracks, _test), do: tracks

  # ---------- FORM ----------

  @impl true
  def is_valid?(_test, _round, _choices), do: true

  # ---------- SAVE ----------

  @impl true
  def clean_choices(choices, _tracks, _test), do: choices

  @impl true
  def submit(_test, _choices, _ip_address), do: :ok
end
