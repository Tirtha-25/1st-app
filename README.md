# Optimized Weather & News App 🌤️📰

An elegant, high-performance Flutter application that combines real-time weather data with global news headlines.

## ✨ Key Features
- **Smart Weather**: Accurate weather data, 5-day forecasts, and Air Quality Index (AQI) powered by OpenWeatherMap.
- **Dynamic News**: Parallel fetching of top stories from Google News, Yahoo News, and Reddit.
- **Fluid Performance**: 
  - Persistent metadata caching using `SharedPreferences`.
  - Multi-threaded XML parsing with `compute()`.
  - Optimized image loading with `cached_network_image`.
- **Modern UI**: Dark-themed, glassmorphism-inspired design with smooth animations.
- **Automated Deployment**: Integrated GitHub Actions for continuous delivery to GitHub Pages.

## 🚀 Getting Started

### Local Development
To run the app locally, you need to provide an OpenWeatherMap API Key:

```bash
flutter run --dart-define=OPENWEATHER_API_KEY=YOUR_KEY_HERE
```

### Build APK (Android 13+)
```bash
flutter build apk --release
```

## 🛠 Tech Stack
- **Framework**: Flutter (Dart)
- **API**: OpenWeatherMap, Google News RSS, Reddit JSON
- **Packages**: `geolocator`, `geocoding`, `cached_network_image`, `flutter_animate`, `shared_preferences`, `connectivity_plus`.
