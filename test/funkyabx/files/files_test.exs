defmodule FunkyABX.FilesTest do
  use ExUnit.Case, async: true

  alias FunkyABX.Files

  describe "test get_destination_filename" do
    test "destination has the correct ext mp3" do
      assert Files.get_destination_filename("led_zeppelin.mp3") |> String.ends_with?(".mp3") ===
               true
    end

    test "destination has the correct ext flac" do
      refute Files.get_destination_filename("the_who.flac") |> String.ends_with?(".mp3") === true
    end
  end
end
