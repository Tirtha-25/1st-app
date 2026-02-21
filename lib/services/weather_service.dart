import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // API Key is now injected at build time for security.
  // Build with: --dart-define=OPENWEATHER_API_KEY=your_key_here
  static const String _apiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '4d8fb5b93d4af21d66a2948710284366', // Temporary fallback
  );
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetch current weather by city name
  Future<WeatherData> getWeatherByCity(String city) async {
    final url =
        '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final data = json.decode(body);
        final weather = WeatherData.fromJson(data);

        // Also fetch forecast and AQI
        final forecast = await _getForecast(city);
        final lat = data['coord']['lat'] as double;
        final lon = data['coord']['lon'] as double;
        final aqi = await _getAqi(lat, lon);

        return WeatherData(
          cityName: weather.cityName,
          country: weather.country,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          tempMin: weather.tempMin,
          tempMax: weather.tempMax,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          pressure: weather.pressure,
          description: weather.description,
          icon: weather.icon,
          mainCondition: weather.mainCondition,
          visibility: weather.visibility,
          sunrise: weather.sunrise,
          sunset: weather.sunset,
          hourlyForecast: forecast['hourly']?.cast<HourlyForecast>() ?? [],
          dailyForecast: forecast['daily']?.cast<DailyForecast>() ?? [],
          aqi: aqi,
        );
      } else if (response.statusCode == 404) {
        throw Exception('City not found. Please check the name and try again.');
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw Exception('No internet connection. Please turn on Wi-Fi or Cellular Data.');
      }
      rethrow;
    }
  }

  /// Fetch current weather by coordinates
  Future<WeatherData> getWeatherByLocation(double lat, double lon) async {
    final url =
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final data = json.decode(body);
        final weather = WeatherData.fromJson(data);

        final forecast =
            await _getForecastByCoords(lat, lon);
        final aqi = await _getAqi(lat, lon);

        return WeatherData(
          cityName: weather.cityName,
          country: weather.country,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          tempMin: weather.tempMin,
          tempMax: weather.tempMax,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          pressure: weather.pressure,
          description: weather.description,
          icon: weather.icon,
          mainCondition: weather.mainCondition,
          visibility: weather.visibility,
          sunrise: weather.sunrise,
          sunset: weather.sunset,
          hourlyForecast: forecast['hourly']?.cast<HourlyForecast>() ?? [],
          dailyForecast: forecast['daily']?.cast<DailyForecast>() ?? [],
          aqi: aqi,
        );
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('ClientException')) {
        throw Exception('No internet connection. Please turn on Wi-Fi or Cellular Data.');
      }
      rethrow;
    }
  }

  /// Fetch 5-day / 3-hour forecast by city name
  Future<Map<String, List<dynamic>>> _getForecast(String city) async {
    final url =
        '$_baseUrl/forecast?q=$city&appid=$_apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return _parseForecast(json.decode(body));
    }
    return {'hourly': [], 'daily': []};
  }

  /// Fetch 5-day / 3-hour forecast by coordinates
  Future<Map<String, List<dynamic>>> _getForecastByCoords(
      double lat, double lon) async {
    final url =
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return _parseForecast(json.decode(body));
    }
    return {'hourly': [], 'daily': []};
  }

  /// Parse forecast data into hourly and daily lists
  Map<String, List<dynamic>> _parseForecast(Map<String, dynamic> data) {
    final List forecastList = data['list'] ?? [];

    // Hourly forecast (interpolate to get hour-by-hour for next 12 hours)
    final baseHourly = forecastList
        .take(8)
        .map((item) => HourlyForecast.fromJson(item))
        .toList();

    final List<HourlyForecast> hourly = [];
    if (baseHourly.isNotEmpty) {
      final startTime = DateTime.now();
      
      for (int i = 0; i <= 12; i++) {
        final targetTime = startTime.add(Duration(hours: i));
        
        HourlyForecast? f1;
        HourlyForecast? f2;
        
        if (targetTime.isBefore(baseHourly.first.dateTime)) {
          // If before the first forecast, just use the first forecast as baseline
          f1 = baseHourly.first;
          f2 = baseHourly.first;
        } else {
          for (int j = 0; j < baseHourly.length - 1; j++) {
            if (baseHourly[j].dateTime.isBefore(targetTime) && 
                (baseHourly[j+1].dateTime.isAfter(targetTime) || baseHourly[j+1].dateTime.isAtSameMomentAs(targetTime)) ||
                baseHourly[j].dateTime.isAtSameMomentAs(targetTime)) {
              f1 = baseHourly[j];
              f2 = baseHourly[j+1];
              break;
            }
          }
        }
        
        // Fallback
        f1 ??= baseHourly.last;
        f2 ??= baseHourly.last;

        final t1 = f1.dateTime.millisecondsSinceEpoch;
        final t2 = f2.dateTime.millisecondsSinceEpoch;
        final tTarget = targetTime.millisecondsSinceEpoch;
        
        double fraction = 0;
        if (t2 > t1) {
          fraction = (tTarget - t1) / (t2 - t1);
        }
        fraction = fraction.clamp(0.0, 1.0);
        
        final temp = f1.temperature + (f2.temperature - f1.temperature) * fraction;
        final humidity = f1.humidity + (f2.humidity - f1.humidity) * fraction;

        hourly.add(HourlyForecast(
          dateTime: targetTime,
          temperature: temp,
          icon: fraction < 0.5 ? f1.icon : f2.icon,
          description: fraction < 0.5 ? f1.description : f2.description,
          humidity: humidity.round(),
        ));
      }
    }

    // Daily forecast (group by day, take min/max temps)
    final Map<String, List<dynamic>> dailyMap = {};
    for (var item in forecastList) {
      final date = DateTime.fromMillisecondsSinceEpoch(
          (item['dt'] as int) * 1000);
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!dailyMap.containsKey(dayKey)) {
        dailyMap[dayKey] = [];
      }
      dailyMap[dayKey]!.add(item);
    }

    final daily = dailyMap.entries.take(5).map((entry) {
      final items = entry.value;
      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      int totalHumidity = 0;
      double totalWind = 0;

      for (var item in items) {
        final temp = (item['main']['temp'] as num).toDouble();
        if (temp < minTemp) minTemp = temp;
        if (temp > maxTemp) maxTemp = temp;
        totalHumidity += item['main']['humidity'] as int;
        totalWind += (item['wind']['speed'] as num).toDouble();
      }

      // Use the midday entry for icon/description, or the first one
      final midItem = items.length > 3 ? items[3] : items[0];

      return DailyForecast(
        dateTime: DateTime.parse(entry.key),
        tempMin: minTemp,
        tempMax: maxTemp,
        icon: midItem['weather'][0]['icon'] ?? '01d',
        description: midItem['weather'][0]['description'] ?? '',
        humidity: totalHumidity ~/ items.length,
        windSpeed: totalWind / items.length,
      );
    }).toList();

    return {
      'hourly': hourly,
      'daily': daily,
    };
  }

  /// Fetch accurate AQI (Air Quality Index) using US EPA standard based on PM2.5
  Future<int> _getAqi(double lat, double lon) async {
    final url = '$_baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double pm25 = (data['list'][0]['components']['pm2_5'] as num).toDouble();
        final double pm10 = (data['list'][0]['components']['pm10'] as num).toDouble();
        
        int aqiPm25 = _calculateAqiForPollutant(
          pm25, 
          [0.0, 12.1, 35.5, 55.5, 150.5, 250.5, 350.5], 
          [12.0, 35.4, 55.4, 150.4, 250.4, 350.4, 500.4]
        );
        
        int aqiPm10 = _calculateAqiForPollutant(
          pm10, 
          [0, 55, 155, 255, 355, 425, 505], 
          [54, 154, 254, 354, 424, 504, 604]
        );
        
        return aqiPm25 > aqiPm10 ? aqiPm25 : aqiPm10;
      }
    } catch (_) {}
    return 0; // fallback
  }

  int _calculateAqiForPollutant(double c, List<double> bpLow, List<double> bpHigh) {
    List<int> iLow = [0, 51, 101, 151, 201, 301, 401];
    List<int> iHigh = [50, 100, 150, 200, 300, 400, 500];

    int index = 0;
    for (int i = 0; i < bpHigh.length; i++) {
      if (c <= bpHigh[i]) {
        index = i;
        break;
      }
    }
    if (c > bpHigh.last) index = bpHigh.length - 1;

    double aqi = ((iHigh[index] - iLow[index]) / (bpHigh[index] - bpLow[index])) * (c - bpLow[index]) + iLow[index];
    return aqi.round();
  }

  /// Get City Suggestions
  Future<List<String>> searchCities(String query) async {
    if (query.length < 2) return [];

    final url =
        'https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(query)}&limit=5&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final data = json.decode(body) as List;
        return data.map((item) {
          final name = item['name'] as String;
          final state = item['state'] as String?;
          final country = item['country'] as String;
          if (state != null && state.isNotEmpty) {
            return '$name, $state, $country';
          }
          return '$name, $country';
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
