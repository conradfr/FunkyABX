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

  {
    :error,
    {
      :http_error,
      404,
      %{
        body:
          "<?xml version='1.0' encoding='UTF-8'?>\n<Error><Code>NoSuchKey</Code><Message>The specified key does not exist.</Message><RequestId>txbad292a7010642cbbed05-00635bd575</RequestId><Key>0641d264-8c0a-4c3d-8588-c02606473e55/165167472
9_1988197E85E9693364D0B7E714C8689439C8DD99.flazc</Key></Error>",
        headers: [
          {"x-amz-id-2", "txbad292a7010642cbbed05-00635bd575"},
          {"x-amz-request-id", "txbad292a7010642cbbed05-00635bd575"},
          {"content-type", "application/xml"},
          {"date", "Fri, 28 Oct 2022 13:13:25 GMT"},
          {"transfer-encoding", "chunked"}
        ],
        status_code: 404
      }
    }
  }

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
    object =
      Application.fetch_env!(:funkyabx, :bucket)
      |> ExAws.S3.list_objects_v2(prefix: test_id)
      |> ExAws.request!()

    Application.fetch_env!(:funkyabx, :bucket)
    |> ExAws.S3.delete_object(object)
    |> ExAws.request()

    filename
  end
end
