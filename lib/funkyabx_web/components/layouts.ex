defmodule FunkyABXWeb.Layouts do
  use FunkyABXWeb, :html

  @release_version_env "RELEASE_ID"

  @limit 11

  embed_templates "layouts/*"

  defp get_release_version_query_string() do
    with release_version when is_binary(release_version) <- get_release_version() do
      "?v=#{release_version}"
    else
      _ -> "?v=dev"
    end
  end

  defp get_release_version() do
    System.get_env(@release_version_env)
  end
end
