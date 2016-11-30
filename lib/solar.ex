defmodule Solar do
  def sunrise_for_date zenith, location, date, timezone do
    Solar.Events.sun_event_for_date :rise, zenith, location, date, timezone
  end
  def sunset_for_date zenith, location, date, timezone do
    Solar.Events.sun_event_for_date :set, zenith, location, date, timezone
  end
end
