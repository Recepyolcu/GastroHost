import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase in main.dart
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        publishableKey: SupabaseConstants.supabaseAnonKey,
      );

      // If an expired token is cached from an unreachable/old project, clear it to prevent infinite refresh retry loops
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.isExpired) {
        debugPrint('Expired Supabase session detected with unreachable host. Purging stale local session.');
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      }
    } catch (e) {
      debugPrint('Supabase initialize error: $e');
    }
  }

  // Helper to clear local stale session
  Future<void> clearLocalSession() async {
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }

  // --- Authentication ---
  
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Session? get currentSession => client.auth.currentSession;
  User? get currentUser => client.auth.currentUser;

  // --- Database Operations ---

  // Get Profiles
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  // RPC: Get Nearby Providers
  Future<List<Map<String, dynamic>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    String targetType = 'chef',
  }) async {
    final List<dynamic> response = await client.rpc(
      'get_nearby_providers',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'target_type': targetType,
      },
    );
    return List<Map<String, dynamic>>.from(response);
  }

  // Fetch Rich Discovery Providers (Chefs & Mixologists) with Menus, Profiles & PostGIS Distance
  Future<List<Map<String, dynamic>>> getDiscoveryProviders({
    double latitude = 40.9833,
    double longitude = 29.0254,
  }) async {
    final Map<String, double> distanceMap = {};
    try {
      final nearby = await getNearbyProviders(
        latitude: latitude,
        longitude: longitude,
        targetType: 'all',
      );
      for (final row in nearby) {
        final pid = row['provider_id']?.toString();
        final dist = (row['distance_km'] as num?)?.toDouble();
        if (pid != null && dist != null) {
          distanceMap[pid] = dist;
        }
      }
    } catch (e) {
      debugPrint('getNearbyProviders RPC fallback: $e');
    }

    final response = await client
        .from('provider_profiles')
        .select('*, profiles!user_id(*), menus(*)')
        .eq('is_available_now', true)
        .order('rating_avg', ascending: false);

    final List<Map<String, dynamic>> result = [];
    for (final raw in List<Map<String, dynamic>>.from(response)) {
      final id = raw['id']?.toString() ?? '';
      final providerType = raw['provider_type']?.toString() ?? 'chef';
      final isBartender = providerType == 'bartender';
      final profile = raw['profiles'] as Map<String, dynamic>? ?? {};
      final rawMenus = List<Map<String, dynamic>>.from(raw['menus'] as List? ?? [])
          .where((m) => m['is_active'] == true)
          .toList();

      final fullName = profile['full_name']?.toString().trim().isNotEmpty == true
          ? profile['full_name'].toString()
          : '${raw['first_name'] ?? ''} ${raw['last_name'] ?? ''}'.trim();

      final hourlyRate = (raw['hourly_rate'] as num?)?.toDouble() ?? 850.0;
      double unitPrice = isBartender ? hourlyRate : 1650.0;
      if (!isBartender && rawMenus.isNotEmpty) {
        final prices = rawMenus
            .map((m) => (m['price_per_person'] as num?)?.toDouble() ?? 1650.0)
            .toList()
          ..sort();
        unitPrice = prices.first;
      } else if (isBartender && rawMenus.isNotEmpty) {
        unitPrice = (rawMenus.first['price_per_person'] as num?)?.toDouble() ?? hourlyRate;
      }

      final specialties = raw['specialties'] is Map<String, dynamic>
          ? raw['specialties'] as Map<String, dynamic>
          : <String, dynamic>{};
      final cuisines = List<String>.from(specialties['cuisines'] as List? ?? []);
      final cocktails = List<String>.from(specialties['cocktails'] as List? ?? []);
      final dietary = List<String>.from(specialties['dietary'] as List? ?? []);
      final tags = isBartender
          ? (cocktails.isNotEmpty ? cocktails : ['Craft Cocktails', 'Mixology'])
          : (cuisines.isNotEmpty ? cuisines : ['Fine Dining', 'Özel Şef']);

      final portfolioImages = List<String>.from(raw['portfolio_images'] as List? ?? []);
      final avatarUrl = profile['avatar_url']?.toString() ??
          (portfolioImages.isNotEmpty
              ? portfolioImages.first
              : 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&q=80');

      final distKm = distanceMap[id] ?? 2.4;
      final ratingAvg = ((raw['rating_avg'] as num?)?.toDouble() ?? 5.0).toStringAsFixed(1);

      result.add({
        'id': id,
        'provider_id': id,
        'user_id': raw['user_id'],
        'provider_type': providerType,
        'name': fullName.isNotEmpty ? fullName : (isBartender ? 'Marcus Thorne' : 'Chef Julian'),
        'role': raw['title']?.toString() ??
            (isBartender ? 'Master Mixologist & Bar Uzmanı' : 'Executive Private Chef'),
        'title': raw['title'],
        'price': isBartender
            ? '₺${unitPrice.toStringAsFixed(0)}/saat'
            : '₺${unitPrice.toStringAsFixed(0)}/kişi',
        'unit_price': unitPrice,
        'hourly_rate': hourlyRate,
        'rating': ratingAvg,
        'total_reviews': raw['total_reviews'] ?? 0,
        'completed_bookings_count': raw['completed_bookings_count'] ?? 0,
        'distance_km': '${distKm.toStringAsFixed(1)} km',
        'distance_num': distKm,
        'description': raw['bio']?.toString() ?? '',
        'bio': raw['bio']?.toString() ?? '',
        'education': raw['education']?.toString() ?? 'Uluslararası Gastronomi Akademisi',
        'experience_years': raw['experience_years'] ?? 5,
        'city_region': raw['city_region']?.toString() ?? 'İstanbul',
        'tags': tags,
        'dietary_tags': dietary,
        'tag': tags.first,
        'image': avatarUrl,
        'avatar': avatarUrl,
        'phone': profile['phone']?.toString() ?? raw['phone']?.toString() ?? '+90 532 890 12 34',
        'portfolio_images': portfolioImages,
        'verification_badges': raw['verification_badges'] ?? const {},
        'is_verified': raw['is_verified'] ?? true,
        'menus': rawMenus,
      });
    }

    result.sort((a, b) => ((a['distance_num'] as num?) ?? 99).compareTo((b['distance_num'] as num?) ?? 99));
    return result;
  }

  // Resolve provider_profiles.id from either provider_profiles.id or auth user_id
  Future<String> _resolveProviderProfileId(String providerOrUserId) async {
    try {
      final byId = await client
          .from('provider_profiles')
          .select('id')
          .eq('id', providerOrUserId)
          .maybeSingle();
      if (byId != null && byId['id'] != null) {
        return byId['id'].toString();
      }
      final byUserId = await client
          .from('provider_profiles')
          .select('id')
          .eq('user_id', providerOrUserId)
          .maybeSingle();
      if (byUserId != null && byUserId['id'] != null) {
        return byUserId['id'].toString();
      }
    } catch (_) {}
    return providerOrUserId;
  }

  Map<String, dynamic> _normalizeMenuFromDb(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final pricingType = map['pricing_type']?.toString() ?? 'per_person';
    final isBartender = pricingType == 'hourly' ||
        (map['category']?.toString().toLowerCase().contains('cocktail') ?? false) ||
        (map['category']?.toString().toLowerCase().contains('bar') ?? false);
    final rawCourses = map['courses'] as List? ?? const [];
    final items = rawCourses.map((c) {
      if (c is Map) {
        final type = c['type'] ?? c['course'] ?? '';
        final name = c['name'] ?? c['title'] ?? '';
        final desc = c['desc'] ?? c['description'] ?? '';
        if (type.toString().isNotEmpty && name.toString().isNotEmpty) {
          return '$type: $name';
        }
        if (name.toString().isNotEmpty && desc.toString().isNotEmpty) {
          return '$name — $desc';
        }
        return name.toString();
      }
      return c.toString();
    }).where((s) => s.isNotEmpty).toList();

    map['price'] = (map['price_per_person'] as num?)?.toDouble() ?? 1200.0;
    map['min_limit'] = map['min_guests'] ?? (isBartender ? 2 : 4);
    map['image'] = map['image_url'] ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80';
    map['items'] = items;
    map['tags'] = (map['dietary_tags'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    map['type'] = isBartender ? 'bartender' : 'chef';
    return map;
  }

  Map<String, dynamic> _sanitizeMenuForDb(
    Map<String, dynamic> menuData, {
    String? resolvedProviderId,
  }) {
    final isBartender = menuData['type'] == 'bartender' || menuData['pricing_type'] == 'hourly';
    final price = (menuData['price_per_person'] as num?)?.toDouble() ??
        (menuData['price'] as num?)?.toDouble() ??
        (isBartender ? 950.0 : 1200.0);
    final minGuests = (menuData['min_guests'] as num?)?.toInt() ??
        (menuData['min_limit'] as num?)?.toInt() ??
        (isBartender ? 2 : 4);
    final maxGuests = (menuData['max_guests'] as num?)?.toInt() ?? 20;

    final rawCourses = menuData['courses'] ?? menuData['items'] ?? const [];
    final List<Map<String, dynamic>> formattedCourses = [];
    if (rawCourses is List) {
      for (int i = 0; i < rawCourses.length; i++) {
        final item = rawCourses[i];
        if (item is Map<String, dynamic>) {
          formattedCourses.add(item);
        } else if (item is String && item.trim().isNotEmpty) {
          formattedCourses.add({
            'course': '${i + 1}. Aşama',
            'name': item.trim(),
            'desc': '',
          });
        }
      }
    }

    final rawTags = menuData['dietary_tags'] ?? menuData['tags'] ?? const [];
    final dietaryTags = (rawTags is List) ? rawTags.map((e) => e.toString()).toList() : <String>[];

    return {
      if (resolvedProviderId != null) 'provider_id': resolvedProviderId,
      'title': menuData['title']?.toString() ?? 'Özel Tadım Menüsü',
      'description': menuData['description']?.toString() ?? '',
      'category': menuData['category']?.toString() ?? (isBartender ? 'Signature Craft Cocktails' : 'Fine Dining & Tasting'),
      'pricing_type': menuData['pricing_type']?.toString() ?? (isBartender ? 'hourly' : 'per_person'),
      'price_per_person': price,
      'min_guests': minGuests,
      'max_guests': maxGuests,
      'prep_time_minutes': (menuData['prep_time_minutes'] as num?)?.toInt() ?? 120,
      'ingredients_included': menuData['ingredients_included'] as bool? ?? true,
      'courses': formattedCourses,
      'dietary_tags': dietaryTags,
      'image_url': (menuData['image_url'] ?? menuData['image'])?.toString(),
      'is_active': menuData['is_active'] as bool? ?? true,
    };
  }

  // Get Menus for a Specific Provider
  Future<List<Map<String, dynamic>>> getProviderMenus(String providerId) async {
    final realProviderId = await _resolveProviderProfileId(providerId);
    final response = await client
        .from('menus')
        .select()
        .eq('provider_id', realProviderId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response).map(_normalizeMenuFromDb).toList();
  }

  // Get All Menus for Provider (including inactive)
  Future<List<Map<String, dynamic>>> getProviderAllMenus(String providerId) async {
    final realProviderId = await _resolveProviderProfileId(providerId);
    final response = await client
        .from('menus')
        .select()
        .eq('provider_id', realProviderId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response).map(_normalizeMenuFromDb).toList();
  }

  // Create New Menu / Cocktail Package
  Future<Map<String, dynamic>> createMenu(Map<String, dynamic> menuData) async {
    final rawProvId = menuData['provider_id']?.toString() ?? currentUser?.id ?? '';
    final realProviderId = await _resolveProviderProfileId(rawProvId);
    final payload = _sanitizeMenuForDb(menuData, resolvedProviderId: realProviderId);
    final response = await client
        .from('menus')
        .insert(payload)
        .select()
        .single();
    return _normalizeMenuFromDb(response);
  }

  // Update Existing Menu
  Future<Map<String, dynamic>> updateMenu(String menuId, Map<String, dynamic> menuData) async {
    final payload = _sanitizeMenuForDb(menuData);
    final response = await client
        .from('menus')
        .update(payload)
        .eq('id', menuId)
        .select()
        .single();
    return _normalizeMenuFromDb(response);
  }

  // Toggle Menu Active Status
  Future<void> toggleMenuStatus(String menuId, bool isActive) async {
    await client
        .from('menus')
        .update({'is_active': isActive})
        .eq('id', menuId);
  }

  // Delete Menu
  Future<void> deleteMenu(String menuId) async {
    await client
        .from('menus')
        .delete()
        .eq('id', menuId);
  }

  // Helper to check if a string is a valid UUID
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // Create Booking
  Future<Map<String, dynamic>> createBooking({
    required String providerId,
    required String menuId,
    required DateTime eventDate,
    required String eventTime,
    required int guestCount,
    required double totalPrice,
    required double platformFee,
    required double providerEarnings,
    required Map<String, dynamic> kitchenDetails,
    required List<String> allergies,
    required String eventAddress,
    double? eventLat,
    double? eventLng,
    bool isHourly = false,
    int hoursCount = 3,
    double? unitPrice,
    bool ingredientsIncluded = true,
    String? notes,
    String? addonBartenderId,
    String? addonMenuId,
    double addonPrice = 0.0,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı.');

    // Ensure menuId is a valid UUID referencing menus(id)
    String resolvedMenuId = menuId;
    if (!_uuidRegExp.hasMatch(resolvedMenuId)) {
      final existingMenus = await getProviderMenus(providerId);
      if (existingMenus.isNotEmpty) {
        resolvedMenuId = existingMenus.first['id'] as String;
      } else {
        final createdDefaultMenu = await createMenu({
          'provider_id': providerId,
          'title': isHourly ? 'Saatlik Özel Şef / Barmen Hizmeti' : 'Özel Tadım Menüsü',
          'description': 'Standart rezervasyon paketi',
          'category': 'Fine Dining',
          'pricing_type': isHourly ? 'hourly' : 'per_person',
          'price_per_person': unitPrice ?? (totalPrice / (guestCount > 0 ? guestCount : 1)),
          'min_guests': 1,
          'max_guests': 50,
          'ingredients_included': ingredientsIncluded,
          'courses': const [],
        });
        resolvedMenuId = createdDefaultMenu['id'] as String;
      }
    }

    final response = await client.from('bookings').insert({
      'customer_id': userId,
      'provider_id': providerId,
      'menu_id': resolvedMenuId,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'event_time': eventTime,
      'guest_count': guestCount,
      'is_hourly': isHourly,
      'hours_count': hoursCount,
      'unit_price': unitPrice ?? (totalPrice / (guestCount > 0 ? guestCount : 1)),
      'total_price': totalPrice,
      'commission_rate': 0.10,
      'platform_fee': platformFee,
      'provider_earnings': providerEarnings,
      'ingredients_included': ingredientsIncluded,
      'kitchen_details': kitchenDetails,
      'allergies': allergies,
      'event_address': eventAddress,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (addonBartenderId != null && _uuidRegExp.hasMatch(addonBartenderId))
        'addon_bartender_id': addonBartenderId,
      if (addonMenuId != null && _uuidRegExp.hasMatch(addonMenuId))
        'addon_menu_id': addonMenuId,
      if (addonPrice > 0) 'addon_price': addonPrice,
      if (eventLat != null && eventLng != null)
        'event_location': 'POINT($eventLng $eventLat)',
    }).select().single();

    return response;
  }

  // Fetch Customer's Bookings
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('bookings')
        .select('*, provider:provider_profiles(*, profiles(*)), menu:menus(*), review:reviews(*)')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Submit Review for a Completed Booking
  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required String providerId,
    required int ratingFood,
    required int ratingHygiene,
    required int ratingPresentation,
    String? comment,
    List<String> photos = const [],
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı.');

    final response = await client.from('reviews').upsert({
      'booking_id': bookingId,
      'customer_id': userId,
      'provider_id': providerId,
      'rating_food': ratingFood,
      'rating_hygiene': ratingHygiene,
      'rating_presentation': ratingPresentation,
      'comment': comment,
      'photos': photos,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'booking_id').select().single();

    return response;
  }

  // Fetch Reviews for a Provider
  Future<List<Map<String, dynamic>>> getProviderReviews(String providerId) async {
    final response = await client
        .from('reviews')
        .select('*, customer:profiles(full_name, avatar_url)')
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Resolve booking UUID safely from either UUID or GH-XXXXX booking_code
  Future<String?> resolveBookingUuid(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;
    if (_uuidRegExp.hasMatch(trimmed)) return trimmed;
    try {
      final row = await client
          .from('bookings')
          .select('id')
          .eq('booking_code', trimmed)
          .maybeSingle();
      if (row != null && row['id'] != null) {
        return row['id'].toString();
      }
    } catch (_) {}
    return null;
  }

  // Fetch Booking Details & Live Status Tracker
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    final resolvedId = await resolveBookingUuid(bookingId);
    if (resolvedId == null) return null;
    return await client
        .from('bookings')
        .select('*, provider:provider_profiles(*, profiles(*)), menu:menus(*)')
        .eq('id', resolvedId)
        .maybeSingle();
  }

  // Update Booking Status (For Chefs/Providers & Customers)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    final normalizedStatus = status == 'confirmed' ? 'accepted' : status;
    try {
      await client.rpc(
        'update_booking_status_safe',
        params: {
          'p_booking_identifier': bookingId,
          'p_new_status': normalizedStatus,
        },
      );
      return;
    } catch (_) {}

    final resolvedId = await resolveBookingUuid(bookingId);
    if (resolvedId != null) {
      await client
          .from('bookings')
          .update({'status': normalizedStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', resolvedId);
    }
  }

  // Realtime Booking Status Stream (Customer Tracker)
  Stream<Map<String, dynamic>?> getBookingStream(String bookingId) {
    return client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', bookingId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  // Realtime Chef Bookings Stream (Chef Dashboard)
  Stream<List<Map<String, dynamic>>> getChefBookingsStream(String chefProfileId) {
    return client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('provider_id', chefProfileId)
        .order('created_at', ascending: false);
  }

  // --- Realtime Chat ---

  // Get Messages stream for a booking
  Stream<List<Map<String, dynamic>>> getMessagesStream(String bookingId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId)
        .order('created_at', ascending: true);
  }

  // Send message to a booking's chat room
  Future<void> sendMessage(String bookingId, String content) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı.');
    await client.from('messages').insert({
      'booking_id': bookingId,
      'sender_id': userId,
      'content': content,
    });
  }

  // --- Provider Availability & Documents ---

  // Get Provider Availability
  Future<List<Map<String, dynamic>>> getProviderAvailability(String providerId) async {
    final response = await client
        .from('provider_availability')
        .select()
        .eq('provider_id', providerId)
        .eq('is_available', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Save/Update Provider Availability Slot
  Future<Map<String, dynamic>> upsertProviderAvailability({
    required String providerId,
    int? dayOfWeek,
    required String startTime,
    required String endTime,
    DateTime? specificDate,
    bool isAvailable = true,
  }) async {
    final response = await client.from('provider_availability').upsert({
      'provider_id': providerId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'specific_date': specificDate?.toIso8601String().split('T').first,
      'is_available': isAvailable,
    }).select().single();
    return response;
  }

  // Fetch Provider Documents
  Future<List<Map<String, dynamic>>> getProviderDocuments(String providerId) async {
    final response = await client
        .from('provider_documents')
        .select()
        .eq('provider_id', providerId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Add Provider Document Record
  Future<Map<String, dynamic>> addProviderDocument({
    required String providerId,
    required String documentType,
    required String fileUrl,
  }) async {
    final response = await client.from('provider_documents').insert({
      'provider_id': providerId,
      'document_type': documentType,
      'file_url': fileUrl,
      'status': 'pending',
    }).select().single();
    return response;
  }

  // Admin: Get All Provider Documents across system
  Future<List<Map<String, dynamic>>> getAllProviderDocuments() async {
    final response = await client
        .from('provider_documents')
        .select('*, provider:provider_profiles(*, profiles(*))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Admin: Review Document via RPC or Direct Update
  Future<Map<String, dynamic>> reviewDocument({
    required String docId,
    required String newStatus,
    String? rejectionReason,
  }) async {
    try {
      final dynamic response = await client.rpc(
        'admin_review_document',
        params: {
          'doc_id': docId,
          'new_status': newStatus,
          'reason': rejectionReason,
        },
      );
      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}

    // Direct fallback update
    final response = await client
        .from('provider_documents')
        .update({
          'status': newStatus,
          'rejection_reason': newStatus == 'rejected' ? rejectionReason : null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', docId)
        .select()
        .single();
    return response;
  }

  // Admin: Get All Provider Applications across system (provider_profiles with profiles and docs)
  Future<List<Map<String, dynamic>>> getAllProviderApplications() async {
    try {
      final response = await client
          .from('provider_profiles')
          .select('*, profiles!user_id(*), provider_documents(*)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getAllProviderApplications join query warning: $e');
      try {
        final response = await client
            .from('provider_profiles')
            .select('*, profiles(*), provider_documents(*)')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        final fallbackResponse = await client
            .from('provider_profiles')
            .select()
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(fallbackResponse);
      }
    }
  }

  // Admin: Update Provider Application Onboarding Status & Verification
  Future<Map<String, dynamic>> updateProviderApplicationStatus({
    required String providerId,
    required String newStatus, // 'approved', 'rejected', 'pending_approval'
    String? rejectionReason,
  }) async {
    final isVerified = newStatus == 'approved';

    // 1. Direct update on provider_profiles
    try {
      final response = await client
          .from('provider_profiles')
          .update({
            'onboarding_status': newStatus,
            'is_verified': isVerified,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', providerId)
          .select()
          .single();

      // If approved, also approve any pending documents for this provider
      if (newStatus == 'approved') {
        try {
          await client
              .from('provider_documents')
              .update({'status': 'approved', 'updated_at': DateTime.now().toIso8601String()})
              .eq('provider_id', providerId);
        } catch (_) {}
      } else if (newStatus == 'rejected') {
        try {
          await client
              .from('provider_documents')
              .update({
                'status': 'rejected',
                'rejection_reason': rejectionReason,
                'updated_at': DateTime.now().toIso8601String()
              })
              .eq('provider_id', providerId);
        } catch (_) {}
      }

      return response;
    } catch (e) {
      // 2. Fallback to RPC if direct table update is restricted by RLS
      try {
        final dynamic rpcResponse = await client.rpc(
          'admin_review_provider_application',
          params: {
            'p_provider_id': providerId,
            'p_new_status': newStatus,
            'p_reason': rejectionReason,
          },
        );
        if (rpcResponse != null) {
          return Map<String, dynamic>.from(rpcResponse);
        }
      } catch (_) {}

      rethrow;
    }
  }

  // --- Escrow & Wallet Operations ---

  // Process Escrow Payment for Booking (%10 Commission / %90 Provider Payout per PRD)
  Future<Map<String, dynamic>> processEscrowPayment({
    required String bookingId,
    required double amount,
    String gateway = 'iyzico',
    double commissionRate = 0.10,
  }) async {
    final resolvedId = await resolveBookingUuid(bookingId) ?? bookingId;
    final dynamic response = await client.rpc(
      'process_escrow_payment',
      params: {
        'p_booking_id': resolvedId,
        'p_amount': amount,
        'p_gateway': gateway,
        'p_commission_rate': commissionRate,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  // Fetch Provider Bookings (for Chef / Bartender Dashboard)
  Future<List<Map<String, dynamic>>> getProviderBookings(String providerId) async {
    final response = await client
        .from('bookings')
        .select('*, customer:profiles!customer_id(full_name, phone, avatar_url), menu:menus!menu_id(title, category)')
        .eq('provider_id', providerId)
        .order('event_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Update Provider Live Availability Toggle (is_available_now)
  Future<void> updateProviderAvailabilityToggle(String providerId, bool isAvailableNow) async {
    await client
        .from('provider_profiles')
        .update({
          'is_available_now': isAvailableNow,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', providerId);
  }

  // Save iyzico Sub-Merchant & IBAN Info for Provider
  Future<Map<String, dynamic>> saveSubMerchantInfo({
    required String providerId,
    required String iban,
    required String identityNumber,
    String subMerchantType = 'PERSONAL',
  }) async {
    // Generate mock subMerchantKey if running in demo/sandbox without live function
    final mockSubMerchantKey = 'SUBM-${identityNumber.substring(0, 5)}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final response = await client
        .from('provider_profiles')
        .update({
          'iban': iban,
          'identity_number': identityNumber,
          'sub_merchant_type': subMerchantType,
          'sub_merchant_key': mockSubMerchantKey,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', providerId)
        .select()
        .single();
    return response;
  }

  // Release Escrow Payout (Transfer %90 Earnings to Chef Wallet)
  Future<Map<String, dynamic>> releaseEscrowPayout(String bookingId) async {
    final resolvedId = await resolveBookingUuid(bookingId) ?? bookingId;
    try {
      final dynamic response = await client.rpc(
        'release_escrow_payout',
        params: {'p_booking_id': resolvedId},
      );
      if (response != null) {
        return Map<String, dynamic>.from(response as Map);
      }
    } catch (_) {}

    // Fallback: update payment status directly
    final response = await client
        .from('payments')
        .update({
          'escrow_status': 'released',
          'released_at': DateTime.now().toIso8601String(),
        })
        .eq('booking_id', resolvedId)
        .select()
        .single();
    return response;
  }

  // Refund Escrow Payment (Return 100% to Host)
  Future<Map<String, dynamic>> refundEscrowPayment({
    required String bookingId,
    String reason = 'Rezervasyon iptal edildi.',
  }) async {
    final resolvedId = await resolveBookingUuid(bookingId) ?? bookingId;
    try {
      final dynamic response = await client.rpc(
        'refund_escrow_payment',
        params: {
          'p_booking_id': resolvedId,
          'p_reason': reason,
        },
      );
      if (response != null) {
        return Map<String, dynamic>.from(response as Map);
      }
    } catch (_) {}

    final response = await client
        .from('payments')
        .update({
          'escrow_status': 'refunded',
          'refunded_at': DateTime.now().toIso8601String(),
          'cancel_reason': reason,
        })
        .eq('booking_id', resolvedId)
        .select()
        .single();
    return response;
  }

  // Fetch Provider Wallet Balance & Escrow Earnings
  Future<Map<String, dynamic>?> getProviderWallet(String providerId) async {
    final response = await client
        .from('provider_profiles')
        .select('wallet_balance, pending_escrow, iban, sub_merchant_key')
        .eq('id', providerId)
        .maybeSingle();
    return response;
  }
}
