import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AppSettingsState {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool orderUpdatesEnabled;
  final bool promotionalEnabled;
  final bool chefMessagesEnabled;
  final bool locationPermissionGranted;
  final String locationStatusText;
  final String language;
  final String currency;
  final bool soundEnabled;
  final bool hapticEnabled;

  const AppSettingsState({
    this.themeMode = ThemeMode.light,
    this.notificationsEnabled = true,
    this.orderUpdatesEnabled = true,
    this.promotionalEnabled = false,
    this.chefMessagesEnabled = true,
    this.locationPermissionGranted = true,
    this.locationStatusText = 'Kadıköy, İstanbul (Aktif)',
    this.language = 'Türkçe',
    this.currency = 'TRY (₺)',
    this.soundEnabled = true,
    this.hapticEnabled = true,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? orderUpdatesEnabled,
    bool? promotionalEnabled,
    bool? chefMessagesEnabled,
    bool? locationPermissionGranted,
    String? locationStatusText,
    String? language,
    String? currency,
    bool? soundEnabled,
    bool? hapticEnabled,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      orderUpdatesEnabled: orderUpdatesEnabled ?? this.orderUpdatesEnabled,
      promotionalEnabled: promotionalEnabled ?? this.promotionalEnabled,
      chefMessagesEnabled: chefMessagesEnabled ?? this.chefMessagesEnabled,
      locationPermissionGranted: locationPermissionGranted ?? this.locationPermissionGranted,
      locationStatusText: locationStatusText ?? this.locationStatusText,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(const AppSettingsState()) {
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      final isGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      state = state.copyWith(
        locationPermissionGranted: isGranted,
        locationStatusText: isGranted ? 'Konum İzni Aktif' : 'Konum İzni Kapalı',
      );
    } catch (_) {}
  }

  void toggleTheme(bool isDark) {
    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleNotifications(bool enabled) {
    state = state.copyWith(
      notificationsEnabled: enabled,
      orderUpdatesEnabled: enabled ? state.orderUpdatesEnabled : false,
      promotionalEnabled: enabled ? state.promotionalEnabled : false,
      chefMessagesEnabled: enabled ? state.chefMessagesEnabled : false,
    );
  }

  void toggleOrderUpdates(bool enabled) {
    state = state.copyWith(orderUpdatesEnabled: enabled);
  }

  void togglePromotional(bool enabled) {
    state = state.copyWith(promotionalEnabled: enabled);
  }

  void toggleChefMessages(bool enabled) {
    state = state.copyWith(chefMessagesEnabled: enabled);
  }

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          locationPermissionGranted: false,
          locationStatusText: 'GPS Kapalı (Cihaz ayarlarından açın)',
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          locationPermissionGranted: false,
          locationStatusText: 'Kalıcı Reddedildi (Uygulama İzinlerinden Açın)',
        );
        return false;
      }

      final isGranted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        String formatted = 'Konum Alındı';
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final district = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? '';
          final city = place.administrativeArea ?? place.country ?? '';
          formatted = district.isNotEmpty ? '$district, $city' : city;
        }
        state = state.copyWith(
          locationPermissionGranted: true,
          locationStatusText: '$formatted (Aktif)',
        );
        return true;
      } else {
        state = state.copyWith(
          locationPermissionGranted: false,
          locationStatusText: 'İzin Verilmedi',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        locationPermissionGranted: false,
        locationStatusText: 'Hata: $e',
      );
      return false;
    }
  }

  void setLocationPermissionGranted(bool granted) {
    if (!granted) {
      state = state.copyWith(
        locationPermissionGranted: false,
        locationStatusText: 'Konum İzni Devre Dışı',
      );
    } else {
      requestLocationPermission();
    }
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void setCurrency(String currency) {
    state = state.copyWith(currency: currency);
  }

  void toggleSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
  }

  void toggleHaptic(bool enabled) {
    state = state.copyWith(hapticEnabled: enabled);
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});
