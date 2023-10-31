defmodule FunkyABX.Tests.Type do
  alias Ecto.UUID
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
      rounds
  """
  @callback get_test_params(test :: Test) :: map()

  @doc """
    Can this test type have a have reference track?
  """
  @callback can_have_reference_track?() :: boolean()

  @doc """
    How many times the test has been taken
  """
  @callback get_how_many_taken(test :: Test) :: integer()

  @doc """
    Transform tracks to be used on the test
  """
  @callback prep_tracks(list(), test :: Test) :: list()

  @doc """
    Is the test valid?
  """
  @callback is_valid?(test :: Test, integer(), map()) :: boolean()

  @doc """
    Clean the choices from the user to be saved/stored
  """
  @callback clean_choices(map(), list(), test :: Test) :: map()

  @doc """
    Save the choices of the user
  """
  @callback submit(test :: Test, map(), session_id :: UUID.t(), ip_address :: String.t()) :: any()

  @doc """
    Get results of a specific visitor session
  """
  @callback get_results(test :: Test, session_id :: UUID.t()) :: map()
end
