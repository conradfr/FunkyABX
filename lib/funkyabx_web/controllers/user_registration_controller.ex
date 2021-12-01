defmodule FunkyABXWeb.UserRegistrationController do
  use FunkyABXWeb, :controller
  import Ecto.Query, only: [from: 2]
  import Plug.Conn
  alias FunkyABX.Repo
  alias FunkyABX.Accounts
  alias FunkyABX.Accounts.User
  alias FunkyABX.Test
  alias FunkyABXWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} = Accounts.deliver_user_welcome(user)

        conn
        |> transfer_tests_to_account(user)
        |> delete_test_cookies(conn)
        |> put_flash(:info, "Your account has been created!")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp transfer_tests_to_account(conn, user) do
    ids =
      conn.cookies
      |> Enum.reduce([], fn {k, c}, acc ->
        case String.starts_with?(k, "test_") do
          true -> [String.slice(k, 5, 36) | [c | acc]]
          false -> acc
        end
      end)

    test_ids = Enum.take_every(ids, 2)
    password_ids = ids -- test_ids

    IO.puts "#{inspect test_ids}"
    IO.puts "#{inspect password_ids}"

    query =
      from(t in Test,
        where: t.id in ^test_ids and t.password in ^password_ids and is_nil(t.deleted_at),
        select: t
      )

    query
    |> Repo.all()
    |> Enum.map(fn t ->
      t
      |> Repo.preload(:user)
      |> Test.changeset_to_user(%{"user" => user, "password" => nil})
      |> Repo.update()

      t.id
    end)
  end

  defp delete_test_cookies(test_ids, conn) do
    test_ids
    |> Enum.reduce(conn, fn test_id, acc ->
      delete_test_cookie(test_id, acc)
    end)
  end

  defp delete_test_cookie(test_id, conn) do
    delete_resp_cookie(conn, "test_#{test_id}")
  end
end
