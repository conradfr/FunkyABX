defmodule FunkyABX.Tracks do
  # ---------- EXPORT ----------

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

  # ---------- UTILS ----------

  def prep_tracks(tracks, _test) do
    tracks
    |> Enum.map(&prep_track/1)
  end

  def prep_track(track) do
    fake_id = :rand.uniform(1_000_000)

    %{
      track
      | fake_id: fake_id,
        hash: get_track_hash(track, fake_id)
    }
  end

  def get_track_hash(track, fake_id \\ nil) do
    track_fake_id = Map.get(track, :fake_id) || fake_id

    :md5
    |> :crypto.hash(track.id <> track.filename <> Integer.to_string(track_fake_id))
    |> Base.encode16()
  end

  def get_track_url(track_id, test) do
    track_id
    |> find_track(test.tracks)
    |> get_media_url(test)
  end

  def get_media_url(track, test) do
    Application.fetch_env!(:funkyabx, :cdn_prefix) <> test.id <> "/" <> track.filename
  end

  def find_track(track_id, tracks) do
    Enum.find(tracks, fn t ->
      t.id == track_id
    end)
  end

  def find_track_id_from_fake_id(fake_id, tracks) do
    tracks
    |> Enum.find(fn x -> x.fake_id == fake_id end)
    |> Map.get(:id)
  end

  def find_fake_id_from_track_id(track_id, tracks) do
    tracks
    |> Enum.find(fn x -> x.id == track_id end)
    |> Map.get(:fake_id)
  end
end
