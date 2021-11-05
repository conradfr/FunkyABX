defmodule FunkyABX.Tracks do
  alias FunkyABX.Test
  alias FunkyABX.Track

  def to_json(tracks, test) do
    tracks
    |> Enum.map(fn t ->
      %{
#        id: t.id,
        url: Application.fetch_env!(:funkyabx, :cdn_prefix) <> test.id <> "/" <> t.filename,
        hash: t.hash
      }
      end
    )
    |> Jason.encode!()
  end
end
