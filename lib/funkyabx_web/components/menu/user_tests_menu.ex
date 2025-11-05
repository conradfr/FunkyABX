defmodule FunkyABXWeb.UserTestsMenuComponent do
  use FunkyABXWeb, :html

  alias FunkyABX.Tests
  alias FunkyABX.Accounts.User

  @limit 11

  attr :conn, :any, required: true
  attr :current_user, :any

  def display(assigns) do
    assigns = assign_new(assigns, :tests, fn -> get_tests(assigns.current_user, assigns.conn) end)

    ~H"""
    <li class="nav-item dropdown">
      <a
        class="nav-link dropdown-toggle"
        href="#"
        id="navbarDropdownTestsMenuLink"
        role="button"
        data-bs-toggle="dropdown"
        aria-expanded="false"
      >
        {dgettext("test", "My tests")}
      </a>
      <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownTestsMenuLink">
        <%= for test <- @tests do %>
          <li class="navbar-tests">
            <div class="d-flex w-100">
              <div class="px-3 flex-grow-1 text-truncate" style="width: 250px">
                <.link
                  href={~p"/test/#{test.slug}"}
                  class="text-base-content/80 hover:text-primary"
                >
                  {test.title}
                </.link>
              </div>
              <div class="text-center" style="width: 100px">
                <%= if test.view_count != nil do %>
                  <i class="bi bi-play-circle" title={dgettext("site", "Test played")}></i>&nbsp;&nbsp;{test.view_count}
                <% else %>
                  <span class="text-body-secondary">-</span>
                <% end %>
              </div>
              <div class="d-flex text-end navbar-tests-actions">
                <%= if @current_user do %>
                  <div class="px-1">
                    <.link
                      href={~p"/edit/#{test.slug}"}
                      class="text-base-content/80 hover:text-primary"
                    >
                      {dgettext("test", "edit")}
                    </.link>
                  </div>
                  <div class="text-body-secondary">|</div>
                  <%= unless test.type == :listening do %>
                    <div class="px-1">
                      <.link
                        href={~p"/results/#{test.slug}"}
                        class="text-base-content/80 hover:text-primary disabled"
                      >
                        {dgettext("test", "results")}
                      </.link>
                    </div>
                  <% else %>
                    <div class="px-1 text-body-secondary">{dgettext("test", "results")}</div>
                  <% end %>
                <% else %>
                  <div class="px-1">
                    <.link
                      href={~p"/edit/#{test.slug}/#{test.access_key}"}
                      class="text-base-content/80 hover:text-primary disabled"
                    >
                      {dgettext("test", "edit")}
                    </.link>
                  </div>
                  <div class="text-body-secondary">|</div>
                  <%= unless test.type == :listening do %>
                    <div class="px-1">
                      <.link
                        href={~p"/results/#{test.slug}/#{test.access_key}"}
                        class="text-base-content/80 hover:text-primary disabled"
                      >
                        {dgettext("test", "results")}
                      </.link>
                    </div>
                  <% else %>
                    <div class="px-1 text-body-secondary">{dgettext("test", "results")}</div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </li>
        <% end %>
        <%= if Kernel.length(@tests) == 0 do %>
          <li class="navbar-tests px-2 text-center">
            <small class="text-body-secondary">{dgettext("test", "No tests (yet !)")}</small>
          </li>
        <% else %>
          <%= if @current_user do %>
            <li><hr class="dropdown-divider" style="background-color: white;" /></li>
            <li class="px-1 text-center d-flex justify-content-around">
              <div>
                <small>
                  <.link
                    href={~p"/test"}
                    class="text-base-content/80 hover:text-primary disabled"
                  >
                    {dgettext("test", "New test")}
                  </.link>
                </small>
              </div>
              <div>
                <small>
                  <.link
                    href={~p"/user/tests"}
                    class="text-base-content/80 hover:text-primary disabled"
                  >
                    {dgettext("test", "All my tests")}
                  </.link>
                </small>
              </div>
            </li>
          <% end %>
        <% end %>
      </ul>
    </li>
    """
  end

  defp get_tests(%User{} = current_user, _conn)
       when not is_nil(current_user) do
    Tests.get_of_user(current_user, @limit)
  end

  defp get_tests(_user, conn) do
    ids =
      conn.cookies
      |> Enum.reduce([], fn {k, c}, acc ->
        case String.starts_with?(k, "test_") do
          true -> [String.slice(k, 5, 36) | [c | acc]]
          false -> acc
        end
      end)

    test_ids = Enum.take_every(ids, 2)
    access_key_ids = ids -- test_ids

    unless length(test_ids) == 0 or length(access_key_ids) == 0 do
      Tests.get_tests_from_ids_and_access_key_ids(test_ids, access_key_ids, @limit)
    else
      []
    end
  end
end
