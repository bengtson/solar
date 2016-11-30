defmodule LatLong do
  @moduledoc """
  A really nice parsing of all the ways that a longitude or latitude may be specified. Comments and suggestions on how this might have been better written are welcome. The following lat long formats are allowed ... all are equivalent:

  - 38.8977, -77.0365
  - 38° 53' 51.635" N, 77° 2' 11.507" W
  - 38 53 51.635 N, 77 2 11.507 W
  - N 38° 53' 51.635", W 77° 2' 11.507"
  - N 38 53 51.635, W 77 2 11.507
  - 38 53 51.635, -77 2 11.507

  And some other examples that are for different locations:

  - -31.96, 115.84
  - 90, 0 (North Pole)
  - 41 25 01N, 120 58 57W
  - 41°25'01"N, 120°58'57"W
  - S17 33 08.352, W69 01 29.74
  - 41 25N, 120 58W
  - 41°25'N, 120°58'W
  - N41 25.117, W120 58.292
  - 41 N, 120 W
  - 41°N, 120°W
  - N41.092, W120.8362
  - 90S, 0E (South Pole)

  In addition, the latitude may be in one format and the longitude in another.

  ## Parsing

  The strings are parsed with a state machine checking the next part of the string, saving the various parts in a map. Each pass of the state machine provides the next Float if available and the next grapheme. The state machine lets the call fall to the appropriate state handler and then the next part is examined until there isn't anything left in the string.
  """

  @doc """
  Parses string representations of a latitude and longitude into decimals. The latitude and longitude must be provided as string arguments. The return is { :ok, latitude, longitude } or { :error, message }.
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

  # Called to convert latitude or longitude. 'type' is either :latitude or
  # :longitude. Angle is the string of the latitude or longitude.
  # Starts the state machine by calling next_part with the string and state.
  defp part_to_decimal_position angle, type do
    state = %{ sign: 1, degrees: 0, minutes: 0, seconds: 0, field: :degrees, type: type }
    next_part angle, state
  end

  # If string is empty, calcualte and return the parsed value.
  defp next_part "", state do
    (state[:degrees] + state[:minutes] / 60.0 + state[:seconds] / 3600.0) * state[:sign]
  end

  # Get possible value at next string position and next grapheme. Then drop
  # it into the state machine.
  defp next_part string, state do
    next_state Float.parse(string), String.next_grapheme(string), state
  end

  # Just ignore spaces. They are delimiters for float parsing already used
  # so toss.
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
  defp next_state { _, _ }, {"-", tail}, state do
    next_part tail, Map.merge(state, %{sign: -1})
  end

  # Capture a plus sign but only if a valid float was found.
  defp next_state { _, _ }, {"+", tail}, state do
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
