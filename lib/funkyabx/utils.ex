defmodule FunkyABX.Utils do
  use Gettext, backend: FunkyABXWeb.Gettext
  import Phoenix.LiveView.Utils, only: [put_flash: 3]
  use Gettext, backend: FunkyABXWeb.Gettext

  @headers [
    {"Content-type", "application/x-www-form-urlencoded"},
    {"Accept", "application/json"}
  ]

  @verify_url "https://www.google.com/recaptcha/api/siteverify"

  def parse_recaptcha_token(nil), do: false

  def parse_recaptcha_token(token) do
    body =
      %{secret: Application.fetch_env!(:funkyabx, :recaptcha_private), response: token}
      |> URI.encode_query()

    case HTTPoison.post(@verify_url, body, @headers) do
      {:ok, response} ->
        body = response.body |> Jason.decode!()

        if body["success"] do
          true
        else
          false
        end

      _ ->
        false
    end
  end

  def get_ip_as_binary(nil), do: nil

  def get_ip_as_binary(remote_ip) do
    remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  def send_error_toast(socket) do
    test = Gettext.dgettext(FunkyABXWeb.Gettext, "site", "An error occurred, please try again.")
    put_flash(socket, :error, test)
  end

  def embedize_url(add_embed, prefix \\ "?")

  def embedize_url(:test, prefix), do: "#{prefix}embed=1"
  def embedize_url(:player, prefix), do: "#{prefix}embed=2"
  def embedize_url(_embed, _prefix), do: ""
end
