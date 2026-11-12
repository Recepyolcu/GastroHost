import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

class ProcurementItem {
  final String name;
  final String quantity;
  final String origin;
  final String providedBy; // 'Şef Karşılıyor (%100 Dahil)' or 'Ev Sahibi / Mutfak'
  final bool isProcured;

  const ProcurementItem({
    required this.name,
    required this.quantity,
    this.origin = 'Taze / Yerel Gurme Pazar',
    this.providedBy = 'Şef Karşılıyor (%100 Dahil)',
    this.isProcured = true,
  });
}

class BookingModel {
  final String id; // Display booking code (e.g. GH-99104)
  final String? dbId; // Actual PostgreSQL UUID (bookings.id)
  final String providerId;
  final String providerName;
  final String providerRole;
  final String providerImage;
  final String providerRating;
  final String providerPhone;
  final String menuId;
  final String menuTitle;
  final String menuDescription;
  final List<String> courses;
  final List<ProcurementItem> procurementItems;
  final String procurementResponsible; // Kim tarafından karşılanıyor
  final DateTime eventDate;
  final String eventTime;
  final int guestCount;
  final int hoursCount;
  final bool isHourly;
  final String address;
  final Map<String, bool> kitchenDetails;
  final List<String> allergies;
  final double unitPrice;
  final double totalPrice;
  final double platformFee;
  final double providerEarnings;
  final String status; // 'confirmed', 'shopping', 'on_the_way', 'in_kitchen', 'completed', 'cancelled'
  final DateTime createdAt;
  final String paymentMethod;
  final String? notes;
  final bool isReviewed;
  final double? ratingFood;
  final double? ratingHygiene;
  final double? ratingPresentation;
  final double? ratingOverall;
  final String? reviewComment;
  final DateTime? reviewedAt;

  bool get isActive => status != 'completed' && status != 'cancelled';

  const BookingModel({
    required this.id,
    this.dbId,
    required this.providerId,
    required this.providerName,
    required this.providerRole,
    required this.providerImage,
    required this.providerRating,
    this.providerPhone = '+90 (532) 890 12 34',
    required this.menuId,
    required this.menuTitle,
    required this.menuDescription,
    required this.courses,
    required this.procurementItems,
    this.procurementResponsible = 'Şef / Hizmet Sağlayıcı Tarafından Karşılanır (%100 Taze & Gurme Tedarik)',
    required this.eventDate,
    required this.eventTime,
    required this.guestCount,
    this.hoursCount = 3,
    this.isHourly = false,
    required this.address,
    required this.kitchenDetails,
    required this.allergies,
    required this.unitPrice,
    required this.totalPrice,
    required this.platformFee,
    required this.providerEarnings,
    this.status = 'on_the_way',
    required this.createdAt,
    this.paymentMethod = 'iyzico Escrow (%10 Güvenceli)',
    this.notes,
    this.isReviewed = false,
    this.ratingFood,
    this.ratingHygiene,
    this.ratingPresentation,
    this.ratingOverall,
    this.reviewComment,
    this.reviewedAt,
  });

