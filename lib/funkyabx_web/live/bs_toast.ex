defmodule FunkyABXWeb.BsToastLive do
  use FunkyABXWeb, :live_view

  alias FunkyABX.Utils

  @status [:success, :error]

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="bs-toast-container"
      phx-hook="BsToast"
      phx-update="stream"
      class="toast-container position-fixed top-0 end-0 p-3"
    >
      <div
        id="toast-disconnected"
        role="alert"
        aria-live="assertive"
        aria-atomic="true"
        class="toast text-white bg-warning"
      >
        <div class="d-flex justify-content-center align-items-center p-3">
          <div class="toast-icon">
            <i class="bi-x-circle-fill"></i>
          </div>
          <div class="toast-body flex-fill py-0 text-center align-middle">
            <%= dgettext("site", "Websocket error, attempting to reconnect ...") %>
          </div>
        </div>
      </div>

      <div
        :for={{id, toast} <- @streams.toasts}
        id={id}
        role="alert"
        aria-live="assertive"
        aria-atomic="true"
        class={[
          "toast",
          "text-white",
          toast.type == :success && "bg-success",
          toast.type == :error && "bg-warning"
        ]}
      >
        <div class="d-flex justify-content-center align-items-center p-3">
          <div class="toast-icon">
            <i class={[
              "bi",
              toast.type == :success && "bi-check-circle-fill",
              toast.type == :error && "bi-x-circle-fill"
            ]}>
            </i>
          </div>
          <div class="toast-body flex-fill py-0 text-center align-middle">
            <%= toast.message %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      process_name = get_toast_process_name(socket)
      Registry.register(FunkyABXRegistry, process_name, :toast)
    end

    {:ok,
     socket
     |> stream(:toasts, []), layout: false}
  end

  @impl true
  def handle_info({:display_toast, message, status}, socket)
      when is_binary(message) and status in @status do
    toast = Toast.new(message, status)

    {:noreply,
     socket
     |> stream_insert(:toasts, toast)
     |> push_event("show_toast", %{id: "toasts-" <> toast.id})}
  end

  @impl true
  def handle_info({:display_toast, _message, _status}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toast_closed", %{"id" => id} = _params, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :toasts, id)}
  end

  # we get the unique id from the app.js so both liveviews have the same
  defp get_toast_process_name(socket) do
    "bs_toast_" <> Utils.get_page_id_from_socket(socket)
  end
end
