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
            <th scope="col" class="text-center">Views</th>
            <!-- <th scope="col" class="text-center">Taken</th> -->
            <th scope="col" class="text-center">Results</th>
            <th scope="col" class="text-center">Actions</th>
          </tr>
          </thead>
          <tbody class="table-striped">
            <%= for test <- @tests do %>
              <tr>
                <td><.link href={Routes.test_public_path(@socket, FunkyABXWeb.TestLive, test.slug)} class="test-link"><%= test.title %></.link></td>
                <td class="text-center"><%= format_date(test.inserted_at) %></td>
                <td class="text-center">
                  <%= unless test.view_count == nil do %>
                    <%= test.view_count %>
                  <% else %>
                    -
                  <% end %>
                </td>
                  <%= unless test.type == :listening do %>
                    <!-- <td class="text-center">-</td> -->
                    <td class="text-center"><.link href={Routes.test_results_public_path(@socket, FunkyABXWeb.TestResultsLive, test.slug)}>results</.link></td>
                  <% else %>
                    <!-- <td class="text-center">-</td> -->
                    <td class="text-center">-</td>
                  <% end %>
                <td class="text-center"><.link href={Routes.test_edit_path(@socket, FunkyABXWeb.TestFormLive, test.slug)}>edit / delete</.link></td>
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

      {:ok,
       assign(
         socket,
         %{
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
