defmodule FunkyABXWeb.UserTestsMenuComponent do
  use FunkyABXWeb, :html

  alias FunkyABX.Tests

  @limit 11

  attr :conn, :any, required: true
  attr :current_user, :any

  def display(assigns) do
    assigns = assign_new(assigns, :tests, fn -> get_tests(assigns.conn) end)

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
        <%= dgettext("test", "My tests") %>
      </a>
      <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownTestsMenuLink">
        <%= for test <- @tests do %>
          <li class="navbar-tests">
            <div class="d-flex w-100">
              <div class="px-3 flex-grow-1 text-truncate" style="width: 250px">
                <%= link(test.title, to: ~p"/test/#{test.slug}") %>
              </div>
              <div class="text-center" style="width: 100px">
                <%= if test.view_count != nil do %>
                  <i class="bi bi-eye"></i>&nbsp;&nbsp;<%= test.view_count %>
                <% else %>
                  <span class="text-body-secondary">-</span>
                <% end %>
              </div>
              <div class="d-flex text-end navbar-tests-actions">
                <%= if @current_user do %>
                  <div class="px-1">
                    <%= link(dgettext("test", "edit"), to: ~p"/edit/#{test.slug}") %>
                  </div>
                  <div class="text-body-secondary">|</div>
                  <%= unless test.type == :listening do %>
                    <div class="px-1">
                      <%= link(dgettext("test", "results"),
                        to: ~p"/results/#{test.slug}",
                        class: "disabled"
                      ) %>
                    </div>
                  <% else %>
                    <div class="px-1 text-body-secondary"><%= dgettext("test", "results") %></div>
                  <% end %>
                <% else %>
                  <div class="px-1">
                    <%= link(dgettext("test", "edit"), to: ~p"/edit/#{test.slug}/#{test.access_key}") %>
                  </div>
                  <div class="text-body-secondary">|</div>
                  <%= unless test.type == :listening do %>
                    <div class="px-1">
                      <%= link(dgettext("test", "results"),
                        to: ~p"/results/#{test.slug}/#{test.access_key}"
                      ) %>
                    </div>
                  <% else %>
                    <div class="px-1 text-body-secondary"><%= dgettext("test", "results") %></div>
                  <% end %>
                <% end %>
              </div>
            </div>
          </li>
        <% end %>
        <%= if Kernel.length(@tests) == 0 do %>
          <li class="navbar-tests px-2 text-center">
            <small class="text-body-secondary"><%= dgettext("test", "No tests (yet !)") %></small>
          </li>
        <% else %>
          <%= if @current_user do %>
            <li><hr class="dropdown-divider" style="background-color: white;" /></li>
            <li class="px-1 text-center d-flex justify-content-around">
              <div><small><%= link(dgettext("test", "New test"), to: ~p"/test") %></small></div>
              <div>
                <small><%= link(dgettext("test", "All my tests"), to: ~p"/user/tests") %></small>
              </div>
            </li>
          <% end %>
        <% end %>
      </ul>
    </li>
    """
  end

  defp get_tests(%{assigns: %{current_user: current_user}} = _conn)
       when not is_nil(current_user) do
    Tests.get_of_user(current_user, @limit)
  end

  defp get_tests(conn) do
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
