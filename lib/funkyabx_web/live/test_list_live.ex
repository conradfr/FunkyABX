defmodule FunkyABXWeb.TestListLive do
  use FunkyABXWeb, :live_view
  alias FunkyABX.Cldr
  alias FunkyABX.Repo
  alias FunkyABX.Accounts

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <table class="table">
          <thead>
          <tr>
            <th scope="col" class="text-center w-50">Title</th>
            <th scope="col" class="text-center w-25">Created</th>
            <th scope="col" class="text-center">Taken</th>
            <th scope="col" class="text-center">Results</th>
            <th scope="col" class="text-center">Actions</th>
          </tr>
          </thead>
          <tbody class="table-striped">
            <%= for test <- @tests do %>
              <tr>
                <td><%= link test.title, to: Routes.test_public_path(@socket, FunkyABXWeb.TestLive, test.slug), class: "test-link" %></td>
                <td class="text-center"><%= format_date(test.inserted_at) %></td>
                <%= unless test.type == :listening do %>
                  <td class="text-center"></td>
                  <td class="text-center"><%= link "results", to: Routes.test_results_public_path(@socket, FunkyABXWeb.TestResultsLive, test.slug) %></td>
                <% else %>
                  <td colspan="2"></td>
                <% end %>
                <td class="text-center"><%= link "edit / delete", to: Routes.test_edit_path(@socket, FunkyABXWeb.TestFormLive, test.slug) %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    with user when not is_nil(user) <- Accounts.get_user_by_session_token(session["user_token"]) do
      user = Repo.preload(user, :tests)
      tests = Enum.filter(user.tests, fn t -> t.deleted_at == nil end)

      {:ok, assign(
        socket, %{
          page_title: "My tests",
          tests: tests
        }
      )}
    else
      _ ->
        {:ok, socket}
    end
  end

  defp format_date(datetime) do
    {:ok, date_string} = Cldr.DateTime.to_string(datetime, format: :short)
    date_string
  end
end
