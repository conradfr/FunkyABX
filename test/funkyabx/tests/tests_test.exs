defmodule FunkyABX.TestsTest do
  use ExUnit.Case, async: true

  alias FunkyABX.Tests

  describe "test assign_new" do
    test "return the default for no choices" do
      assert Tests.assign_new(%{}, 1, :test) === %{}
    end

    test "return a specified default for no choices" do
      assert Tests.assign_new(%{}, 1, :test, "default") === "default"
    end

    test "return a specified default for no round data" do
      assert Tests.assign_new(%{1 => %{test: "rocknroll"}}, 2, :test, "default") === "default"
    end

    test "return the key value" do
      assert Tests.assign_new(%{1 => %{test: "rocknroll"}}, 1, :test) === "rocknroll"
    end
  end
end
