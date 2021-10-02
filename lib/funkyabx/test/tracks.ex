defmodule FunkyABX.Tracks do
  def to_json(tracks, test) do
    tracks
    |> Enum.map(fn t ->
      %{
        #        id: t.id,
        url: get_media_url(t, test),
        hash: t.hash
      }
    end)
    |> Jason.encode!()
  end

  def get_media_url(track, test) do
    Application.fetch_env!(:funkyabx, :cdn_prefix) <> test.id <> "/" <> track.filename
  end
end
