defmodule OutputSelectorComponent do
  use FunkyABXWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="player-output d-none d-sm-block" id="output-selector" phx-hook="OutputSelector">
      <div class="dropdown">
        <div
          id="output-selector-dropdown"
          class="player-output-action cursor-pointer ms-3"
          title={dgettext("test", "Select an output device")}
          data-bs-auto-close="outside"
          data-bs-toggle="dropdown"
        >
          <i class="bi bi-speaker text-extra-muted"></i>
        </div>
        <div class="dropdown-menu p-2 px-3">
          <div :if={!@display_selector}>
            <a class="dropdown-item cursor-pointer" phx-click="list_devices" phx-target={@myself}>
              <small>{dgettext("test", "Select an output device")}</small>
            </a>
          </div>
          <div :if={@display_selector}>
            <div class="mb-2">
              <label class="form-check-label mb-2 ps-1" for="output-select">
                <small>{dgettext("test", "Select an output device")}</small>
              </label>
              <select
                class="form-select form-select-sm select-output"
                name="output-select"
                aria-label="Audio output select"
              >
                <option :for={device <- @devices} value={device.device_id}>
                  {device.label}
                </option>
              </select>
            </div>
            <div :if={@selected_device} class="small mb-2">
              {dgettext("test", "Currently selected: %{device}",
                device: get_device_label(@selected_device, @devices)
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     assign(socket,
       devices: Map.get(assigns, :devices) || Map.get(socket.assigns, :devices) || [],
       selected_device:
         Map.get(assigns, :selected_device) || Map.get(socket.assigns, :selected_device) || nil,
       display_selector:
         Map.get(assigns, :display_selector) || Map.get(socket.assigns, :display_selector) ||
           false
     )}
  end

  @impl true
  def handle_event("list_devices", _params, socket) do
    {:noreply,
     socket
     |> push_event("select_output", %{})
     |> assign(display_selector: true)}
  end

  @impl true
  def handle_event("output_devices", %{"devices" => devices} = _params, socket) do
    devices_cleaned =
      devices
      |> Enum.map(fn e ->
        %{device_id: e["deviceId"], label: e["label"]}
      end)

    {:noreply, assign(socket, devices: devices_cleaned)}
  end

  defp get_device_label(device_id, devices) when is_binary(device_id) and device_id != "" do
    Enum.find_value(devices, fn e ->
      if e.device_id == device_id do
        e.label
      else
        false
      end
    end)
  end

  defp get_device_label(_device_id, _devices), do: nil
end
