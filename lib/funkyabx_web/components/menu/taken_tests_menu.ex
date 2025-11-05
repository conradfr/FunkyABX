defmodule FunkyABXWeb.TakenTestsMenuComponent do
  use FunkyABXWeb, :html

  alias FunkyABX.Tests

  attr :cookies, :any, required: true

  def display(assigns) do
    assigns = assign_new(assigns, :tests, fn -> get_taken_tests(assigns.cookies) end)

    ~H"""
    <li class="nav-item dropdown">
      <a
        class="nav-link dropdown-toggle"
        href="#"
        id="navbarDropdownTakenTestsMenuLink"
        role="button"
        data-bs-toggle="dropdown"
        aria-expanded="false"
      >
        {dgettext("test", "Tests taken")}
      </a>
      <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdownTakenTestsMenuLink">
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
              <div class="d-flex text-end navbar-tests-actions">
                <div class="px-1">
                  <.link
                    href={~p"/results/#{test.slug}"}
                    class="text-base-content/80 hover:text-primary"
                  >
                    {dgettext("test", "results")}
                  </.link>
                </div>
              </div>
            </div>
          </li>
        <% end %>

        <li :if={length(@tests) == 0} class="navbar-tests px-2 text-center">
          <small class="text-body-secondary">{dgettext("test", "No test taken (yet !)")}</small>
        </li>
      </ul>
    </li>
    """
  end

  defp get_taken_tests(cookies) do
    test_ids =
      cookies
      |> Enum.reduce([], fn {k, c}, acc ->
        case String.starts_with?(k, "taken_") and
               not String.ends_with?(k, ["_session", "_tracks_order"]) do
          true -> [String.slice(k, 6, 36) | [c | acc]]
          false -> acc
        end
      end)
      |> Enum.take_every(2)

    unless length(test_ids) == 0 do
      Tests.get_tests_from_ids(test_ids)
    else
      []
    end
  end
end
