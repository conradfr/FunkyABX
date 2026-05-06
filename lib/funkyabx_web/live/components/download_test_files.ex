defmodule DownloadTestFilesComponent do
  use FunkyABXWeb, :live_component
  alias FunkyABX.Repo
  use PhoenixHTMLHelpers
  import Ecto.Query, only: [from: 2]

  alias FunkyABX.Test
  alias FunkyABX.Tracks

  attr :test, Test, required: true
  attr :class, :string, default: "mt-4 mb-2"

  @impl true
  def render(assigns) do
    ~H"""
    <div id="download-files" phx-hook="DownloadTestFiles">
      <button
        :if={@test.local == false and @test.allow_download_files == true}
        class={["btn btn-outline-dark", @class]}
        type="button"
        style="--bs-btn-padding-y: .25rem; --bs-btn-padding-x: .5rem; --bs-btn-font-size: .75rem;"
        phx-click="download"
        phx-target={@myself}
      >
        {dgettext("test", "Download audio files")}
      </button>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("download", _value, %{assigns: %{test: test}} = socket) do
    from(t in Test, where: t.id == ^test.id)
    |> Repo.update_all(inc: [download_files_counter: 1])

    socket =
      Enum.reduce(test.tracks, socket, fn t, socket ->
        push_event(socket, "download_file", %{
          title: t.title,
          url: Tracks.get_media_url(t, test)
        })
      end)

    {:noreply, socket}
  end
end
