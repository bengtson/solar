defmodule EventsTest do
  use ExUnit.Case
  doctest LatLong

  test "sun rise" do

    position = LatLong.to_decimal_position "39.1373 ", "-88.65"
    time = Solar.Events.sunrise_for_date(
        Zeniths.official, position, Timex.now("America/Chicago"), "America/Chicago")
    IO.inspect time
    hour = Kernel.trunc(time)
    tmins = (time-hour) * 60
    minute = Kernel.trunc(tmins)
    tsecs = (tmins-minute) * 60
    seconds = Kernel.trunc(tsecs)
    IO.puts "Hour: #{hour}, Minutes: #{minute}, Seconds: #{seconds}"
    time = Time.new(hour,minute,seconds)
    IO.inspect time
    assert 1 == 1
  end


end