  BookingModel copyWith({
    String? id,
    String? dbId,
    String? providerId,
    String? providerName,
    String? providerRole,
    String? providerImage,
    String? providerRating,
    String? providerPhone,
    String? menuId,
    String? menuTitle,
    String? menuDescription,
    List<String>? courses,
    List<ProcurementItem>? procurementItems,
    String? procurementResponsible,
    DateTime? eventDate,
    String? eventTime,
    int? guestCount,
    int? hoursCount,
    bool? isHourly,
    String? address,
    Map<String, bool>? kitchenDetails,
    List<String>? allergies,
    double? unitPrice,
    double? totalPrice,
    double? platformFee,
    double? providerEarnings,
    String? status,
    DateTime? createdAt,
    String? paymentMethod,
    String? notes,
    bool? isReviewed,
    double? ratingFood,
    double? ratingHygiene,
    double? ratingPresentation,
    double? ratingOverall,
    String? reviewComment,
    DateTime? reviewedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      dbId: dbId ?? this.dbId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerRole: providerRole ?? this.providerRole,
      providerImage: providerImage ?? this.providerImage,
      providerRating: providerRating ?? this.providerRating,
      providerPhone: providerPhone ?? this.providerPhone,
      menuId: menuId ?? this.menuId,
      menuTitle: menuTitle ?? this.menuTitle,
      menuDescription: menuDescription ?? this.menuDescription,
      courses: courses ?? this.courses,
      procurementItems: procurementItems ?? this.procurementItems,
      procurementResponsible: procurementResponsible ?? this.procurementResponsible,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      guestCount: guestCount ?? this.guestCount,
      hoursCount: hoursCount ?? this.hoursCount,
      isHourly: isHourly ?? this.isHourly,
      address: address ?? this.address,
      kitchenDetails: kitchenDetails ?? this.kitchenDetails,
      allergies: allergies ?? this.allergies,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      platformFee: platformFee ?? this.platformFee,
      providerEarnings: providerEarnings ?? this.providerEarnings,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isReviewed: isReviewed ?? this.isReviewed,
      ratingFood: ratingFood ?? this.ratingFood,
      ratingHygiene: ratingHygiene ?? this.ratingHygiene,
      ratingPresentation: ratingPresentation ?? this.ratingPresentation,
      ratingOverall: ratingOverall ?? this.ratingOverall,
      reviewComment: reviewComment ?? this.reviewComment,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

class BookingState {
  final List<BookingModel> bookings;
  final String? activeBookingId;
  final bool isLoading;

  const BookingState({
    this.bookings = const [],
    this.activeBookingId,
    this.isLoading = false,
  });

  BookingModel? get activeBooking {
    if (bookings.isEmpty) return null;
    if (activeBookingId != null) {
      try {
        return bookings.firstWhere((b) => b.id == activeBookingId);
      } catch (_) {}
    }
    return bookings.first;
  }

  bool get hasActiveBooking =>
      bookings.any((b) => b.status != 'completed' && b.status != 'cancelled');

  BookingModel? get currentActiveBooking {
    try {
      return bookings.firstWhere((b) => b.status != 'completed' && b.status != 'cancelled');
    } catch (_) {
      return null;
    }
  }

  BookingState copyWith({
    List<BookingModel>? bookings,
    String? activeBookingId,
    bool? isLoading,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      activeBookingId: activeBookingId ?? this.activeBookingId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier() : super(_initialState()) {
    loadBookingsFromSupabase();
  }

  Future<void> loadBookingsFromSupabase() async {
    try {
      final supabase = SupabaseService();
      if (supabase.currentUser == null) return;

      final rows = await supabase.getUserBookings();
      if (rows.isEmpty) return;

      final List<BookingModel> loaded = rows.map((row) {
        final providerMap = row['provider'] as Map<String, dynamic>? ?? {};
        final profileMap = providerMap['profiles'] as Map<String, dynamic>? ?? {};
        final menuMap = row['menu'] as Map<String, dynamic>? ?? {};
        final reviewRaw = row['review'];
        final Map<String, dynamic>? reviewMap = reviewRaw is List
            ? (reviewRaw.isNotEmpty ? reviewRaw.first as Map<String, dynamic> : null)
            : (reviewRaw as Map<String, dynamic>?);

        final isBartender = providerMap['provider_type'] == 'bartender';
        final rawCourses = menuMap['courses'] as List? ?? [];
        final parsedCourses = rawCourses.map((c) {
          if (c is Map) {
            return '${c['type'] ?? 'Tabak'}: ${c['name'] ?? ''}';
          }
          return c.toString();
        }).toList();

        final rawAllergies = row['allergies'] as List? ?? [];
        final parsedAllergies = rawAllergies.map((a) => a.toString()).toList();

        final bookingCode = row['booking_code']?.toString() ?? row['id'].toString();
        final rawStatus = row['status']?.toString() ?? 'accepted';
        final normalizedStatus = rawStatus == 'confirmed' ? 'accepted' : rawStatus;

        final rawKitchen = row['kitchen_details'];
        final Map<String, bool> parsedKitchen = {
          'stove': true,
          'oven': true,
          'blender': true,
        };
        if (rawKitchen is Map) {
          parsedKitchen['stove'] = rawKitchen['stove'] == true || rawKitchen['stove_type'] != null;
          parsedKitchen['oven'] = rawKitchen['oven'] == true || rawKitchen['has_oven'] == true;
          parsedKitchen['blender'] = rawKitchen['blender'] == true || rawKitchen['has_blender'] == true;
          if (rawKitchen.containsKey('mobile_bar') || rawKitchen.containsKey('has_ice_maker')) {
            parsedKitchen['mobile_bar'] = rawKitchen['mobile_bar'] == true || rawKitchen['has_ice_maker'] == true;
          }
        }

        final rawProcurement = row['procurement_items'];
        final List<ProcurementItem> parsedProcurement = [];
        if (rawProcurement is List && rawProcurement.isNotEmpty) {
          for (final item in rawProcurement) {
            if (item is Map) {
              parsedProcurement.add(
                ProcurementItem(
                  name: (item['name'] ?? item['item'] ?? 'Gurme Tedarik Kalemi').toString(),
                  quantity: (item['quantity'] ?? 'Standart').toString(),
                  origin: (item['origin'] ?? 'Taze / Yerel Gurme Pazar').toString(),
                  providedBy: row['ingredients_included'] == false
                      ? 'Ev Sahibi / Mutfak'
                      : 'Şef Karşılıyor (%100 Dahil)',
                  isProcured: item['status'] != 'pending',
                ),
              );
            }
          }
        }

        final resolvedTotal = (row['total_price'] as num?)?.toDouble() ?? 6600.0;
        final resolvedFee = (row['platform_fee'] as num?)?.toDouble() ?? (resolvedTotal * 0.10);
        final resolvedEarnings = (row['provider_earnings'] as num?)?.toDouble() ?? (resolvedTotal - resolvedFee);

        return BookingModel(
          id: bookingCode,
          dbId: row['id']?.toString(),
          providerId: row['provider_id']?.toString() ?? '',
          providerName: profileMap['full_name']?.toString() ??
              '${providerMap['first_name'] ?? ''} ${providerMap['last_name'] ?? ''}'.trim(),
          providerRole: providerMap['title']?.toString() ??
              (isBartender ? 'Master Mixologist' : 'Executive Chef'),
          providerImage: profileMap['avatar_url']?.toString() ??
              'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&q=80',
          providerRating: ((providerMap['rating_avg'] as num?)?.toDouble() ?? 4.9).toStringAsFixed(1),
          providerPhone: profileMap['phone']?.toString() ?? '+90 (532) 890 12 34',
          menuId: row['menu_id']?.toString() ?? '',
          menuTitle: menuMap['title']?.toString() ?? 'Özel Tadım Menüsü',
          menuDescription: menuMap['description']?.toString() ?? '',
          courses: parsedCourses.isNotEmpty
              ? parsedCourses
              : const ['Başlangıç & İmza Ana Yemek Seçkisi'],
          procurementItems: parsedProcurement.isNotEmpty
              ? parsedProcurement
              : const [
                  ProcurementItem(
                    name: 'Taze Gurme Malzeme & Tedarik Paketi',
                    quantity: 'Tam Set',
                    origin: 'Yerel Üretici & Gurme Pazar',
                    providedBy: 'Şef Karşılıyor (%100 Dahil)',
                    isProcured: true,
                  ),
                ],
          procurementResponsible: row['ingredients_included'] == false
              ? 'Malzeme Listesi Ev Sahibi Tarafından Temin Edilir (%20 İndirimli)'
              : 'Şef / Hizmet Sağlayıcı Tarafından Karşılanır (%100 Taze & Gurme Tedarik)',
          eventDate: DateTime.tryParse(row['event_date']?.toString() ?? '') ?? DateTime.now(),
          eventTime: (row['event_time']?.toString() ?? '19:30').substring(0, 5),
          guestCount: (row['guest_count'] as num?)?.toInt() ?? 4,
          hoursCount: (row['hours_count'] as num?)?.toInt() ?? 3,
          isHourly: row['is_hourly'] == true || isBartender,
          address: row['event_address']?.toString() ?? '',
          kitchenDetails: parsedKitchen,
          allergies: parsedAllergies.isNotEmpty ? parsedAllergies : const ['Belirtilen alerjen yok'],
          unitPrice: (row['unit_price'] as num?)?.toDouble() ?? 1650.0,
          totalPrice: resolvedTotal,
          platformFee: resolvedFee,
          providerEarnings: resolvedEarnings,
          status: normalizedStatus,
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          notes: row['notes']?.toString(),
          isReviewed: reviewMap != null,
          ratingFood: (reviewMap?['rating_food'] as num?)?.toDouble(),
          ratingHygiene: (reviewMap?['rating_hygiene'] as num?)?.toDouble(),
          ratingPresentation: (reviewMap?['rating_presentation'] as num?)?.toDouble(),
          ratingOverall: (reviewMap?['rating_overall'] as num?)?.toDouble(),
          reviewComment: reviewMap?['comment']?.toString(),
        );
      }).toList();

      state = state.copyWith(
        bookings: loaded,
        activeBookingId: loaded.first.id,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('loadBookingsFromSupabase warning: $e');
    }
  }

  static BookingState _initialState() {
    final now = DateTime.now();
    // Default active event is scheduled 2 days from now at 19:30
    final targetDate = now.add(const Duration(days: 2));

    final defaultActive = BookingModel(
      id: 'GH-94821',
      providerId: 'p1',
      providerName: 'Chef Julian',
      providerRole: 'Executive Chef & Gastronomi Danışmanı',
      providerImage: 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
      providerRating: '4.9',
      providerPhone: '+90 (532) 412 88 90',
      menuId: 'menu_truffle_01',
      menuTitle: 'Tuscan Truffle & Fine Dining Deneyimi',
      menuDescription: 'Alba beyaz trüf mantarı, taze el yapımı tagliolini ve dinlendirilmiş Chianina dana bonfile ile 4 aşamalı imza menü.',
      courses: [
        'Amuse-Bouche: Trüf Yağlı & Ricottalı Bruschetta',
        'Başlangıç: Burrata Peyniri, İncir Carpaccio & Balzamik İncileri',
        'Ana Yemek: Taze El Açması Tagliolini al Tartufo Bianco & Chianina Dana Bonfile',
        'Tatlı: Yaban Mersinli Panna Cotta & Bitter Çikolata Ganaj',
      ],
      procurementResponsible: 'Şef Tarafından Karşılanır (%100 Taze & Yerel Tedarik Dahil)',
      procurementItems: [
        const ProcurementItem(
          name: 'Alba Beyaz Trüf Mantarı',
          quantity: '50 gr',
          origin: 'Piemonte / İtalya İthal',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: '00 Taş Değirmen İtalyan Unu',
          quantity: '500 gr',
          origin: 'Organik Gurme Market',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: '24 Ay Dinlendirilmiş Parmigiano Reggiano',
          quantity: '250 gr',
          origin: 'Parma / İtalya',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Chianina Dana Bonfile (Dry-Aged)',
          quantity: '900 gr',
          origin: 'Özel Besi Çiftliği / Balıkesir',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Taze Burrata ve Manda Ricottası',
          quantity: '4 adet',
          origin: 'Günlük Mandıra / Çatalca',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Zeytinyağı, Kaya Tuzu & Karabiber Değirmeni',
          quantity: 'Standart',
          origin: 'Ev Sahibi Mutfağı',
          providedBy: 'Ev Sahibi / Mutfakta Mevcut',
          isProcured: true,
        ),
      ],
      eventDate: targetDate,
      eventTime: '19:30',
      guestCount: 4,
      hoursCount: 4,
      isHourly: false,
      address: 'Caferağa Mah. Moda Cad. No:14 D:3, Kadıköy / İstanbul',
      kitchenDetails: const {
        'stove': true,
        'oven': true,
        'blender': true,
        'mobile_bar': false,
      },
      allergies: const [
        '1 Davetli Fıstık / Ceviz Alerjisi',
        'Glutensiz tabaklama seçeneği ayrıldı',
      ],
      unitPrice: 2250.0,
      totalPrice: 9000.0,
      platformFee: 900.0,
      providerEarnings: 8100.0,
      status: 'confirmed',
      createdAt: now.subtract(const Duration(hours: 3)),
      notes: 'Girişte güvenlikten 3 numaralı daire ziline basılabilir. Mutfak hazırlığı için 1 saat önceden giriş rica olunur.',
    );

    final pastBooking = BookingModel(
      id: 'GH-82194',
      providerId: 'm1',
      providerName: 'Marcus T.',
      providerRole: 'Master Mixologist & Bar Danışmanı',
      providerImage: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80',
      providerRating: '4.9',
      providerPhone: '+90 (533) 678 90 12',
      menuId: 'menu_cocktail_01',
      menuTitle: 'Artisan Craft Cocktails & Botanicals',
      menuDescription: 'Dumanlı meşe infüzyonları, taze narenciye ve moleküler kokteyl sunumu.',
      courses: [
        'Hoşgeldiniz: Smoked Rosemary Old Fashioned',
        'İmza Sunum: Hibiscus & Bergamot Infused Gin Tonic',
        'Tadım: Truffle & Honey Bourbon Sour',
        'Kapanış: Espresso Martini & Organik Vanilya Köpüğü',
      ],
      procurementResponsible: 'Barmen Tarafından Karşılanır (İçkiler, Şuruplar & Buz Dahil)',
      procurementItems: [
        const ProcurementItem(
          name: 'Premium Bourbon & Artisan Botanik Cin',
          quantity: '2 Şişe',
          origin: 'Özel Kav',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Organik Bergamot & Kan Portakalı',
          quantity: '1.5 kg',
          origin: 'Bodrum Narenciye Bahçesi',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Taze Biberiye & Hibiskus Kurusu',
          quantity: '200 gr',
          origin: 'Mısır Çarşısı',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Kalıp Kristal Elmas Buz & Garnitür',
          quantity: '5 kg',
          origin: 'GastroIce Istanbul',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Kokteyl Kadehleri & Bardak Seti',
          quantity: '12 Adet',
          origin: 'Barmen Ekipman Çantası',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
      ],
      eventDate: now.subtract(const Duration(days: 7)),
      eventTime: '20:00',
      guestCount: 6,
      hoursCount: 3,
      isHourly: true,
      address: 'Bebek Mah. Cevdetpaşa Cad. No:42, Beşiktaş / İstanbul',
      kitchenDetails: const {
        'stove': false,
        'oven': false,
        'blender': true,
        'mobile_bar': true,
      },
      allergies: const ['Alkol hassasiyeti olan 1 davetli için özel mocktail talep edildi'],
      unitPrice: 850.0,
      totalPrice: 2550.0,
      platformFee: 255.0,
      providerEarnings: 2295.0,
      status: 'completed',
      createdAt: now.subtract(const Duration(days: 8)),
      isReviewed: true,
      ratingFood: 5.0,
      ratingHygiene: 4.8,
      ratingPresentation: 5.0,
      ratingOverall: 4.93,
      reviewComment: 'Marcus harika kokteyller hazırladı, dumanlı infüzyonlar gecenin yıldızı oldu! Mutfak tertemiz teslim edildi.',
      reviewedAt: now.subtract(const Duration(days: 6)),
    );

    return BookingState(
      bookings: [defaultActive, pastBooking],
      activeBookingId: defaultActive.id,
      isLoading: false,
    );
  }

  void setActiveBooking(String bookingId) {
    state = state.copyWith(activeBookingId: bookingId);
  }

  void updateBookingStatus(String bookingId, String newStatus) {
    final normalizedStatus = newStatus == 'confirmed' ? 'accepted' : newStatus;
    String? targetDbId;
    final updatedList = state.bookings.map((b) {
      if (b.id == bookingId || b.dbId == bookingId) {
        targetDbId = b.dbId;
        return b.copyWith(status: normalizedStatus);
      }
      return b;
    }).toList();
    state = state.copyWith(bookings: updatedList);

    // Sync status update to Supabase safely without UUID cast errors
    Future.microtask(() async {
      try {
        final supabase = SupabaseService();
        await supabase.updateBookingStatus(targetDbId ?? bookingId, normalizedStatus);
      } catch (_) {}
    });
  }

  Future<void> confirmCompletionAndReleaseEscrow(String bookingId) async {
    String? targetDbId;
    final updatedList = state.bookings.map((b) {
      if (b.id == bookingId || b.dbId == bookingId) {
        targetDbId = b.dbId;
        return b.copyWith(status: 'completed');
      }
      return b;
    }).toList();
    state = state.copyWith(bookings: updatedList);

    try {
      final supabase = SupabaseService();
      await supabase.releaseEscrowPayout(targetDbId ?? bookingId);
    } catch (_) {}
  }

  void submitReview({
    required String bookingId,
    required double ratingFood,
    required double ratingHygiene,
    required double ratingPresentation,
    required String comment,
  }) {
    final overall = double.parse(((ratingFood + ratingHygiene + ratingPresentation) / 3.0).toStringAsFixed(2));
    BookingModel? targetBooking;
    final updatedList = state.bookings.map((b) {
      if (b.id == bookingId || b.dbId == bookingId) {
        targetBooking = b;
        return b.copyWith(
          isReviewed: true,
          ratingFood: ratingFood,
          ratingHygiene: ratingHygiene,
          ratingPresentation: ratingPresentation,
          ratingOverall: overall,
          reviewComment: comment,
          reviewedAt: DateTime.now(),
        );
      }
      return b;
    }).toList();
    state = state.copyWith(bookings: updatedList);

    // Persist review to Supabase reviews table safely
    Future.microtask(() async {
      try {
        final supabase = SupabaseService();
        final resolvedUuid = targetBooking?.dbId ?? await supabase.resolveBookingUuid(bookingId);
        if (resolvedUuid != null) {
          final row = await supabase.client
              .from('bookings')
              .select('id, provider_id')
              .eq('id', resolvedUuid)
              .maybeSingle();
          if (row != null) {
            await supabase.submitReview(
              bookingId: row['id'] as String,
              providerId: row['provider_id'] as String,
              ratingFood: ratingFood.round().clamp(1, 5),
              ratingHygiene: ratingHygiene.round().clamp(1, 5),
              ratingPresentation: ratingPresentation.round().clamp(1, 5),
              comment: comment,
            );
          }
        }
      } catch (e) {
        debugPrint('Supabase submitReview sync warning: $e');
      }
    });
  }

  BookingModel addBooking({
    required Map<String, dynamic> provider,
    required Map<String, dynamic> menu,
    required DateTime eventDate,
    required TimeOfDay eventTime,
    required int guestCount,
    required int hoursCount,
    required String address,
    required Map<String, bool> kitchenDetails,
    required List<String> allergies,
    required double totalPrice,
    required double platformFee,
    required double providerEarnings,
    double? unitPrice,
    bool? isHourly,
    bool ingredientsIncluded = true,
    String? notes,
    String? customBookingId,
    String? dbUuid,
  }) {
    final isBartender = provider['provider_type'] == 'bartender' ||
        (provider['price']?.toString().contains('/hr') ?? false) ||
        (provider['id']?.toString().startsWith('m') ?? false);

    final bookingId = customBookingId ?? 'GH-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
    final providerName = provider['name'] ?? (isBartender ? 'Marcus T.' : 'Chef Julian');
    final providerImage = provider['image'] ??
        (isBartender
            ? 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80'
            : 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80');

    final menuTitle = menu['title'] ?? (isBartender ? 'Özel Artisan Kokteyl Paketi' : 'Şefin Özel Tadım Menüsü');
    final menuDesc = menu['description'] ??
        (isBartender
            ? 'Etkinliğinize özel hazırlanan imza kokteyller ve taze botanik infüzyonlar.'
            : 'Mevsimin en taze yerel malzemeleriyle hazırlanan özel fine-dining deneyimi.');

    List<String> courses;
    List<ProcurementItem> procurementItems;
    final procurementResponsible = isBartender
        ? 'Barmen Tarafından Karşılanır (Premium İçecekler, Şuruplar, Buz & Ekipman Dahil)'
        : 'Şef Tarafından Karşılanır (%100 Gurme, Yerel Taze Malzemeler & Sunum Ekipmanı Dahil)';

    if (isBartender) {
      courses = [
        'Aperitif: Smoked Rosemary & Citrus Welcome Drink',
        'İmza Kokteyl: Handcrafted Botanical Gin Tonic & Dry Bitters',
        'Özel Sunum: Barrel-Aged Bourbon & Smoked Old Fashioned',
        'Digestif: Cold Brew Espresso Martini & Organik Vanilya Köpüğü',
      ];
      procurementItems = [
        const ProcurementItem(
          name: 'Premium Seçilmiş İçecek & Botanikler',
          quantity: '3 Şişe',
          origin: 'Özel Mahzen',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Taze Organik Narenciye & Meyve Püreleri',
          quantity: '2 kg',
          origin: 'Mevsimsel Yerel Bahçe',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'El Yapımı Özel Şuruplar & Aromatik Bitterler',
          quantity: '4 Çeşit',
          origin: 'Şefin Kendi Üretimi',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Kalıp Kristal Elmas Buz & Garnitürler',
          quantity: '5 kg',
          origin: 'GastroIce',
          providedBy: 'Barmen Karşılıyor',
          isProcured: true,
        ),
      ];
    } else {
      courses = [
        'Amuse-Bouche: Mevsimsel Taze Trüflü & Otlu İkram',
        'Başlangıç: Organik Burrata & Taze İncir Carpaccio',
        'Ana Yemek: Özel Dinlendirilmiş Bonfile & Fırınlanmış Kuşkonmaz',
        'Tatlı: İtalyan Usulü Panna Cotta & Taze Yaban Mersini Sosu',
      ];
      procurementItems = [
        const ProcurementItem(
          name: 'Özel Seçim Taze Trüf & Mantar Çeşitleri',
          quantity: '40 gr',
          origin: 'Yerel Gurme İthalat',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        ProcurementItem(
          name: 'Dinlendirilmiş Dana Bonfile (Dry-Aged)',
          quantity: '${(guestCount * 220)} gr',
          origin: 'Özel Besi Çiftliği',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        ProcurementItem(
          name: 'Günlük Taze Burrata & Gurme Peynirler',
          quantity: '$guestCount adet',
          origin: 'Günlük Butik Mandıra',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Taş Değirmen İtalyan 00 Un & Taze Yumurta',
          quantity: '500 gr',
          origin: 'Organik Pazar',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Taze Kuşkonmaz & Mikro Yeşillikler',
          quantity: '300 gr',
          origin: 'Seralardan Taze Hasat',
          providedBy: 'Şef Karşılıyor',
          isProcured: true,
        ),
        const ProcurementItem(
          name: 'Mutfak Yağı, Tuz & Standart Baharatlar',
          quantity: 'Mevcut',
          origin: 'Ev Sahibi Mutfağı',
          providedBy: 'Ev Sahibi / Mutfak',
          isProcured: true,
        ),
      ];
    }

    final formattedTime = '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';
    final effectiveHourly = isHourly ?? isBartender;
    final resolvedUnitPrice = unitPrice ??
        (menu['price_per_person'] as num?)?.toDouble() ??
        (provider['unit_price'] as num?)?.toDouble() ??
        (effectiveHourly ? 850.0 : 1850.0);

    final newBooking = BookingModel(
      id: bookingId,
      dbId: dbUuid,
      providerId: provider['id']?.toString() ?? 'p1',
      providerName: providerName,
      providerRole: isBartender ? 'Master Mixologist' : 'Executive Chef',
      providerImage: providerImage,
      providerRating: provider['rating']?.toString() ?? '4.9',
      menuId: menu['id']?.toString() ?? 'menu_101',
      menuTitle: menuTitle,
      menuDescription: menuDesc,
      courses: courses,
      procurementResponsible: !ingredientsIncluded
          ? 'Malzeme Listesi Ev Sahibi Tarafından Temin Edilir (%20 İndirimli)'
          : procurementResponsible,
      procurementItems: procurementItems,
      eventDate: eventDate,
      eventTime: formattedTime,
      guestCount: guestCount,
      hoursCount: hoursCount,
      isHourly: effectiveHourly,
      address: address,
      kitchenDetails: kitchenDetails,
      allergies: allergies.isEmpty ? ['Özel alerjen belirtilmedi'] : allergies,
      unitPrice: resolvedUnitPrice,
      totalPrice: totalPrice,
      platformFee: platformFee,
      providerEarnings: providerEarnings,
      status: 'accepted',
      createdAt: DateTime.now(),
      notes: notes,
    );

    state = state.copyWith(
      bookings: [newBooking, ...state.bookings.where((b) => b.id != newBooking.id)],
      activeBookingId: newBooking.id,
    );

    return newBooking;
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});
