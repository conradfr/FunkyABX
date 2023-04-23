defmodule Toast do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:id, :string)
    field(:message, :string)
    field(:type, Ecto.Enum, values: [:success, :error])
  end

  def new(message, type \\ :success) when is_binary(message) do
    %Toast{
      id: System.unique_integer([:positive]) |> Integer.to_string(),
      message: message,
      type: type
    }
  end
end
