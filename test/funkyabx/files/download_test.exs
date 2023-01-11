defmodule FunkyABX.DownloadTest do
  use ExUnit.Case, async: true

  alias FunkyABX.Download

  describe "dropbox urls" do
    test "not dropbox url is unchanged" do
      url = "https://www.whatever.com/files.mp3"
      assert Download.filter(url) === url
    end

    test "dropbox url with dl=1 is unchanged" do
      url = "https://www.dropbox.com/s/great_id/great_file.wav?dl=1"
      assert Download.filter(url) === url
    end

    test "dropbox url with dl=0 is changed" do
      url = "https://www.dropbox.com/s/great_id/great_file.wav?dl=0"
      assert Download.filter(url) === "https://www.dropbox.com/s/great_id/great_file.wav?dl=1"
    end

    test "dropbox url with no dl but ? is change accordingly" do
      url = "https://www.dropbox.com/s/great_id/great_file.wav?t=test"

      assert Download.filter(url) ===
               "https://www.dropbox.com/s/great_id/great_file.wav?t=test&dl=1"
    end

    test "dropbox url with no dl and no ? is change accordingly" do
      url = "https://www.dropbox.com/s/great_id/great_file.wav"
      assert Download.filter(url) === "https://www.dropbox.com/s/great_id/great_file.wav?dl=1"
    end
  end
end
