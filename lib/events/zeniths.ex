defmodule Zeniths do
  @moduledoc """
  Provides values for the various definitions for sunrise and sunset. These are referred to as twilight definitions.

  - Astonomical is when the sun is 18 degrees below horizon.
  - Nautical is when the sun is 12 degrees below horizon.
  - Civil is when the sun is 6 degrees below horizon.
  - Official is when the sun is 50 arcminutes below horizon.
  """

  @doc "Returns the angle for 'astonomical' sunrise and sunset"
  def astronomical, do: 90.0 + 18.0

  @doc "Returns the angle for 'nautical' sunrise and sunset"
  def nautical,     do: 90.0 + 12.0

  @doc "Returns the angle for 'civil' sunrise and sunset"
  def civil,        do: 90.0 +  6.0

  @doc "Returns the angle for 'official' sunrise and sunset"
  def official,     do: 90.0 + 50.0 / 60.0

end
