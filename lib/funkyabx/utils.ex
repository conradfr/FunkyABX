defmodule FunkyABX.Utils do
  import FunkyABXWeb.Gettext

  @default_locale "en"

  def get_ip_as_binary(nil), do: nil

  def get_ip_as_binary(remote_ip) do
    remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  def send_success_toast(message, id) when is_binary(message) do
    with pid when pid != nil <- get_pid_of_toast_lv(id) do
      Process.send(pid, {:display_toast, message, :success}, [])
    else
      _ -> :error
    end
  end

  def send_error_toast(message, id) do
    with pid when pid != nil <- get_pid_of_toast_lv(id) do
      Process.send(pid, {:display_toast, message, :error}, [])
    else
      _ -> :error
    end
  end

  def send_error_toast(id) do
    with pid when pid != nil <- get_pid_of_toast_lv(id) do
      Process.send(
        pid,
        {:display_toast, dgettext("site", "An error occurred, please try again."), :error},
        []
      )
    else
      _ -> :error
    end
  end

  def get_page_id_from_socket(socket) do
    with %{} = params <- Phoenix.LiveView.get_connect_params(socket) do
      params
      |> Map.get("page_id")
      |> Integer.to_string()
    else
      _ -> nil
    end
  end

  def get_pid_of_toast_lv(id) do
    case Registry.lookup(FunkyABXRegistry, "bs_toast_" <> id) do
      [] -> nil
      [{pid, _}] -> pid
    end
  end

  def get_locale_from_socket(socket) do
    with %{} = params <- Phoenix.LiveView.get_connect_params(socket) do
      params
      |> Map.get("locale", @default_locale)
    else
      _ -> @default_locale
    end
  end

  def embedize_url(add_embed, prefix \\ "?")

  def embedize_url(true, prefix), do: "#{prefix}embed=1"
  def embedize_url(_embed, _prefix), do: ""
end
