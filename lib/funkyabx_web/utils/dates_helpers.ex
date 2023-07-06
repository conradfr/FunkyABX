defmodule FunkyABXWeb.DatesHelpers do
  @get_defaults [
    timezone: "Etc/UTC",
    format: :medium
  ]

  def format_date_time(datetime, opts \\ [])

  def format_date_time(datetime, _opts) when datetime == nil, do: ""

  def format_date_time(datetime, opts) do
    options = Keyword.merge(@get_defaults, opts) |> Enum.into(%{})

    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(options.timezone)
    |> Cldr.DateTime.to_string!(format: options.format)
  end

  def format_date(datetime, opts \\ [])

  def format_date(datetime, _opts) when datetime == nil, do: ""

  def format_date(datetime, opts) do
    options = Keyword.merge(@get_defaults, opts) |> Enum.into(%{})

    datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(options.timezone)
    |> Cldr.Date.to_string!(format: options.format)
  end
end
