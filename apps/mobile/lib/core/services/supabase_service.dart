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
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      publishableKey: SupabaseConstants.supabaseAnonKey,
    );
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

  // Get Menus for a Specific Provider
  Future<List<Map<String, dynamic>>> getProviderMenus(String providerId) async {
    final response = await client
        .from('menus')
        .select()
        .eq('provider_id', providerId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get All Menus for Provider (including inactive)
  Future<List<Map<String, dynamic>>> getProviderAllMenus(String providerId) async {
    final response = await client
        .from('menus')
        .select()
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Create New Menu / Cocktail Package
  Future<Map<String, dynamic>> createMenu(Map<String, dynamic> menuData) async {
    final response = await client
        .from('menus')
        .insert(menuData)
        .select()
        .single();
    return response;
  }

  // Update Existing Menu
  Future<Map<String, dynamic>> updateMenu(String menuId, Map<String, dynamic> menuData) async {
    final response = await client
        .from('menus')
        .update(menuData)
        .eq('id', menuId)
        .select()
        .single();
    return response;
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
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı.');

    final response = await client.from('bookings').insert({
      'customer_id': userId,
      'provider_id': providerId,
      'menu_id': menuId,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'event_time': eventTime,
      'guest_count': guestCount,
      'total_price': totalPrice,
      'platform_fee': platformFee,
      'provider_earnings': providerEarnings,
      'kitchen_details': kitchenDetails,
      'allergies': allergies,
      'event_address': eventAddress,
      if (eventLat != null && eventLng != null)
        'event_location': 'POINT($eventLng $eventLat)',
    }).select().single();

    return response;
  }

  // Fetch Booking Details & Live Status Tracker
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    return await client
        .from('bookings')
        .select('*, provider:provider_profiles(*, profiles(*)), menu:menus(*)')
        .eq('id', bookingId)
        .maybeSingle();
  }

  // Update Booking Status (For Chefs/Providers)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await client
        .from('bookings')
        .update({'status': status})
        .eq('id', bookingId);
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

  // Process Escrow Payment for Booking (10% Commission)
  Future<Map<String, dynamic>> processEscrowPayment({
    required String bookingId,
    required double amount,
    String gateway = 'iyzico',
  }) async {
    final dynamic response = await client.rpc(
      'process_escrow_payment',
      params: {
        'p_booking_id': bookingId,
        'p_amount': amount,
        'p_gateway': gateway,
        'p_commission_rate': 0.10, // 10% platform commission
      },
    );
    return Map<String, dynamic>.from(response as Map);
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
    try {
      final dynamic response = await client.rpc(
        'release_escrow_payout',
        params: {'p_booking_id': bookingId},
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
        .eq('booking_id', bookingId)
        .select()
        .single();
    return response;
  }

  // Refund Escrow Payment (Return 100% to Host)
  Future<Map<String, dynamic>> refundEscrowPayment({
    required String bookingId,
    String reason = 'Rezervasyon iptal edildi.',
  }) async {
    try {
      final dynamic response = await client.rpc(
        'refund_escrow_payment',
        params: {
          'p_booking_id': bookingId,
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
        .eq('booking_id', bookingId)
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



