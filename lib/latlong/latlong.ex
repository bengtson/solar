defmodule LatLong do

  @moduledoc """
  Signed degrees format (DDD.dddd)

  A latitude or longitude with 8 decimal places pinpoints a location to within 1 millimeter,( 1/16 inch).

  Precede South latitudes and West longitudes with a minus sign.
  Latitudes range from -90 to 90.
  Longitudes range from -180 to 180.
  41.25 and -120.9762
  -31.96 and 115.84
  90 and 0 (North Pole)
  DMS + compass direction formats

  These formats use degrees, minutes, and seconds. For the following formats:
  Latitudes range from 0 to 90.
  Longitudes range from 0 to 180.
  Use N, S, E or W as either the first or last character, which represents a compass direction North, South, East or West.
  The last degree, minute, or second of a latitude or longitude may contain a decimal portion.
  Degrees minutes seconds formats (DDD MM SS + compass direction)

  41 25 01N and 120 58 57W
  41°25'01"N and 120°58'57"W
  S17 33 08.352 and W69 01 29.74

  Degrees minutes formats (DDD MM + compass direction)

  41 25N and 120 58W
  41°25'N and 120°58'W
  N41 25.117 and W120 58.292 (Common geocoding format)

  Degrees only formats (DDD + compass direction)

  41 N and 120 W
  41°N and 120°W
  N41.092 and W120.8362
  90S and 0E (South Pole)

  """
  def to_decimal_position latitude, longitude do
    latitude_value = part_to_decimal_position latitude, :latitude
    longitude_value = part_to_decimal_position longitude, :longitude
    latitude_value = cond do
      latitude_value < -90.0 -> :error
      latitude_value > +90.0 -> :error
      true -> latitude_value
    end
    longitude_value = cond do
      longitude_value < -180.0 -> :error
      longitude_value > +180.0 -> :error
      true -> longitude_value
    end
    {latitude_value, longitude_value}
  end

  defp part_to_decimal_position angle, type do
    state = %{ sign: 1, degrees: 0, minutes: 0, seconds: 0, field: :degrees, type: type }
    next_part angle, state
  end

  # If string is empty, return the parsed value.
  defp next_part "", state do
    (state[:degrees] + state[:minutes] / 60.0 + state[:seconds] / 3600.0) * state[:sign]
  end

  # Get possible value at next string position and next grapheme.
  defp next_part string, state do
    next_state Float.parse(string), String.next_grapheme(string), state
  end

  # Just ignore spaces. They are delimiters for float parsing but toss.
  defp next_state :error, {" ", tail}, state do
    next_part tail, state
  end

  # Check for degrees sign. Must be found when field has moved to minutes.
  defp next_state :error, {"°", tail}, %{field: :minutes} = state do
    next_part tail, state
  end

  # Check for minutes sign. Must be found when field has moved to seconds.
  defp next_state :error, {"\"", tail}, %{field: :seconds} = state do
    next_part tail, state
  end

  # Check for seconds sign. Must be found when field has moved to nil.
  defp next_state :error, {"\'", tail}, %{field: :nil} = state do
    next_part tail, state
  end

  # Capture a minus sign but only if a valid float was found.
  defp next_state { value, _ }, {"-", tail}, state do
    next_part tail, Map.merge(state, %{sign: -1})
  end

  # Capture a plus sign but only if a valid float was found.
  defp next_state { value, _ }, {"+", tail}, state do
    next_part tail, Map.merge(state, %{sign: 1})
  end

  # North sets sign to + but only if type is latitude.
  defp next_state :error, {"N", tail}, %{type: :latitude} = state do
    next_part tail, Map.merge(state, %{sign: 1})
  end

  # South sets sign to - but only if type is latitude.
  defp next_state :error, {"S", tail}, %{type: :latitude} = state do
    next_part tail, Map.merge(state, %{sign: -1})
  end

  # East sets sign to + but only if type is longitude.
  defp next_state :error, {"E", tail}, %{type: :longitude} = state do
    next_part tail, Map.merge(state, %{sign: 1})
  end

  # West sets sign to - but only if type is longitude.
  defp next_state :error, {"W", tail}, %{type: :longitude} = state do
    next_part tail, Map.merge(state, %{sign: -1})
  end

  # Capture the value for degrees. Set field to minutes.
  defp next_state({ value, tail }, _, %{field: :degrees} = state) do
    next_part tail, Map.merge(state, %{degrees: value, field: :minutes})
  end

  # Capture the value for minutes. Set field to seconds.
  defp next_state({ value, tail }, _, %{field: :minutes} = state) do
    next_part tail, Map.merge(state, %{minutes: value, field: :seconds})
  end

  # Capture the value for seconds. Set field to nil.
  defp next_state({ value, tail }, _, %{field: :seconds} = state) do
    next_part tail, Map.merge(state, %{seconds: value, field: :nil})
  end

  # Return an error for this parse.
  defp next_state(_,_,_) do
    :error
  end
end
