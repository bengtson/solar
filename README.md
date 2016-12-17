# Solar - A Solar Event Calculator

Provides sunrise and sunset times for a provided location and date.

The algorithms/math used are from:

  https://github.com/mikereedell/sunrisesunsetlib-java

Code has been completely rewritten to take advantage of the Elixir language.

The event function takes a minimum of two parameters, the event of interest
which can be either :rise or :set and the latitude and longitude. Additionally
a list of options can be provided as follows:

  * `date:` allows a value of either `:today` or an Elixir date. The default
    if this option is not provided is the current day.
  - `zenith:` can be set to define the sunrise or sunset. See the `Zeniths`
    module for a set of standard zeniths that are used. The default if a
    zenith is not provided is `:official` most commonly used for sunrise and
    sunset.
    `timezone:` can be provided and should be a standard timezone identifier
    such as "America/Chicago". If the option is not provided, the timezone is
    taken from the system and used.

## Examples

The following, with out any options and run on December 25:

    iex> Solar.event (:rise, {39.1371, -88.65})
    {:ok,~T[07:12:26]}

    iex> Solar.event (:set, {39.1371, -88.65})
    {:ok,~T[16:38:01]}

The coordinates are for Lake Sara, IL where sunrise on this day will be at 7:12:26AM and sunset will be at 4:38:01PM.

The `latlong` library can be used to convert various latitude and longitude
formats to the signed numeric decimal format needed for position in the event
call.

## Road Map

* Have an optional GenServer that can emit calls based on parameters:
  * :rise, +0, :repeat, fn spawns a process to run the function at
  sunrise_for_date each day.
  * :set, -20, fn runs function 20 minutes before sunset.
* Add other events such as :equal where daylight and night are equal.
* Add winter and summer solstice.
- Add earliest sunrise and latest sunset.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `solar` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:solar, "~> 0.1.0"}]
    end
    ```
