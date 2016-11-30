defmodule Solar.Events do

  @doc """
    location = LatLong.to_decimal_position "39.1373 ", "-88.65"
    Timex.today
    Date.new(2016, 11, 29)
    timezone "America/Chicago"
  """
  def sunrise_for_date zenith, location, date, timezone do
    sun_event_for_date :rise, zenith, location, date, timezone
  end
  def sunset_for_date zenith, location, date, timezone do
    sun_event_for_date :set, zenith, location, date, timezone
  end

  def sun_event_for_date type, zenith, location, date, timezone do

    { latitude, longitude } = location
    state = %{type: type, zenith: zenith, location: location,
              latitude: latitude, longitude: longitude,
              date: date, timezone: timezone}

    with  { :ok, state } <- verify_type_parameter(state),
          { :ok, state } <- get_base_longitude_hour(state),
          { :ok, state } <- get_longitude_hour(state),
          { :ok, state } <- get_mean_anomaly(state),
          { :ok, state } <- get_sun_true_longitude(state),
          { :ok, state } <- get_cos_sun_local_hour(state),
          { :ok, state } <- get_sun_local_hour(state),
          { :ok, state } <- get_right_ascension(state),
          { :ok, state } <- get_local_mean_time(state),
          { :ok, state } <- get_local_time(state) do
          state[:local_time]
    else
      error -> error
    end

  end

  defp verify_type_parameter state do
    type = state[:type]
    cond do
      type != :rise && type != :set ->
        { :error, "Type parameter must be either :rise or :set"}
      true -> { :ok, state }
    end
  end

  # Computes the longitude time.
  # Uses: location, date and type
  # Sets: longitude_hour
  defp get_longitude_hour state do
    offset = case state[:type] do
      :rise -> 6.0
      _ -> 18.0
    end

    dividend = offset - state[:longitude] / 15.0
    addend = dividend / 24.0
    longitude_hour = Timex.day(state[:date]) + addend
    { :ok, Map.put(state, :longitude_hour, longitude_hour) }
  end

  # Computes the base longitude hour, lngHour in the algorithm. The longitude
  # of the location of the solar event divided by 15 (deg/hour).

  defp get_base_longitude_hour state do
    base_longitude_hour = state[:longitude] / 15.0
    { :ok, Map.put(state, :base_longitude_hour, base_longitude_hour)}
  end

  # Computes the mean anomaly of the Sun, M in the algorithm.
  defp get_mean_anomaly state do
    mean_anomaly = state[:longitude_hour] * 0.9856 - 3.289
    { :ok, Map.put(state, :mean_anomaly, mean_anomaly) }
  end

  # Computes the true longitude of the sun, L in the algorithm, at the
  # given location, adjusted to fit in the range [0-360].
  defp get_sun_true_longitude state do
    mean_anomaly = state[:mean_anomaly]
    sin_mean_anomaly = :math.sin(deg_to_rad(mean_anomaly))
    sin_double_mean_anomoly = :math.sin(deg_to_rad(mean_anomaly * 2.0))
    first_part = mean_anomaly + (sin_mean_anomaly * 1.916)
    second_part = sin_double_mean_anomoly * 0.020 + 282.634
    true_longitude = first_part + second_part
    sun_true_longitude = case true_longitude > 360.0 do
      true -> true_longitude - 360.0
      false -> true_longitude
    end
    { :ok, Map.put(state, :sun_true_longitude, sun_true_longitude)}
  end

  defp get_cos_sun_local_hour state do
    latitude = state[:latitude]
    sin_sun_declination = :math.sin(deg_to_rad(state[:sun_true_longitude])) * 0.39782
    cos_sun_declination = :math.cos(:math.asin(sin_sun_declination))
    cos_zenith = :math.cos(deg_to_rad(state[:zenith]))
    sin_latitude = :math.sin(deg_to_rad(latitude))
    cos_latitude = :math.cos(deg_to_rad(latitude))

    cos_sun_local_hour =
      (cos_zenith - sin_sun_declination * sin_latitude) /
      (cos_sun_declination * cos_latitude)
    return = cond do
      cos_sun_local_hour < -1.0 -> {:error, "cos_sun_local_hour < -1.0"}
      cos_sun_local_hour > +1.0 -> {:error, "cos_sun_local_hour > +1.0"}
      true -> { :ok, Map.put(state, :cos_sun_local_hour, cos_sun_local_hour)}
    end
  end

  defp get_sun_local_hour state do
    local_hour = rad_to_deg(:math.acos(state[:cos_sun_local_hour]))
    local_hour = case state[:type] do
      :rise -> (360.0 - local_hour) / 15
      _ -> local_hour / 15
    end
    {:ok, Map.put(state, :sun_local_hour, local_hour)}
  end

  defp get_local_mean_time state do
    local_mean_time = state[:sun_local_hour] + state[:right_ascension] -
                      (state[:longitude_hour] * 0.06571) - 6.622
    val = cond do
      local_mean_time < 0 -> local_mean_time + 24.0
      local_mean_time > 24 -> local_mean_time - 24.0
      true -> local_mean_time
    end
    { :ok, Map.put(state, :local_mean_time, val) }
  end

  # Computes the suns right ascension, RA in the algorithm, adjusting for
  # the quadrant of L and turning it into degree-hours. Will be in the
  # range [0,360].
  defp get_right_ascension state do
    tanl = :math.tan(deg_to_rad(state[:sun_true_longitude]))
    inner = rad_to_deg(tanl) * 0.91764
    right_ascension = :math.atan(deg_to_rad(inner))
    right_ascension = rad_to_deg(right_ascension)
    right_ascension = cond do
      right_ascension < 0.0 -> right_ascension + 360.0
      right_ascension > 360.0 -> right_ascension - 360.0
      true -> right_ascension
    end

    long_quad = Kernel.trunc(state[:sun_true_longitude] / 90.0) * 90.0
    right_quad = Kernel.trunc(right_ascension / 90.0) * 90.0
    val = (right_ascension + (long_quad - right_quad)) / 15.0
    { :ok, Map.put(state, :right_ascension, val)}
  end

  defp get_local_time state do
    utc_time = state[:local_mean_time] - state[:base_longitude_hour]
    tzi = Timex.timezone(state[:timezone], state[:date])
    offset_minutes = Timex.Timezone.total_offset(tzi)
    local_time = utc_time + offset_minutes/3600.0
    { :ok, Map.put(state, :local_time, local_time)}
  end

  # Converts degrees to radians.
  defp deg_to_rad degrees do
     degrees / 180.0 * :math.pi
  end

  defp rad_to_deg radians do
    radians * 180.0 / :math.pi
  end

end
