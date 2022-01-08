defmodule FunkyABX.Test.TitleSlugTest do
  use ExUnit.Case, async: true
  import Mock

  alias FunkyABX.Test
  alias FunkyABX.Repo

  @valid_attrs %{
    title: "The title",
    public: false,
    type: 3,
    nb_of_rounds: 1,
    tracks: [%{}, %{}]
  }

  describe "test slug" do
    test "return the slug with no incremented number" do
      with_mock Repo, one: fn _query -> 0 end do
        test = Test.changeset(%Test{}, @valid_attrs)
        assert test.changes.slug == "the-title"
      end
    end

    test "return the slug with incremented number" do
      with_mock Repo, one: fn _query -> 2 end do
        test = Test.changeset(%Test{}, @valid_attrs)
        assert test.changes.slug == "the-title-3"
      end
    end
  end
end
