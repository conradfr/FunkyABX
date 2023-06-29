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

  def display(assigns) do
    ~H"""
    <div
      class="p-2"
      phx-click={
        JS.dispatch(
          if @playing do
            "stop"
          else
            "play"
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
      <%= @title %><%= track_index(@track_id, @tracks_order) |> raw() %>
    </div>
    """
  end

  def track_index(track_id, %{} = tracks_order) when is_map_key(tracks_order, track_id) do
    index = Map.get(tracks_order, track_id)

    unless index == nil do
      "&nbsp;<span class=\"text-body-secondary\"><small> - Track #{index}</small></span>"
    end
  end

  def track_index(_, tracks_order), do: nil
end
