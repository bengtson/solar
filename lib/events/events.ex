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
    longitude_hour = get_longitude_hour location, date, type
    mean_anomaly = get_mean_anomaly longitude_hour
    sun_true_longitude = get_sun_true_longitude mean_anomaly
    cos_sun_local_hour = get_cos_sun_local_hour sun_true_longitude, zenith, location



#    if ((cosineSunLocalHour.doubleValue() < -1.0) || (cosineSunLocalHour.doubleValue() > 1.0)) {
#    return null;
#  }

    sun_local_hour = get_sun_local_hour cos_sun_local_hour, type
    local_mean_time = get_local_mean_time(sun_true_longitude, longitude_hour,sun_local_hour)
    local_time = get_local_time(local_mean_time, location, date, timezone)

  end

  #  Computes the longitude time, t in the algorithm.
  defp get_longitude_hour location, date, rise_or_set do
    offset = cond do
      :rise -> 6.0
      :set -> 18.0
      true -> :error
    end

    dividend = offset - get_base_longitude_hour location
    addend = dividend / 24.0
    Timex.day(date) + addend
  end

  # Computes the base longitude hour, lngHour in the algorithm. The longitude
  # of the location of the solar event divided by 15 (deg/hour).
  defp get_base_longitude_hour location do
    { _, longitude } = location
    longitude / 15.0
  end

  # Computes the mean anomaly of the Sun, M in the algorithm.
  defp get_mean_anomaly longitude_hour do
    longitude_hour * 0.9856 - 3.289
  end

  # Computes the true longitude of the sun, L in the algorithm, at the
  # given location, adjusted to fit in the range [0-360].
  defp get_sun_true_longitude mean_anomaly do
    sin_mean_anomaly = :math.sin(deg_to_rad(mean_anomaly))
    sin_double_mean_anomoly = :math.sin(deg_to_rad(mean_anomaly * 2.0))
    first_part = mean_anomaly + (sin_mean_anomaly * 1.916)
    second_part = sin_double_mean_anomoly * 0.020 + 282.634
    true_longitude = first_part + second_part
    case true_longitude > 360.0 do
      true -> true_longitude - 360.0
      false -> true_longitude
    end
  end

  defp get_cos_sun_local_hour sun_true_long, zenith, location do
    { latitude, _ } = location
    sin_sun_declination = :math.sin(deg_to_rad(sun_true_long)) * 0.39782
    cos_sun_declination = :math.cos(:math.asin(sin_sun_declination))
    cos_zenith = :math.cos(deg_to_rad(zenith))
    sin_latitude = :math.sin(deg_to_rad(latitude))
    cos_latitude = :math.cos(deg_to_rad(latitude))

    (cos_zenith - sin_sun_declination * sin_latitude) /
    (cos_sun_declination * cos_latitude)
  end

  defp get_sun_local_hour cos_sun_local_hour, type do
    local_hour = rad_to_deg(:math.acos(cos_sun_local_hour))
    case type do
      :rise -> (360.0 - local_hour) / 15
      :set -> local_hour / 15
      _ -> :error
    end
  end

  defp get_local_mean_time(sun_true_longitude, longitude_hour,sun_local_hour) do
    right_ascension = get_right_ascension sun_true_longitude
    local_mean_time = sun_local_hour + right_ascension -
                      (longitude_hour * 0.06571) - 6.622
    cond do
      local_mean_time < 0 -> local_mean_time + 24.0
      local_mean_time > 24 -> local_mean_time - 24.0
      true -> local_mean_time
    end
  end

  # Computes the suns right ascension, RA in the algorithm, adjusting for
  # the quadrant of L and turning it into degree-hours. Will be in the
  # range [0,360].
  defp get_right_ascension sun_true_longitude do
    tanl = :math.tan(deg_to_rad(sun_true_longitude))
    inner = rad_to_deg(tanl) * 0.91764
    right_ascension = :math.atan(deg_to_rad(inner))
    right_ascension = rad_to_deg(right_ascension)
    right_ascension = cond do
      right_ascension < 0.0 -> right_ascension + 360.0
      right_ascension > 360.0 -> right_ascension - 360.0
      true -> right_ascension
    end

    long_quad = Kernel.trunc(sun_true_longitude / 90.0) * 90.0
    right_quad = Kernel.trunc(right_ascension / 90.0) * 90.0
    (right_ascension + (long_quad - right_quad)) / 15.0
  end

  defp get_local_time(local_mean_time, location, date, timezone) do
    utc_time = local_mean_time - get_base_longitude_hour(location)
    tzi = Timex.timezone(timezone, date)
    offset_minutes = Timex.Timezone.total_offset(tzi)
    local_time = utc_time + offset_minutes/3600.0
  end

  # Converts degrees to radians.
  defp deg_to_rad degrees do
     degrees / 180.0 * :math.pi
  end

  defp rad_to_deg radians do
    radians * 180.0 / :math.pi
  end

end
