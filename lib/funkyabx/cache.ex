defmodule FunkyABX.Cache do
  use Nebulex.Cache,
    otp_app: :funkyabx,
    adapter: Nebulex.Adapters.Local
end
