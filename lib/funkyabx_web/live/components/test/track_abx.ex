defmodule FunkyABXWeb.TestTrackAbxComponent do
  use FunkyABXWeb, :live_component

  @impl true
  def render(assigns) do
    assigns =
      assign_new(assigns, :guessed, fn ->
        case Map.get(assigns.choices_taken, :abx, {"", false}) do
          {"", _guessed} -> ""
          {guess, _guessed} -> dgettext("test", "Track %{guess}", guess: guess)
        end
      end)

    ~H"""
    <div class="p-2 d-flex flex-row align-items-center flex-grow-1 flex-md-grow-0">
      <%= if Map.get(@track, :to_guess, false) do %>
        <div class="me-auto flex-grow-1 flex-md-grow-0">
          <span class="me-3 text-body-secondary small"><%= dgettext("test", "I think this is ...") %></span>
        </div>
        <div class=" p-0 p-md-3 flex-fill">
          <form phx-change="change_guess" phx-target={@myself}>
            <select class="form-select" name="guess">
              <%= options_for_select(abx_choices(@test), @guessed) %>
            </select>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event(
        "change_guess",
        %{"guess" => guess} = _ranking_params,
        socket
      ) do
    guessed =
      case guess do
        "" ->
          false

        _ ->
          track =
            guess
            |> String.to_integer()
            |> (&Enum.at(socket.assigns.test.tracks, &1 - 1)).()

          track.id == socket.assigns.tracks |> List.last() |> Map.get(:id)
      end

    send(self(), {:update_choices_taken, socket.assigns.round, %{abx: {guess, guessed}}})
    {:noreply, socket}
  end

  def abx_choices(test) when test.anonymized_track_title == false do
    test.tracks
    |> Enum.with_index(1)
    |> Enum.reduce([""], fn {t, i}, acc ->
      acc ++ [{t.title, i}]
    end)
  end

  def abx_choices(test) do
    ([""] ++ Enum.to_list(1..Kernel.length(test.tracks)))
    |> Enum.map(fn choice ->
      case choice do
        choice when is_integer(choice) ->
          {dgettext("site", "Track %{choice}", choice: Integer.to_string(choice)), choice}

        choice ->
          choice
      end
    end)
  end
end
