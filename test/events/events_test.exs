defmodule EventsTest do
  use ExUnit.Case

  # Check sunrise on Christmas day on Lake Sara
  test "sunrise event" do
    location = LatLong.parse "39.1373 ", "-88.65"
    {:ok,date} = Date.new(2016,12,25)
    opts = [date: date]
    assert {:ok,~T[07:12:26]} == Solar.Events.event :rise, location, opts
  end

  # Check sunset on Christmas day on Lake Sara
  test "sunset event" do
    location = LatLong.parse "39.1373", "-88.65"
    {:ok,date} = Date.new(2016,12,25)
    opts = [date: date]
    assert {:ok,~T[16:38:01]} == Solar.Events.event :set, location, opts
  end

end
