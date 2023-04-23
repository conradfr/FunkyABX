defmodule FunkyABX.Files.Cloud do
  @behaviour FunkyABX.Files.Type

  @impl true
  def exists?(filename) when is_binary(filename) do
    case Application.fetch_env!(:funkyabx, :bucket)
         |> ExAws.S3.get_object(filename)
         |> ExAws.request() do
      {:error, _} -> false
      _ -> true
    end
  end

  @impl true
  def save(src_path, dest_path, opts \\ []) when is_binary(src_path) and is_binary(dest_path) do
    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.put_object(dest_path, File.read!(src_path), [{:acl, "public-read"}] ++ opts)
    |> ExAws.request!()
  end

  # Delete all from test
  @impl true
  def delete_all(test_id) do
    stream =
      Application.fetch_env!(:funkyabx, :bucket)
      |> ExAws.S3.list_objects_v2(prefix: test_id)
      |> ExAws.stream!()
      |> Stream.map(& &1.key)

    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.delete_all_objects(stream)
    |> ExAws.request()
  end

  # Delete a file or a list of files
  @impl true
  def delete(filename, test_id)

  @impl true
  def delete(filename, test_id) when is_list(filename) do
    filename
    |> Enum.map(fn file ->
      delete(file, test_id)
      file
    end)
  end

  @impl true
  def delete(filename, test_id) when is_binary(filename) do
    key = test_id <> "/" <> filename

    # we could probably just called delete with the object_key
    # without verifying that it exists
    object_key =
      Application.fetch_env!(:funkyabx, :bucket)
      |> ExAws.S3.list_objects_v2(prefix: test_id)
      |> ExAws.stream!()
      |> Enum.find(%{}, &(&1.key == key))
      |> Map.get(:key, nil)

    unless object_key == nil do
      Application.fetch_env!(:funkyabx, :bucket)
      |> ExAws.S3.delete_object(object_key)
      |> ExAws.request()
    end

    filename
  end

  # util, clean online storage of orphaned folders (from dev, bugs ...)
  def clean_folders() do
    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.list_objects_v2(delimiter: "/")
    |> ExAws.request!()
    |> Map.get(:body)
    |> Map.get(:common_prefixes)
    |> Enum.each(fn %{prefix: prefix} ->
      with folder <- prefix |> String.split("/") |> List.first(),
           true <- String.contains?(folder, "-"),
           test when is_nil(test) or is_nil(test.deleted_at) == false <-
             FunkyABX.Tests.get(folder) do
        delete_all(folder)
      else
        _ ->
          :ok
      end
    end)
  end
end
