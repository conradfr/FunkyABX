defmodule FunkyABXWeb.TestResultAbxComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.Tests.Abx
  alias FunkyABX.Tests.Abx

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
      <div>
        <h4 class="mt-3 header-neon">ABX</h4>

        <%= if @visitor_guesses != nil do %>
          <div class="mb-3">
            Your score: <strong><%= @visitor_guesses %> / <%= @test.nb_of_rounds %></strong>
            <%= if @visitor_guesses == @test.nb_of_rounds do %>
              <i class="bi bi-hand-thumbs-up"></i>
            <% end %>
          </div>
        <% end %>

        <div class="tracks my-2 mb-1 track-results results">
          <%= if Kernel.length(@abx) == 0 do %>
            <div class="alert alert-info alert-thin">No test taken ... yet!</div>
          <% end %>
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
                Correct guesses: <%= guess %> / <%= @test.nb_of_rounds %>
              </div>

              <div class="d-flex flex-grow-1 justify-content-end align-items-center">
                <%= if @visitor_guesses == guess do %>
                  <div class="p-3 flex-grow-1 text-sm-end text-start pe-5"><small>Your score!</small></div>
                <% end %>
              </div>
              <%= if Kernel.length(@test.tracks) == 2 do %>
                <div class="d-flex flex-grow-1 justify-content-end align-items-center">
                  <div class="p-3 flex-grow-1 text-sm-end text-start pe-5 text-muted"><small>Confidence that this result is better than chance: <%= probability %>%</small></div>
                </div>
              <% end %>
              <div class="p-3 ps-0 text-end">
                <%= count %> times
              </div>
            </div>
          <% end %>
        </div>
        <%= if Kernel.length(@test.tracks) == 2 do %>
          <div class="text-muted"><small><i class="bi bi-info-circle"></i>&nbsp;&nbsp;A 95% confidence level is commonly considered statistically significant (<a href="https://en.wikipedia.org/wiki/ABX_test#Confidence" class="text-muted">source</a>).</small></div>
        <% end %>
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
