defmodule FunkyABX.UtilsTest do
  use ExUnit.Case, async: true

  alias FunkyABX.Utils

  describe "get ip address as string" do
    test "get nil when no ip" do
      assert Utils.get_ip_as_binary(nil) == nil
    end

    test "get local ip" do
      assert Utils.get_ip_as_binary({192, 168, 0, 1}) == "192.168.0.1"
    end
  end
end
