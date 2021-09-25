defmodule FunkyABX.Repo do
  use Ecto.Repo,
    otp_app: :funkyabx,
    adapter: Ecto.Adapters.Postgres
end
