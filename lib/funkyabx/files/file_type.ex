defmodule FunkyABX.Files.Type do
  @callback exists?(filename :: String.t()) :: boolean()

  @callback save(String.t(), String.t(), list()) :: :ok

  @callback delete_all(test_id :: String.t()) :: any()

  @callback delete(filename :: String.t() | list(), test_id :: String.t()) :: any()

  @callback is_cached?(path :: String.t()) :: boolean()
end
