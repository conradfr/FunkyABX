defmodule FunkyABXWeb.DevController do
  use FunkyABXWeb, :controller

  def redirect_file(conn, %{"part1" => part1, "part2" => part2} = _params) do
#    s3_conf = Application.fetch_env!(:ex_aws, :s3)
#    url = Keyword.get(s3_conf, :scheme) <> Keyword.get(s3_conf, :host) <> "/" <> part1 <> "/" <> part2
  pick =
    ["A", "B"]
    |> Enum.random()

    Plug.Conn.send_file(conn, 200, "priv/static/uploads/#{pick}.wav")
  end
end
