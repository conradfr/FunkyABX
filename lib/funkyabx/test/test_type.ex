defmodule FunkyABX.Tests.Type do
  alias FunkyABX.Test

  @doc """
    List of sub type modules the test uses
  """
  @callback get_test_modules(test :: Test) :: list()

  @doc """
    List of rating/guess modules the test uses
  """
  @callback get_choices_modules(test :: Test) :: list()

  @doc """
    List of result modules the test uses
  """
  @callback get_result_modules(test :: Test) :: list()

  @doc """
    Test params:
      has_choices
      display_track_titles
      shuffle_tracks
  """
  @callback get_test_params(test :: Test) :: map()

  @doc """
    Is the test valid?
  """
  @callback is_valid?(test :: Test, map()) :: boolean()

  @doc """
    Clean the choices from the user to be saved/stored
  """
  @callback clean_choices(map(), list(), test :: Test) :: map()

  @doc """
    Save the choices of the user
  """
  @callback submit(test :: Test, map(), String.t()) :: any()
end
