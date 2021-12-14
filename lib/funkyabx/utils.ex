defmodule FunkyABX.Utils do

  @moduledoc false

  def get_ip_as_binary(nil), do: nil

  def get_ip_as_binary(remote_ip) do
    remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
