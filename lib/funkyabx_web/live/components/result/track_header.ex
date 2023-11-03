defmodule TestResultTrackHeaderComponent do
  use Phoenix.Component
  use Phoenix.HTML

  alias Phoenix.LiveView.JS
  alias FunkyABX.{Test, Tracks}

  attr :test, Test, required: true
  attr :track_id, :string, required: true
  attr :playing, :boolean, required: true
  attr :rank, :integer, required: true
  attr :title, :string, required: true
  attr :trophy, :boolean, required: false, default: true
  attr :tracks_order, :any, required: false, default: nil
  attr :is_reference_track, :boolean, required: false, default: false

  def display(assigns) do
    ~H"""
    <div
      class="p-2"
      phx-click={
        JS.dispatch(
          if @playing do
            "stop_result"
          else
            "play_result"
          end,
          to: "body",
          detail: %{
            "test_id" => @test.id,
            "test_local" => @test.local,
            "track_id" => @track_id,
            "track_url" => Tracks.get_track_url(@track_id, @test)
          }
        )
      }
    >
      <button type="button" class="btn btn-dark px-2">
        <%= if @playing do %>
          <i class="bi bi-stop-fill"></i>
        <% else %>
          <i class="bi bi-play-fill"></i>
        <% end %>
      </button>
    </div>
    <div :if={@trophy} class="p-2">
      <%= if (@rank < 4) do %>
        <i class={"bi bi-trophy-fill trophy-#{@rank}"}></i>
      <% else %>
        #<%= @rank %>
      <% end %>
    </div>
    <div class="p-2 flex-grow-1 text-truncate cursor-link">
      <%= @title %>
      <span :if={@is_reference_track == false} class="text-body-secondary">
        <%= track_index(@track_id, @tracks_order) |> raw() %>
      </span>
      <span :if={@is_reference_track == true} class="text-body-secondary">
        <small> - Reference track</small>
      </span>
    </div>
    """
  end

  defp track_index(track_id, %{} = tracks_order) when is_map_key(tracks_order, track_id) do
    IO.puts "##################################################"
    IO.puts "#{inspect tracks_order}"
    index = Map.get(tracks_order, track_id)

    unless index == nil do
      "<small> - Track #{index}</small>"
    end
  end

  defp track_index(_, _tracks_order), do: nil
end
