defmodule FunkyABXWeb.TestTrackIdentificationComponent do
  use FunkyABXWeb, :live_component

  alias FunkyABX.Tests
  alias FunkyABX.Tracks

  @impl true
  def render(assigns) do
    assigns =
      assign_new(assigns, :identified, fn ->
        Tests.assign_new(assigns.choices_taken, assigns.round, :identification)
      end)

    ~H"""
    <div class="p-2 d-flex flex-row align-items-center flex-grow-1 flex-md-grow-0">
      <div class="me-auto ms-0 ms-md-3 flex-fill text-start text-md-end">
        <span class="me-2 text-body-secondary small">
          <%= dgettext("test", "I think this is ...") %>
        </span>
      </div>
      <div class="me-auto p-0 p-md-3 ps-0 flex-grow-1 flex-md-grow-0">
        <form phx-change="change_identification" phx-target={@myself}>
          <input name="track[id]" type="hidden" value={@track.id} />
          <select class="form-select" name="guess">
            <%= options_for_select(
              identification_choices(@tracks),
              Map.get(@identified, @track.fake_id, "")
            ) %>
          </select>
        </form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "change_identification",
        %{"track" => %{"id" => track_id}} = identification_params,
        socket
      ) do
    identified =
      socket.assigns.choices_taken
      |> Map.get(socket.assigns.round, %{})
      |> Map.get(:identification, %{})

    fake_id = Tracks.find_fake_id_from_track_id(track_id, socket.assigns.tracks)

    identified_updated =
      case identification_params["guess"] do
        guess when guess == "" ->
          Map.delete(identified, fake_id)

        guess ->
          guess_int = String.to_integer(guess)

          identified
          |> Enum.find(nil, fn {_, value} -> value == guess_int end)
          |> case do
            nil -> identified
            {key, _} -> Map.delete(identified, key)
          end
          |> Map.put(fake_id, guess_int)
      end

    send(
      self(),
      {:update_choices_taken, socket.assigns.round, %{identification: identified_updated}}
    )

    {:noreply, socket}
  end

  def identification_choices(tracks) do
    [""] ++
      Enum.map(
        tracks
        |> Enum.filter(fn t -> t.reference_track != true end)
        |> Enum.sort_by(&Map.fetch(&1, :title)),
        fn x -> {x.title, x.fake_id} end
      )
  end
end
