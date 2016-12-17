defmodule Solar do
  @moduledoc """
  A library that provides information about the sun and in particular; events.
  This first version handles sunrise and sunset.

  All calls to `Solar` library are through this module.
  """

  @doc """
  Provides sunrise or sunset times for a provided location and date.

  The algorithms/math used are from:

    https://github.com/mikereedell/sunrisesunsetlib-java

  Code has been completely rewritten to take advantage of the Elixir language.

  The event function takes a minimum of two parameters, the event of interest
  which can be either :rise or :set and the latitude and longitude. Additionally
  a list of options can be provided as follows:

    * `date:` allows a value of either `:today` or an Elixir date. The default
      if this option is not provided is the current day.
    * `zenith:` can be set to define the sunrise or sunset. See the `Zeniths`
      module for a set of standard zeniths that are used. The default if a
      zenith is not provided is `:official` most commonly used for sunrise and
      sunset.
    * `tim*ezone:` can be provided and should be a standard timezone identifier
      such as "America/Chicago". If the option is not provided, the timezone is
      taken from the system and used.

  The following, without any options and run on December 25:

      iex> Solar.event(:rise, {39.1371, -88.65})
      {:ok,~T[07:12:26]}

      iex> Solar.event(:set, {39.1371, -88.65})
      {:ok,~T[16:38:01]}

  The coordinates are for Lake Sara, IL where sunrise on this day will be at 7:12:26AM and sunset will be at 4:38:01PM.

  The function returns the following:

      {:ok, Time}
      {:error, message}
  """
  def event(event, location, opts \\ []) do
    Solar.Events.event event, location, opts
  end

  @doc """
  Generates the sunrise, sunset times as well as the daylight hours. The following tuple is returned:

      {:ok, sunrise, sunset, daylight}

  This takes the same parameters as `Solar.event` except the event parameter.
  """
  def day_info(location, opts \\ []) do
    { :ok, rise } = Solar.Events.event :rise, location, opts
    { :ok, set } = Solar.Events.event :set, location, opts
    { :ok, rise, set, Solar.Events.daylight(rise, set) }
  end

end
