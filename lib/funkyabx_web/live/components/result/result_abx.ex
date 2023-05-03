defmodule FunkyABXWeb.TestResultAbxComponent do
  use FunkyABXWeb, :live_component

  alias FunkyABX.Test
  alias FunkyABX.Tests.Abx

  attr :test, Test, required: true
  attr :visitor_choices, :any, required: true
  attr :is_another_session, :boolean, required: true
  attr :track_id, :string, required: true
  attr :test_taken_times, :integer, required: true

  @impl true
  def render(assigns) do
    assigns =
      case Map.get(assigns, :visitor_guesses, %{}) do
        %{} ->
          assign(assigns, :visitor_guesses, get_visitor_score(assigns))

        _ ->
          assigns
      end

    ~H"""
    <div style="min-height: 200px">
      <h4 class="mt-3 header-neon"><%= dgettext("test", "ABX") %></h4>

      <div :if={@visitor_guesses != nil} class="mb-3">
        <%= raw(
          dgettext("test", "Your score: <strong>%{visitor_guesses} / %{nb_of_rounds}</strong>",
            visitor_guesses: @visitor_guesses,
            nb_of_rounds: @test.nb_of_rounds
          )
        ) %>
        <i :if={@visitor_guesses == @test.nb_of_rounds} class="bi bi-hand-thumbs-up"></i>
      </div>

      <div :if={@test.local === false} class="tracks my-2 mb-1 track-results results">
        <div :if={Kernel.length(@abx) == 0} class="alert alert-info alert-thin">
          <%= dgettext("test", "No test taken ... yet!") %>
        </div>
        <%= for {%{correct: guess, count: count, probability: probability}, i} <- @abx |> Enum.with_index(1) do %>
          <div class="track my-1 d-flex flex-wrap justify-content-between align-items-center">
            <div class="p-3">
              <%= if (guess < 4) do %>
                <i class={"bi bi-trophy-fill trophy-#{i}"}></i>
              <% else %>
                #<%= i %>
              <% end %>
            </div>
            <div class="p-3 ps-1 text-end">
              <%= raw(
                dgettext("test", "Correct guesses: <strong>%{guess} / %{nb_of_rounds}</strong>",
                  guess: guess,
                  nb_of_rounds: @test.nb_of_rounds
                )
              ) %>
            </div>

            <div class="d-flex flex-grow-1 justify-content-end align-items-center">
              <div
                :if={@visitor_guesses == guess}
                class="p-3 flex-grow-1 text-sm-end text-start pe-5 small"
              >
                <%= if @is_another_session == true do %>
                  <%= dgettext("test", "Scored") %>
                <% else %>
                  <%= dgettext("test", "Your score!") %>
                <% end %>
              </div>
            </div>
            <div
              :if={Kernel.length(@test.tracks) == 2}
              class="d-flex flex-grow-1 justify-content-end align-items-center"
            >
              <div class="p-3 flex-grow-1 text-sm-end text-start pe-5 text-muted small d-none">
                <%= dgettext(
                  "test",
                  "Confidence that this result is better than chance: %{probability}%",
                  probability: probability
                ) %>
              </div>
            </div>
            <div class="p-3 ps-0 text-end">
              <%= dngettext("test", "%{count} time", "%{count} times", count) %>
            </div>
          </div>
        <% end %>
      </div>
      <div :if={Kernel.length(@test.tracks) == 2} class="text-muted small d-none">
        <i class="bi bi-info-circle"></i>&nbsp;&nbsp;<%= raw(
          dgettext(
            "test",
            "A 95% confidence level is commonly considered statistically significant (<a href=\"https://en.wikipedia.org/wiki/ABX_test#Confidence\" class=\"text-muted\">source</a>)."
          )
        ) %>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:abx, fn -> Abx.get_abx(assigns.test) end)}
  end

  defp get_visitor_score(assigns) when is_map_key(assigns, :visitor_choices) == false, do: nil

  defp get_visitor_score(assigns) do
    assigns.visitor_choices
    |> Map.values()
    |> Enum.count(fn round_result ->
      round_result
    end)
  end
end
