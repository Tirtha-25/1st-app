class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final String description;
  final String icon;
  final String mainCondition;
  final int visibility;
  final DateTime sunrise;
  final DateTime sunset;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;
  final int aqi;

  WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.description,
    required this.icon,
    required this.mainCondition,
    required this.visibility,
    required this.sunrise,
    required this.sunset,
    this.hourlyForecast = const [],
    this.dailyForecast = const [],
    this.aqi = 0,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? '',
      country: json['sys']?['country'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      pressure: json['main']['pressure'] as int,
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '01d',
      mainCondition: json['weather'][0]['main'] ?? '',
      visibility: json['visibility'] ?? 10000,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (json['sys']['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          (json['sys']['sunset'] as int) * 1000),
      aqi: json['aqi'] ?? 0,
    );
  }
}

class HourlyForecast {
  final DateTime dateTime;
  final double temperature;
  final String icon;
  final String description;
  final int humidity;

  HourlyForecast({
    required this.dateTime,
    required this.temperature,
    required this.icon,
    required this.description,
    required this.humidity,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      dateTime:
          DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      icon: json['weather'][0]['icon'] ?? '01d',
      description: json['weather'][0]['description'] ?? '',
      humidity: json['main']['humidity'] as int,
    );
  }
}

class DailyForecast {
  final DateTime dateTime;
  final double tempMin;
  final double tempMax;
  final String icon;
  final String description;
  final int humidity;
  final double windSpeed;

  DailyForecast({
    required this.dateTime,
    required this.tempMin,
    required this.tempMax,
    required this.icon,
    required this.description,
    required this.humidity,
    required this.windSpeed,
  });
}
