import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../utils/weather_icons.dart';

class WeatherDetailCards extends StatelessWidget {
  final WeatherData weather;

  const WeatherDetailCards({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '${weather.humidity}%',
                color: const Color(0xFF42A5F5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailCard(
                icon: Icons.air_rounded,
                label: 'Wind',
                value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                color: const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: Icons.compress_rounded,
                label: 'Pressure',
                value: '${weather.pressure} hPa',
                color: const Color(0xFFAB47BC),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailCard(
                icon: Icons.visibility_rounded,
                label: 'Visibility',
                value: '${(weather.visibility / 1000).toStringAsFixed(1)} km',
                color: const Color(0xFFFF7043),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: Icons.wb_sunny_outlined,
                label: 'Sunrise',
                value: DateFormat('hh:mm a').format(weather.sunrise),
                color: const Color(0xFFFFB300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailCard(
                icon: Icons.nights_stay_outlined,
                label: 'Sunset',
                value: DateFormat('hh:mm a').format(weather.sunset),
                color: const Color(0xFFE91E63),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
  }
}

class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecast> forecast;

  const HourlyForecastWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Hourly Forecast',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: forecast.length,
            itemBuilder: (context, index) {
              final item = forecast[index];
              final isNow = index == 0;
              return Container(
                width: 85,
                margin: EdgeInsets.only(right: index < forecast.length - 1 ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isNow
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNow
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      isNow ? 'Now' : DateFormat('HH:mm').format(item.dateTime),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: isNow ? 1.0 : 0.7),
                        fontSize: 13,
                        fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Icon(
                      WeatherIconHelper.getIcon(item.icon),
                      color: WeatherIconHelper.getIconColor(item.icon),
                      size: 28,
                    ),
                    Text(
                      '${item.temperature.round()}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: (index * 80).ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
            },
          ),
        ),
      ],
    );
  }
}

class DailyForecastWidget extends StatelessWidget {
  final List<DailyForecast> forecast;

  const DailyForecastWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '5-Day Forecast',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: List.generate(forecast.length, (index) {
              final item = forecast[index];
              final isToday = index == 0;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            isToday
                                ? 'Today'
                                : DateFormat('EEE').format(item.dateTime),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 
                                  isToday ? 1.0 : 0.8),
                              fontSize: 15,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          WeatherIconHelper.getIcon(item.icon),
                          color: WeatherIconHelper.getIconColor(item.icon),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.tempMin.round()}°',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF42A5F5),
                                const Color(0xFFFF7043),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '${item.tempMax.round()}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < forecast.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                      indent: 18,
                      endIndent: 18,
                    ),
                ],
              )
                  .animate(delay: (index * 100).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
            }),
          ),
        ),
      ],
    );
  }
}
