defmodule FunkyABX.TestsTest do
  use ExUnit.Case, async: true
  import FunkyABX.Factory

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

    test "get test modules with one test type" do
      test = build(:test, tracks: [])
      assert length(Tests.get_test_modules(test)) == 1
      assert hd(Tests.get_test_modules(test)) == FunkyABX.Picks

      assert length(Tests.get_choices_modules(test)) == 1
      assert hd(Tests.get_choices_modules(test)) == FunkyABXWeb.TestTrackPickComponent
    end

    test "get test modules with two test types" do
      test = build(:test, regular_type: :star, identification: true, tracks: [])

      assert length(Tests.get_test_modules(test)) == 2
      assert hd(Tests.get_test_modules(test)) == FunkyABX.Stars

      assert length(Tests.get_choices_modules(test)) == 2
      assert hd(Tests.get_choices_modules(test)) == FunkyABXWeb.TestTrackStarComponent
    end
  end
end
