import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'supabase_service.dart';

class UserProfile {
  final String name;
  final String email;
  final String role;
  final String location;
  final double latitude;
  final double longitude;
  final String initials;
  final bool isLoadingLocation;
  final bool isVerifiedChef;

  UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.location,
    this.latitude = 40.9901,
    this.longitude = 29.0291,
    required this.initials,
    this.isLoadingLocation = false,
    this.isVerifiedChef = false,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? location,
    double? latitude,
    double? longitude,
    String? initials,
    bool? isLoadingLocation,
    bool? isVerifiedChef,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      initials: initials ?? this.initials,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      isVerifiedChef: isVerifiedChef ?? this.isVerifiedChef,
    );
  }

  factory UserProfile.defaultUser({
    String? name,
    String? email,
    String? role,
    String? location,
    double? latitude,
    double? longitude,
    bool? isVerifiedChef,
  }) {
    final finalName = name ?? 'Ahmet Yılmaz';
    final parts = finalName.trim().split(' ');
    String computedInitials = 'AY';
    if (parts.isNotEmpty) {
      computedInitials = parts.map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
      if (computedInitials.length > 2) computedInitials = computedInitials.substring(0, 2);
    }

    return UserProfile(
      name: finalName,
      email: email ?? 'ahmet.yilmaz@example.com',
      role: role ?? 'customer',
      location: location ?? 'Kadıköy, İstanbul',
      latitude: latitude ?? 40.9901,
      longitude: longitude ?? 29.0291,
      initials: computedInitials,
      isVerifiedChef: isVerifiedChef ?? false,
    );
  }
}

class UserLocationNotifier extends StateNotifier<UserProfile> {
  UserLocationNotifier() : super(UserProfile.defaultUser()) {
    loadUserProfile();
    requestDeviceLocationPermission();
  }

  Future<void> loadUserProfile() async {
    try {
      final supabaseService = SupabaseService();
      final user = supabaseService.currentUser;

      if (user != null) {
        final email = user.email ?? 'ahmet.yilmaz@example.com';
        final meta = user.userMetadata ?? {};
        final name = meta['full_name'] as String? ?? 'Ahmet Yılmaz';
        final role = meta['role'] as String? ?? 'customer';

        // Check verification status from provider_profiles
        bool isVerified = false;
        if (role == 'chef' || role == 'bartender' || role == 'admin') {
          try {
            final response = await supabaseService.client
                .from('provider_profiles')
                .select('is_verified')
                .eq('user_id', user.id)
                .maybeSingle();
            if (response != null) {
              isVerified = response['is_verified'] as bool? ?? false;
            }
          } catch (_) {}
        }

        state = UserProfile.defaultUser(
          name: name,
          email: email,
          role: role,
          location: state.location,
          latitude: state.latitude,
          longitude: state.longitude,
          isVerifiedChef: isVerified,
        );
      }
    } catch (_) {}
  }

  Future<void> refreshDeviceLocation() async {
    await requestDeviceLocationPermission();
  }


  /// Triggers Native Android/iOS Location Permission dialog and fetches live GPS coordinates
  Future<String> requestDeviceLocationPermission() async {
    state = state.copyWith(isLoadingLocation: true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLoadingLocation: false);
        return 'GPS Kapalı (Konum Açın)';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(isLoadingLocation: false);
          return 'Konum İzni Reddedildi';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLoadingLocation: false);
        return 'Konum İzni Kalıcı Reddedildi';
      }

      // Fetch live GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Reverse geocode lat/lng into city/district name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final district = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? '';
        final city = place.administrativeArea ?? place.country ?? '';
        final formattedLocation = district.isNotEmpty ? '$district, $city' : city;

        state = state.copyWith(
          location: formattedLocation,
          latitude: position.latitude,
          longitude: position.longitude,
          isLoadingLocation: false,
        );
        return formattedLocation;
      }

      final fallbackLoc = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      state = state.copyWith(
        location: fallbackLoc,
        latitude: position.latitude,
        longitude: position.longitude,
        isLoadingLocation: false,
      );
      return fallbackLoc;
    } catch (e) {
      debugPrint('Geolocator Error: $e');
      state = state.copyWith(isLoadingLocation: false);
      return state.location;
    }
  }
}

final userProfileProvider = StateNotifierProvider<UserLocationNotifier, UserProfile>((ref) {
  return UserLocationNotifier();
});

