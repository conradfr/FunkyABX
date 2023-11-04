defmodule FunkyABXWeb.TestTrackRankComponent do
  use FunkyABXWeb, :live_component

  alias FunkyABX.Tests

  @impl true
  def render(assigns) do
    assigns =
      assign_new(assigns, :ranked, fn ->
        Tests.assign_new(assigns.choices_taken, assigns.round, :rank)
      end)

    ~H"""
    <div class="p-2 d-flex flex-row align-items-center flex-grow-1 flex-md-grow-0">
      <div class="me-auto flex-grow-1 flex-md-grow-0">
        <span class="me-3 text-body-secondary small">
          <%= dgettext("test", "I rank this track ...") %>
        </span>
      </div>
      <div class=" p-0 p-md-3 flex-fill">
        <form phx-change="change_ranking" phx-target={@myself}>
          <input name="track[id]" type="hidden" value={@track.id} />
          <select class="form-select" name="rank" disabled={@test_already_taken == true}>
            <%= options_for_select(ranking_choices(@test), Map.get(@ranked, @track.id, "")) %>
          </select>
        </form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "change_ranking",
        _ranking_params,
        %{assigns: %{test_already_taken: true}} = socket
      ),
      do: {:noreply, socket}

  @impl true
  def handle_event(
        "change_ranking",
        %{"track" => %{"id" => track_id}, "rank" => rank} = _ranking_params,
        socket
      ) do
    ranked =
      socket.assigns.choices_taken
      |> Map.get(socket.assigns.round, %{})
      |> Map.get(:rank, %{})

    ranking_updated =
      case rank do
        rank when rank == "" ->
          Map.delete(ranked, track_id)

        rank ->
          new_rank = String.to_integer(rank)

          ranked
          |> Enum.find(nil, fn {_, value} -> value == new_rank end)
          |> case do
            nil ->
              ranked

            {key, _} ->
              Map.delete(ranked, key)
          end
          |> Map.put(track_id, new_rank)
      end

    send(self(), {:update_choices_taken, socket.assigns.round, %{rank: ranking_updated}})
    {:noreply, socket}
  end

  def ranking_choices(test) when test.ranking_only_extremities == true do
    nb_tracks = Tests.tracks_count(test)
    ["", Best: [1, 2, 3], Worst: [nb_tracks - 2, nb_tracks - 1, nb_tracks]]
  end

  def ranking_choices(test) do
    track_count =
      test
      |> Map.get(:tracks, [])
      |> Tests.filter_reference_track()
      |> Kernel.length()

    [""] ++ Enum.to_list(1..track_count)
  end
end
