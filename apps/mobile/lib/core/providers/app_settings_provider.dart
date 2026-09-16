import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _keyThemeMode = 'gastrohost_theme_mode';
  static const String _keyNotifications = 'gastrohost_notifications_enabled';
  static const String _keyOrderUpdates = 'gastrohost_order_updates_enabled';
  static const String _keyPromotional = 'gastrohost_promotional_enabled';
  static const String _keyChefMessages = 'gastrohost_chef_messages_enabled';
  static const String _keyLanguage = 'gastrohost_language';
  static const String _keyCurrency = 'gastrohost_currency';
  static const String _keySound = 'gastrohost_sound_enabled';
  static const String _keyHaptic = 'gastrohost_haptic_enabled';

  AppSettingsNotifier() : super(const AppSettingsState()) {
    _loadPersistedSettings();
    _checkInitialPermissions();
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme Mode Persistence
      final themeStr = prefs.getString(_keyThemeMode);
      ThemeMode loadedThemeMode = state.themeMode;
      if (themeStr == 'dark') {
        loadedThemeMode = ThemeMode.dark;
      } else if (themeStr == 'light') {
        loadedThemeMode = ThemeMode.light;
      } else if (themeStr == 'system') {
        loadedThemeMode = ThemeMode.system;
      }

      final notifications = prefs.getBool(_keyNotifications) ?? state.notificationsEnabled;
      final orderUpdates = prefs.getBool(_keyOrderUpdates) ?? state.orderUpdatesEnabled;
      final promotional = prefs.getBool(_keyPromotional) ?? state.promotionalEnabled;
      final chefMessages = prefs.getBool(_keyChefMessages) ?? state.chefMessagesEnabled;
      final language = prefs.getString(_keyLanguage) ?? state.language;
      final currency = prefs.getString(_keyCurrency) ?? state.currency;
      final sound = prefs.getBool(_keySound) ?? state.soundEnabled;
      final haptic = prefs.getBool(_keyHaptic) ?? state.hapticEnabled;

      state = state.copyWith(
        themeMode: loadedThemeMode,
        notificationsEnabled: notifications,
        orderUpdatesEnabled: orderUpdates,
        promotionalEnabled: promotional,
        chefMessagesEnabled: chefMessages,
        language: language,
        currency: currency,
        soundEnabled: sound,
        hapticEnabled: haptic,
      );
    } catch (e) {
      debugPrint('Error loading persisted settings: $e');
    }
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

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, isDark ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode.name);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(
      notificationsEnabled: enabled,
      orderUpdatesEnabled: enabled ? state.orderUpdatesEnabled : false,
      promotionalEnabled: enabled ? state.promotionalEnabled : false,
      chefMessagesEnabled: enabled ? state.chefMessagesEnabled : false,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifications, enabled);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> toggleOrderUpdates(bool enabled) async {
    state = state.copyWith(orderUpdatesEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOrderUpdates, enabled);
    } catch (e) {
      debugPrint('Error saving order updates: $e');
    }
  }

  Future<void> togglePromotional(bool enabled) async {
    state = state.copyWith(promotionalEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPromotional, enabled);
    } catch (e) {
      debugPrint('Error saving promotional settings: $e');
    }
  }

  Future<void> toggleChefMessages(bool enabled) async {
    state = state.copyWith(chefMessagesEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyChefMessages, enabled);
    } catch (e) {
      debugPrint('Error saving chef messages settings: $e');
    }
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

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, language);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> setCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrency, currency);
    } catch (e) {
      debugPrint('Error saving currency: $e');
    }
  }

  Future<void> toggleSound(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, enabled);
    } catch (e) {
      debugPrint('Error saving sound setting: $e');
    }
  }

  Future<void> toggleHaptic(bool enabled) async {
    state = state.copyWith(hapticEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHaptic, enabled);
    } catch (e) {
      debugPrint('Error saving haptic setting: $e');
    }
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});
