import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../utils/weather_icons.dart';
import '../widgets/weather_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _searchController = TextEditingController();

  WeatherData? _weather;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSearching = false;

  // Multi-location support
  final List<String> _savedLocations = [];
  int _selectedLocationIndex = -1; // -1 means "current location"
  static const int _maxSavedLocations = 4;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocationWeather();
  }

  /// Get device location and load weather
  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedLocationIndex = -1;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable GPS.';
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Fallback to default city instead of showing error for better UX
        await _loadWeather('Kathmandu');
        return;
      }

      // Get current position with a more reasonable timeout and accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final weather = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      // Attempt to get a more accurate address/city name from coordinates
      String? cityName;
      if (!kIsWeb) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            // Prefer locality (City), fallback to subAdministrativeArea (District/Area)
            cityName = place.locality ?? place.subAdministrativeArea ?? place.name;
          }
        } catch (e) {
          debugPrint('Geocoding error: $e');
        }
      }

      setState(() {
        _weather = cityName != null && cityName.isNotEmpty 
            ? weather.copyWith(cityName: cityName) 
            : weather;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Location error: $e');
      
      // If we are on web and not on localhost/https, show a specific error
      if (kIsWeb && e.toString().contains('User denied Geolocation')) {
        setState(() {
          _errorMessage = 'Location denied by browser. Please allow location access.';
          _isLoading = false;
        });
        return;
      }

      // Fallback to default city for other errors (like timeout)
      try {
        await _loadWeather('Kathmandu');
      } catch (_) {
        setState(() {
          _errorMessage = 'Unable to get location or weather data. Please search manually.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWeather(String city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weather = await _weatherService.getWeatherByCity(city);
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _performSearch() {
    final city = _searchController.text.trim();
    if (city.isNotEmpty) {
      _loadWeather(city);
      _toggleSearch();
    }
  }

  void _addLocation() {
    if (_savedLocations.length >= _maxSavedLocations) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $_maxSavedLocations saved locations reached. Remove one first.',
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Location',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter city name...',
              hintStyle: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.location_city_rounded,
                  color: Colors.white.withValues(alpha: 0.4)),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    ).then((city) {
      if (city != null && city.toString().isNotEmpty) {
        setState(() {
          _savedLocations.add(city);
          _selectedLocationIndex = _savedLocations.length - 1;
        });
        _loadWeather(city);
      }
    });
  }

  void _removeLocation(int index) {
    setState(() {
      _savedLocations.removeAt(index);
      if (_selectedLocationIndex == index) {
        _selectedLocationIndex = -1;
        _loadCurrentLocationWeather();
      } else if (_selectedLocationIndex > index) {
        _selectedLocationIndex--;
      }
    });
  }

  void _selectLocation(int index) {
    if (index == -1) {
      _loadCurrentLocationWeather();
    } else {
      setState(() => _selectedLocationIndex = index);
      _loadWeather(_savedLocations[index]);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _weather != null
        ? WeatherIconHelper.getGradient(
            _weather!.icon, _weather!.mainCondition)
        : [
            const Color(0xFF0F0F1A),
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
          ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildLocationChips(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _errorMessage.isNotEmpty
                          ? _buildErrorState()
                          : _buildWeatherContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          if (!_isSearching) ...[
            const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _weather != null
                    ? '${_weather!.cityName}, ${_weather!.country}'
                    : 'Weather',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _toggleSearch,
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
            ),
            IconButton(
              onPressed: _selectedLocationIndex == -1
                  ? _loadCurrentLocationWeather
                  : () => _loadWeather(_savedLocations[_selectedLocationIndex]),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 26),
            ),
          ] else ...[
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.length < 2) {
                      return const Iterable<String>.empty();
                    }
                    return await _weatherService.searchCities(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _searchController.text = selection;
                    _performSearch();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    // Sync our controller when it changes, but primarily use the field's controller
                    if (_searchController.text != controller.text && _searchController.text.isEmpty) {
                      controller.clear();
                    } else if (_searchController.text.isNotEmpty && controller.text.isEmpty) {
                      controller.text = _searchController.text;
                    }
                    
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        hintStyle: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                         _searchController.text = val;
                      },
                      onSubmitted: (_) {
                        _searchController.text = controller.text;
                        _performSearch();
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 120,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    option,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.2, duration: 300.ms),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _toggleSearch,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // My Location chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildLocationChip(
              label: '📍 My Location',
              isSelected: _selectedLocationIndex == -1,
              onTap: () => _selectLocation(-1),
            ),
          ),

          // Saved location chips
          ..._savedLocations.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildLocationChip(
                label: entry.value,
                isSelected: _selectedLocationIndex == entry.key,
                onTap: () => _selectLocation(entry.key),
                onRemove: () => _removeLocation(entry.key),
              ),
            );
          }),

          // Add location chip
          if (_savedLocations.length < _maxSavedLocations)
            GestureDetector(
              onTap: _addLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: Colors.white.withValues(alpha: 0.5), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Add City',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildLocationChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.4), size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'Detecting your location...',
            style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                color: Colors.white.withValues(alpha: 0.5), size: 80),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Search another city'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_weather == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _selectedLocationIndex == -1
          ? _loadCurrentLocationWeather()
          : _loadWeather(_savedLocations[_selectedLocationIndex]),
      color: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 30),

            Icon(
              WeatherIconHelper.getIcon(_weather!.icon),
              color: WeatherIconHelper.getIconColor(_weather!.icon),
              size: 100,
            ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.elasticOut),

            const SizedBox(height: 10),

            Text(
              '${_weather!.temperature.round()}°',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 96,
                fontWeight: FontWeight.w200,
                height: 1.0,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(
                begin: 0.2, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 4),

            Text(
              _weather!.description[0].toUpperCase() +
                  _weather!.description.substring(1),
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Feels like ${_weather!.feelsLike.round()}°',
                  style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
                Text('  •  ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                Text(
                  'H:${_weather!.tempMax.round()}°  L:${_weather!.tempMin.round()}°',
                  style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
                Text('  •  ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.air, size: 14, color: _getAqiColor(_weather!.aqi)),
                    const SizedBox(width: 4),
                    Text(
                      'AQI: ${_weather!.aqi}',
                      style: GoogleFonts.outfit(
                          color: _getAqiColor(_weather!.aqi),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: 36),

            HourlyForecastWidget(forecast: _weather!.hourlyForecast)
                .animate().fadeIn(duration: 500.ms, delay: 400.ms),

            const SizedBox(height: 24),
            WeatherDetailCards(weather: _weather!),
            const SizedBox(height: 24),

            DailyForecastWidget(forecast: _weather!.dailyForecast)
                .animate().fadeIn(duration: 500.ms, delay: 500.ms),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.greenAccent;        // Good
    if (aqi <= 100) return Colors.yellowAccent;      // Moderate
    if (aqi <= 150) return Colors.orangeAccent;      // Unhealthy for Sensitive Groups
    if (aqi <= 200) return Colors.redAccent;         // Unhealthy
    if (aqi <= 300) return Colors.purpleAccent;      // Very Unhealthy
    if (aqi > 300) return const Color(0xFF800000);   // Hazardous
    return Colors.white70;                           // Unknown
  }
}
