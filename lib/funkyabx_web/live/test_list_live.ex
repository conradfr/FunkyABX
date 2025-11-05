defmodule FunkyABXWeb.TestListLive do
  use FunkyABXWeb, :live_view

  alias FunkyABX.Repo
  alias FunkyABX.Accounts.User
  alias FunkyABX.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <h3 class="header-chemyretro">{dgettext("test", "My tests")}</h3>
    <div>
      <table class="table">
        <thead>
          <tr>
            <th scope="col" class="text-center w-50">{dgettext("test", "Title")}</th>
            <th scope="col" class="text-center w-25">{dgettext("test", "Created")}</th>
            <th scope="col" class="text-center">{dgettext("test", "Views")}</th>
            <!-- <th scope="col" class="text-center"><%= dgettext "test", "Taken" %></th> -->
            <th scope="col" class="text-center">{dgettext("test", "Results")}</th>
            <th scope="col" class="text-center">{dgettext("test", "Actions")}</th>
          </tr>
        </thead>
        <tbody class="table-striped">
          <%= for test <- @tests do %>
            <tr>
              <td>
                <.link href={~p"/test/#{test.slug}"} class="test-link">{test.title}</.link>
              </td>
              <td class="text-center">{format_date_time(test.inserted_at)}</td>
              <td class="text-center">
                <%= unless test.view_count == nil do %>
                  {test.view_count}
                <% else %>
                  -
                <% end %>
              </td>
              <%= unless test.type == :listening do %>
                <td class="text-center"><.link href={~p"/results/#{test.slug}"}>results</.link></td>
              <% else %>
                <td class="text-center">-</td>
              <% end %>
              <td class="text-center">
                <.link href={~p"/edit/#{test.slug}"}>{dgettext("test", "edit / delete")}</.link>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    with {%User{} = user, _token_inserted_at} when not is_nil(user) <-
           Accounts.get_user_by_session_token(session["user_token"]) do
      # todo more efficient
      user = Repo.preload(user, :tests)
      tests = Enum.filter(user.tests, fn t -> t.deleted_at == nil end)

      {:ok,
       assign(
         socket,
         %{
           page_title: dgettext("test", "My tests"),
           tests: tests
         }
       )}
    else
      _ ->
        {:ok, socket}
    end
  end
end
