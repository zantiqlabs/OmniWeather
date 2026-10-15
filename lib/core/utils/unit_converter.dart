import '../constants/app_constants.dart';

/// Unit conversion utilities.
///
/// Open-Meteo returns data in SI units:
///   Temperature: °C
///   Wind speed:  km/h
///   Precipitation: mm
class UnitConverter {
  UnitConverter._();

  // ── Temperature ───────────────────────────────────────────────────────────

  static double celsiusToFahrenheit(double c) => c * 9 / 5 + 32;
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

  static double convertTemp(double celsius, TemperatureUnit unit) =>
      unit == TemperatureUnit.fahrenheit
          ? celsiusToFahrenheit(celsius)
          : celsius;

  static String tempUnitSymbol(TemperatureUnit unit) =>
      unit == TemperatureUnit.fahrenheit ? '°F' : '°C';

  // ── Wind ──────────────────────────────────────────────────────────────────

  static double kmhToMph(double kmh)    => kmh * 0.621371;
  static double kmhToMs(double kmh)     => kmh / 3.6;
  static double kmhToKnots(double kmh)  => kmh * 0.539957;

  static double convertWind(double kmh, WindUnit unit) => switch (unit) {
    WindUnit.mph    => kmhToMph(kmh),
    WindUnit.ms     => kmhToMs(kmh),
    WindUnit.knots  => kmhToKnots(kmh),
    WindUnit.kmh    => kmh,
  };

  static String windUnitSymbol(WindUnit unit) => switch (unit) {
    WindUnit.mph    => 'mph',
    WindUnit.ms     => 'm/s',
    WindUnit.knots  => 'kn',
    WindUnit.kmh    => 'km/h',
  };

  // ── Precipitation ─────────────────────────────────────────────────────────

  static double mmToInches(double mm) => mm / 25.4;

  static double convertPrecip(double mm, PrecipUnit unit) =>
      unit == PrecipUnit.inches ? mmToInches(mm) : mm;

  static String precipUnitSymbol(PrecipUnit unit) =>
      unit == PrecipUnit.inches ? 'in' : 'mm';

  // ── Wind direction ────────────────────────────────────────────────────────

  static String degreesToCompass(double degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}
