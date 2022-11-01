defmodule FunkyABX.Factory do
  use ExMachina.Ecto, repo: FunkyABX.Repo

  def test_factory do
    %FunkyABX.Test{
      id: Ecto.UUID.generate(),
      title: "Test title",
      slug: "slug",
      type: :regular,
      regular_type: :pick,
      identification: false,
      tracks: []
    }
  end

  def track_factory do
    %FunkyABX.Track{
      title: sequence(:email, &"Track #{&1} Title"),
      filename: sequence(:filename, &"filename_#{&1}.mp3"),
      original_filename: sequence(:original_filename, &"original_filename_#{&1}.mp3")
    }
  end

end
