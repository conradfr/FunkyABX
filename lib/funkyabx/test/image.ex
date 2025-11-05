defmodule FunkyABX.Tests.Image do
  import Mogrify
  use FunkyABXWeb, :verified_routes

  alias FunkyABX.{Tests, Test, Files}

  @image_path "img/results"
  @image_ext "png"

  def get_filename(session_id) when is_binary(session_id) do
    ShortUUID.encode!(session_id) <> "." <> @image_ext
  end

  def get_path_of_img(test, session_id, filename \\ nil)

  def get_path_of_img(%Test{} = test, session_id, nil) do
    get_path_of_img(test, session_id, get_filename(session_id))
  end

  def get_path_of_img(%Test{} = test, _session_id, filename) do
    Path.join([@image_path, ShortUUID.encode!(test.id), filename])
  end

  def exists?(%Test{} = test, _session_id, filename) do
    Path.join([@image_path, ShortUUID.encode!(test.id), filename])
    |> Files.exists?()
  end

  def generate(test, session_id) do
    path = Path.join([:code.priv_dir(:funkyabx), "static", "uploads", get_filename(session_id)])

    mogrify =
      %Mogrify.Image{path: path, ext: @image_ext}
      |> custom("size", "600x3000")
      |> logo(10)
      |> custom("gravity", "NorthWest")
      |> custom("background", "#150f0b")
      |> custom("fill", "#f8f8f8")
      |> custom(
        "font",
        Path.join([:code.priv_dir(:funkyabx), "/static/assets/fonts/TypoGraphica.otf"])
      )
      |> custom("pointsize", "16")
      |> custom(
        "draw",
        "text 10,5 '#{String.replace(test.title, ["'", "\"", "$"], " ", global: true)}'"
      )

    {start, mogrify} = results_modules(mogrify, test, session_id)

    mogrify
    |> custom("crop", "600x#{start + 10}+0+0")
    #    |> logo(start-110)
    |> footer_link(test, session_id, start)
    |> custom("pango", ~S())
    |> create(path: path)

    path
  end

  defp results_modules(mogrify, test, session_id) do
    choices = Tests.get_results_of_session(test, session_id)

    Tests.get_test_modules(test)
    |> Enum.reduce({41, mogrify}, fn module, acc ->
      module
      |> Kernel.apply(:results_to_img, [acc, test, session_id, choices])
      |> then(fn {start, mogrify} ->
        {start + 20, mogrify}
      end)
    end)
  end

  def type_title(mogrify, start, title) do
    mogrify
    |> custom("gravity", "NorthWest")
    |> custom("fill", "#f8f8f8")
    |> custom("font", Path.join([:code.priv_dir(:funkyabx), "/static/assets/fonts/Neon.ttf"]))
    |> custom("pointsize", "14")
    |> custom("draw", "text 10,#{start} '#{title}'")
  end

  def type_track(mogrify, start, index, text) do
    mogrify
    |> custom("fill", "#f8f8f8")
    |> custom("font", "Arial")
    |> custom("pointsize", "12")
    |> custom("draw", "text 10,#{start + 20 * index} '#{text}'")
  end

  defp logo(mogrify, start) do
    mogrify
    |> custom("gravity", "NorthEast")
    |> custom("fill", "#c44811")
    |> custom("font", Path.join([:code.priv_dir(:funkyabx), "/static/assets/fonts/Barqish.otf"]))
    |> custom("pointsize", "14")
    |> custom("draw", "text 10,#{start} 'FunkyABX'")
  end

  defp footer_link(mogrify, test, session_id, start) do
    url =
      FunkyABXWeb.Endpoint.url() <> ~p"/results/#{test.slug}?s=#{ShortUUID.encode!(session_id)}"

    mogrify
    |> custom("gravity", "NorthEast")
    |> custom("fill", "#505050")
    |> custom("font", "Arial")
    |> custom("pointsize", "9")
    |> custom("draw", "text 10,#{start - 5} '#{url}'")
  end
end
