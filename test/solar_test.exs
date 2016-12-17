defmodule SolarTest do
  use ExUnit.Case

  # Check sunrise on Christmas day on Lake Sara
  test "sunrise event" do
    location = LatLong.parse "39.1373 ", "-88.65"
    {:ok,date} = Date.new(2016,12,25)
    opts = [date: date]
    assert {:ok,~T[07:12:26]} == Solar.event :rise, location, opts
  end

end
