defmodule FunkyABXWeb.Plugs.Auth do
  import Plug.Conn
  import Ecto.Query, warn: false, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.ApiKey

  def init(options), do: options

  def call(conn, _opts) do
    with api_keys when api_keys != [] <- get_req_header(conn, "x-api-key"),
         api_key_string <- hd(api_keys),
         api_key when api_key != nil <-
           Repo.get_by(ApiKey, id: api_key_string)
           |> Repo.preload(:user),
         user when user != nil <- api_key.user do
      conn
      |> put_private(:api_key, api_key)
      |> put_private(:user, user)
    else
      _ ->
        conn
    end
  end
end
