import 'package:flutter/material.dart';

/// Returns a weather icon widget based on the OpenWeatherMap icon code
class WeatherIconHelper {
  static IconData getIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny_rounded;
      case '01n':
        return Icons.nightlight_round;
      case '02d':
        return Icons.cloud_queue_rounded;
      case '02n':
        return Icons.nights_stay_rounded;
      case '03d':
      case '03n':
        return Icons.cloud_rounded;
      case '04d':
      case '04n':
        return Icons.cloud_rounded;
      case '09d':
      case '09n':
        return Icons.grain_rounded;
      case '10d':
        return Icons.beach_access_rounded;
      case '10n':
        return Icons.water_drop_rounded;
      case '11d':
      case '11n':
        return Icons.flash_on_rounded;
      case '13d':
      case '13n':
        return Icons.ac_unit_rounded;
      case '50d':
      case '50n':
        return Icons.blur_on_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  static Color getIconColor(String iconCode) {
    switch (iconCode) {
      case '01d':
        return const Color(0xFFFFB300);
      case '01n':
        return const Color(0xFFB0BEC5);
      case '02d':
      case '03d':
      case '04d':
        return const Color(0xFFE0E0E0);
      case '02n':
      case '03n':
      case '04n':
        return const Color(0xFF90A4AE);
      case '09d':
      case '10d':
      case '09n':
      case '10n':
        return const Color(0xFF42A5F5);
      case '11d':
      case '11n':
        return const Color(0xFFFFCA28);
      case '13d':
      case '13n':
        return const Color(0xFFE0F7FA);
      case '50d':
      case '50n':
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFFFFB300);
    }
  }

  /// Returns gradient colors based on weather condition and time of day
  static List<Color> getGradient(String iconCode, String condition) {
    final bool isNight = iconCode.endsWith('n');

    if (isNight) {
      switch (condition.toLowerCase()) {
        case 'clear':
          return [
            const Color(0xFF0D1B2A),
            const Color(0xFF1B2838),
            const Color(0xFF253545),
          ];
        case 'clouds':
          return [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ];
        case 'rain':
        case 'drizzle':
          return [
            const Color(0xFF0D1117),
            const Color(0xFF161B22),
            const Color(0xFF21262D),
          ];
        case 'thunderstorm':
          return [
            const Color(0xFF0A0A0A),
            const Color(0xFF1A1A2E),
            const Color(0xFF2D2D44),
          ];
        case 'snow':
          return [
            const Color(0xFF1A1A2E),
            const Color(0xFF2D3250),
            const Color(0xFF424769),
          ];
        default:
          return [
            const Color(0xFF0D1B2A),
            const Color(0xFF1B2838),
            const Color(0xFF253545),
          ];
      }
    }

    // Daytime gradients
    switch (condition.toLowerCase()) {
      case 'clear':
        return [
          const Color(0xFF1488CC),
          const Color(0xFF2888C9),
          const Color(0xFF2B96D1),
        ];
      case 'clouds':
        return [
          const Color(0xFF4B6CB7),
          const Color(0xFF5B7DC5),
          const Color(0xFF7F9CCF),
        ];
      case 'rain':
      case 'drizzle':
        return [
          const Color(0xFF3A4750),
          const Color(0xFF455A64),
          const Color(0xFF546E7A),
        ];
      case 'thunderstorm':
        return [
          const Color(0xFF2C3E50),
          const Color(0xFF34495E),
          const Color(0xFF42576B),
        ];
      case 'snow':
        return [
          const Color(0xFF536976),
          const Color(0xFF8BA5B5),
          const Color(0xFFBBD2C5),
        ];
      case 'mist':
      case 'fog':
      case 'haze':
      case 'smoke':
        return [
          const Color(0xFF606C88),
          const Color(0xFF7A8599),
          const Color(0xFF9AA7B8),
        ];
      default:
        return [
          const Color(0xFF1488CC),
          const Color(0xFF2B86C5),
          const Color(0xFF2B96D1),
        ];
    }
  }
}
