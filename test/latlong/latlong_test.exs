defmodule LatLongTest do
  use ExUnit.Case
  doctest LatLong

  test "degree conversion" do
    position = LatLong.to_decimal_position "39.1373 ", "-88.65"
    assert position == {39.1373, -88.65}
  end

  test "degree conversion with degree character" do
    position = LatLong.to_decimal_position "39.1373°", "-88.65"
    assert position == {39.1373, -88.65}
  end

  test "degree minute second conversion" do
    position = LatLong.to_decimal_position "39° 30\" 30\'", "-88.65"
    assert position == {39.50833333333333, -88.65}
  end

  test "degree minute second conversion with compass" do
    position = LatLong.to_decimal_position "39.1371°N", "88.65°W"
    assert position == {39.1371, -88.65}
  end

  test "check for compass usage error" do
    position = LatLong.to_decimal_position "39.1371°E", "88.65°W"
    assert position == {:error, -88.65}
  end

  test "check for missing minutes value" do
    position = LatLong.to_decimal_position "39° 30\'N", "88.65°W"
    assert position == {:error, -88.65}
  end

  test "check for out of range" do
    position = LatLong.to_decimal_position "39.1371°N", "188.65°W"
    assert position == {39.1371, :error}
  end


end
