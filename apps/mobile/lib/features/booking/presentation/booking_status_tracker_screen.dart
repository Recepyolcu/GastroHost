import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../review/presentation/review_rating_screen.dart';

class BookingStatusTrackerScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final VoidCallback onBackToHome;
  final VoidCallback onOpenChat;
  final Function(Map<String, dynamic> provider)? onOpenChefProfile;

  const BookingStatusTrackerScreen({
    super.key,
    this.bookingId,
    required this.onBackToHome,
    required this.onOpenChat,
    this.onOpenChefProfile,
  });

  @override
  ConsumerState<BookingStatusTrackerScreen> createState() => _BookingStatusTrackerScreenState();
}

class _BookingStatusTrackerScreenState extends ConsumerState<BookingStatusTrackerScreen> {
  String? _selectedBookingId;

  @override
  void initState() {
    super.initState();
    _selectedBookingId = widget.bookingId;
  }

  @override
  void didUpdateWidget(covariant BookingStatusTrackerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookingId != null && widget.bookingId != oldWidget.bookingId) {
      setState(() {
        _selectedBookingId = widget.bookingId;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime _parseEventDateTime(DateTime eventDate, String eventTime) {
    try {
      final parts = eventTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(eventDate.year, eventDate.month, eventDate.day, hour, minute);
    } catch (_) {
      return eventDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);
    final bookingState = ref.watch(bookingProvider);

    // Determine current booking
    BookingModel? booking;
    if (bookingState.bookings.isNotEmpty) {
      if (_selectedBookingId != null) {
        try {
          booking = bookingState.bookings.firstWhere((b) => b.id == _selectedBookingId);
        } catch (_) {
          booking = bookingState.activeBooking ?? bookingState.bookings.first;
        }
      } else {
        booking = bookingState.activeBooking ?? bookingState.bookings.first;
      }
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
            onPressed: widget.onBackToHome,
          ),
          title: Text(
            'Rezervasyonlarım',
            style: GoogleFonts.libreCaslonText(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: palette.goldAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 36,
                    color: palette.goldAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Henüz Rezervasyonunuz Yok',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Özel şefler ve barmenlerin imza menülerini keşfedin, evinize özel gastronomi deneyimi ayırtın.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: palette.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onBackToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? palette.goldAccent : Colors.black,
                    foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Şefleri Keşfet',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeBooking = booking;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
          onPressed: widget.onBackToHome,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rezervasyon #${activeBooking.id}',
              style: GoogleFonts.libreCaslonText(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            Text(
              'GastroHost Escrow Korumalı',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.goldAccent,
              ),
            ),
          ],
        ),
        // Sağ üstteki mesaj butonu kaldırıldı
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Selector Pills (if multiple bookings exist)
              if (bookingState.bookings.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: bookingState.bookings.map((b) {
                      final isSelected = b.id == activeBooking.id;
                      final isCompleted = b.status == 'completed';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 12),
                        child: ChoiceChip(
                          label: Text(
                            '${b.providerName} (${isCompleted ? "Tamamlandı" : "Aktif"})',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF0B0D11) : Colors.white)
                                  : palette.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: isDark ? palette.goldAccent : Colors.black,
                          backgroundColor: palette.surfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : palette.border,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBookingId = b.id;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // 1. Live Countdown Timer Card (Etkinliğe Kalan Süre)
              _buildCountdownTimerCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 2. Provider & Booking Summary Card
              _buildProviderSummaryCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 3. Live Status Timeline Card
              _buildLiveStatusCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 3.1 3-Criteria Review & Rating Card (Shows if completed)
              if (activeBooking.status == 'completed') ...[
                _buildReviewSummaryOrPromptCard(activeBooking, palette, isDark),
                const SizedBox(height: 16),
              ],

              // 4. Required Materials & Procurement Responsibility Card
              _buildRequiredMaterialsCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 5. Event Logistics & Address Card
              _buildEventLogisticsCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 5.1 Alerjen & Özel Diyet Tercihleri Card
              _buildAllergiesDietCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 6. Menu & Courses Details Card
              _buildMenuDetailsCard(activeBooking, palette, isDark),
              const SizedBox(height: 16),

              // 7. Escrow Payment & Protection Card
              _buildEscrowPaymentCard(activeBooking, palette, isDark),
              const SizedBox(height: 24),

              // 8. Bottom Action Buttons
              _buildBottomActionButtons(activeBooking, palette, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Live Countdown Timer Card
  Widget _buildCountdownTimerCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    final eventDateTime = _parseEventDateTime(booking.eventDate, booking.eventTime);
    final now = DateTime.now();
    final difference = eventDateTime.difference(now);

    final isPast = difference.isNegative;
    final isCompleted = booking.status == 'completed';
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E242B), const Color(0xFF15191E)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.goldAccent.withValues(alpha: isDark ? 0.3 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.goldAccent.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: palette.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Etkinlik Geri Sayımı',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      '${_formatDate(booking.eventDate)} • ${booking.eventTime}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted && !isPast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.goldGlow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.goldAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: palette.goldAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Yaklaşıyor',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (isCompleted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bu etkinlik başarıyla tamamlandı. Afiyet olsun!',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isPast && difference.inHours.abs() < 5) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: palette.goldAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.goldAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: palette.goldAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🟢 Etkinlik Başladı • Canlı Gastronomi Servisinde',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Countdown Digits Row
            Row(
              children: [
                Expanded(
                  child: _buildCountdownBox(
                    label: 'GÜN',
                    value: '${days > 0 ? days : 0}',
                    palette: palette,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountdownBox(
                    label: 'SAAT',
                    value: '${hours > 0 ? hours : 0}',
                    palette: palette,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountdownBox(
                    label: 'DAKİKA',
                    value: '${minutes > 0 ? minutes : 0}',
                    palette: palette,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              days > 0
                  ? 'Şefinizin özel tedarik ve hazırlık süreci için $days gün $hours saat kaldı.'
                  : 'Şefinizin yola çıkışı ve canlı tabaklama için $hours saat $minutes dakika kaldı.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownBox({
    required String label,
    required String value,
    required AppThemePalette palette,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1318) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.libreCaslonText(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.goldAccent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: palette.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Provider Summary Header Card
  Widget _buildProviderSummaryCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (widget.onOpenChefProfile != null) {
                widget.onOpenChefProfile!({
                  'id': booking.providerId,
                  'name': booking.providerName,
                  'role': booking.providerRole,
                  'image': booking.providerImage,
                  'rating': booking.providerRating,
                  'provider_type': booking.isHourly ? 'bartender' : 'chef',
                });
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    booking.providerImage,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: palette.surfaceElevated,
                      child: Icon(Icons.person_rounded, color: palette.goldAccent, size: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              booking.providerName,
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded, color: palette.goldAccent, size: 16),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: palette.goldAccent),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.providerRole,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: palette.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.goldGlow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.goldAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: palette.goldAccent, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                booking.providerRating,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: palette.goldAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${_formatDate(booking.eventDate)} • ${booking.eventTime}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

          // View Profile, Diplomas & Calendar Quick Banner
          InkWell(
            onTap: () {
              if (widget.onOpenChefProfile != null) {
                widget.onOpenChefProfile!({
                  'id': booking.providerId,
                  'name': booking.providerName,
                  'role': booking.providerRole,
                  'image': booking.providerImage,
                  'rating': booking.providerRating,
                  'provider_type': booking.isHourly ? 'bartender' : 'chef',
                });
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined, size: 14, color: palette.goldAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Şefin Eğitimleri, Değerlendirmeleri & Müsaitlik Takvimi',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.goldAccent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: palette.goldAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: palette.borderSubtle, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Şef aranıyor: ${booking.providerPhone}'),
                        backgroundColor: palette.surfaceElevated,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.call_outlined, size: 16, color: palette.textPrimary),
                  label: Text(
                    'Şefi Ara',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(
                    'Mesaj Gönder',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? palette.goldAccent : Colors.black,
                    foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Live Status Timeline
  Widget _buildLiveStatusCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    final status = booking.status;
    final isConfirmed =
        status == 'confirmed' || status == 'accepted' || status == 'pending';
    final isShopping = status == 'shopping';
    final isOnTheWay = status == 'on_the_way';
    final isInKitchen = status == 'in_kitchen';
    final isCompleted = status == 'completed';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Canlı Etkinlik Durumu',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : palette.goldGlow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : palette.goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFF10B981) : palette.goldAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCompleted ? 'Tamamlandı' : 'Canlı Takip',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? const Color(0xFF10B981) : palette.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Step 1: Confirmed
          _buildTimelineStep(
            stepNumber: 1,
            title: 'Rezervasyon & Escrow Onaylandı',
            subtitle: 'Ödeme iyzico Escrow havuzunda güvenceye alındı, menü ve saat planlandı.',
            isDone: true,
            isCurrent: isConfirmed,
            palette: palette,
            isDark: isDark,
          ),
          // Step 2: Sourcing / Prep
          _buildTimelineStep(
            stepNumber: 2,
            title: 'Taze Malzeme Tedariği & Hazırlık',
            subtitle: 'Şefiniz malzemeleri yerel gurme pazarlardan taze olarak temin etti.',
            isDone: isShopping || isOnTheWay || isInKitchen || isCompleted,
            isCurrent: isShopping,
            isUpcoming: isConfirmed,
            palette: palette,
            isDark: isDark,
          ),
          // Step 3: On the way
          _buildTimelineStep(
            stepNumber: 3,
            title: '${booking.isHourly ? "Barmen" : "Şef"} Yolda',
            subtitle: 'Hizmet sağlayıcınız özel ekipmanlarıyla adresinize doğru yola çıktı.',
            isDone: isInKitchen || isCompleted,
            isCurrent: isOnTheWay,
            isUpcoming: isConfirmed || isShopping,
            palette: palette,
            isDark: isDark,
          ),
          // Step 4: In kitchen
          _buildTimelineStep(
            stepNumber: 4,
            title: booking.isHourly ? "Bar Kurulumu & Sunum" : "Mutfak Hazırlığı & Tabaklama",
            subtitle: 'Özel gastronomi sunumu, tabaklama ve canlı servis gerçekleştiriliyor.',
            isDone: isCompleted,
            isCurrent: isInKitchen,
            isUpcoming: isConfirmed || isShopping || isOnTheWay,
            palette: palette,
            isDark: isDark,
          ),
          // Step 5: Completed
          _buildTimelineStep(
            stepNumber: 5,
            title: 'Etkinlik Başarıyla Tamamlandı',
            subtitle: 'Mutfak temizlendi, hizmet sonlandı ve Escrow ödemesi şefe serbest bırakıldı.',
            isDone: isCompleted,
            isCurrent: isCompleted,
            isUpcoming: !isCompleted,
            isLast: true,
            palette: palette,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // 4. Required Materials & Procurement Responsibility Card
  Widget _buildRequiredMaterialsCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: palette.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gerekli Malzemeler & Tedarik Sorumlusu',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Responsibility Highlight Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.emerald.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.emerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shopping_bag_outlined, color: palette.emerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Malzeme Tedariği:',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.emerald,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.procurementResponsible,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Menüdeki tüm özel etler, deniz ürünleri, unlar ve soslar şef tarafından etkinliğe özel taze alınır. Ev sahibinin sadece standart mutfak tuz/yağını hazır bulundurması yeterlidir.',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: palette.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Gerekli Malzeme Listesi ve Temin Durumu:',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          ...booking.procurementItems.map((item) {
            final isChefProvided = item.providedBy.contains('Şef') || item.providedBy.contains('Barmen');
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isChefProvided ? palette.goldAccent : palette.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.origin} • ${item.providedBy}',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F1318) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                    child: Text(
                      item.quantity,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. Event Logistics & Address Card
  Widget _buildEventLogisticsCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: palette.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Etkinlik & Mekan Detayları',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date & Guests Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoSubCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Tarih & Saat',
                  value: '${_formatDate(booking.eventDate)}\n${booking.eventTime}',
                  palette: palette,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoSubCard(
                  icon: booking.isHourly ? Icons.access_time_filled_rounded : Icons.group_rounded,
                  label: booking.isHourly ? 'Hizmet Süresi' : 'Davetli Sayısı',
                  value: booking.isHourly
                      ? '${booking.hoursCount} Saatlik\nBar Hizmeti'
                      : '${booking.guestCount} Kişilik\nÖzel Akşam Yemeği',
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Address block
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: palette.emerald, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Etkinlik Adresi',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  booking.address,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: palette.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Kitchen & Equipment Tags
          Text(
            'Mevcut Mutfak / Bar Ekipmanları:',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (booking.kitchenDetails['stove'] ?? true)
                _buildEquipmentBadge('Ocak & Pişirme', Icons.microwave_rounded, palette),
              if (booking.kitchenDetails['oven'] ?? true)
                _buildEquipmentBadge('Fırın Mevcut', Icons.kitchen_rounded, palette),
              if (booking.kitchenDetails['blender'] ?? true)
                _buildEquipmentBadge('Blender / Mikser', Icons.blender_rounded, palette),
              if (booking.kitchenDetails['mobile_bar'] ?? false)
                _buildEquipmentBadge('Portatif Bar Kurulumu', Icons.local_bar_rounded, palette),
            ],
          ),
          const SizedBox(height: 12),

          // Allergies Note
          if (booking.allergies.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.goldGlow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.goldAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: palette.goldAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alerjen & Özel İstek Notları',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.goldAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...booking.allergies.map(
                          (allergy) => Padding(
                            padding: const EdgeInsets.only(bottom: 2.0),
                            child: Text(
                              '• $allergy',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. Menu Details Card
  Widget _buildMenuDetailsCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded, color: palette.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking.menuTitle,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            booking.menuDescription,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: palette.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Menü Kursları & Sunum Aşamaları:',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...booking.courses.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final course = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: palette.goldGlow,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.goldAccent.withValues(alpha: 0.5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$idx',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: palette.goldAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      course,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 7. Escrow & Payment Card
  Widget _buildEscrowPaymentCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: palette.emerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Escrow Ödeme Özeti',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.emerald.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.emerald.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, color: palette.emerald, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ödemeniz GastroHost Escrow korumasında bloke edilmiştir. Hizmet tamamlanana kadar güvenle saklanır.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildPaymentRow(
            booking.isHourly
                ? 'Saatlik Ücret (₺${booking.unitPrice.toStringAsFixed(0)} × ${booking.hoursCount} saat)'
                : 'Menü Ücreti (₺${booking.unitPrice.toStringAsFixed(0)} × ${booking.guestCount} kişi)',
            '₺${(booking.totalPrice - booking.platformFee).toStringAsFixed(0)}',
            palette,
          ),
          const SizedBox(height: 8),
          _buildPaymentRow(
            'GastroHost Hizmet & Escrow Bedeli (%10)',
            '₺${booking.platformFee.toStringAsFixed(0)}',
            palette,
          ),
          Divider(color: palette.borderSubtle, height: 20),
          _buildPaymentRow(
            'Toplam Ödenen Tutar',
            '₺${booking.totalPrice.toStringAsFixed(0)}',
            palette,
            isTotal: true,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ödeme Yöntemi',
                style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
              ),
              Text(
                booking.paymentMethod,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.goldAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openReviewModal(BookingModel booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewRatingScreen(
          booking: booking,
          onBack: () => Navigator.of(context).pop(),
          onSubmitComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // 8. Bottom Action Buttons
  Widget _buildBottomActionButtons(BookingModel booking, AppThemePalette palette, bool isDark) {
    final isFinished = booking.status == 'completed' || booking.status == 'cancelled';

    if (isFinished) {
      final isCompleted = booking.status == 'completed';
      final needsReview = isCompleted && !booking.isReviewed;

      return Column(
        children: [
          if (needsReview) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openReviewModal(booking),
                icon: const Icon(Icons.star_rounded, size: 20),
                label: Text(
                  '⭐ Deneyimi Değerlendir (3 Kriterli)',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.goldAccent,
                  foregroundColor: const Color(0xFF0B0D11),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: palette.emerald, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCompleted
                        ? (booking.isReviewed
                            ? 'Bu rezervasyonunuz tamamlandı ve 3 kriterli değerlendirmeniz şef profiline işlendi. Yeni bir rezervasyon oluşturabilirsiniz.'
                            : 'Bu rezervasyonunuz tamamlandı. Şefinize lezzet, hijyen ve sunum puanı verip yeni bir rezervasyon oluşturabilirsiniz!')
                        : 'Bu rezervasyon iptal edildi. Dilediğiniz zaman yeni bir rezervasyon oluşturabilirsiniz.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: palette.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: needsReview
                ? OutlinedButton.icon(
                    onPressed: widget.onBackToHome,
                    icon: const Icon(Icons.explore_rounded, size: 18),
                    label: Text(
                      'Yeni Rezervasyon Oluştur (Şefleri Keşfet)',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: palette.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: widget.onBackToHome,
                    icon: const Icon(Icons.explore_rounded, size: 18),
                    label: Text(
                      'Yeni Rezervasyon Oluştur (Şefleri Keşfet)',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? palette.goldAccent : Colors.black,
                      foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (booking.status != 'completed' && booking.status != 'cancelled') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(bookingProvider.notifier)
                    .confirmCompletionAndReleaseEscrow(booking.id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                          '✅ Hizmet tamamlandı onaylandı! %90 uzman hakedişi Escrow havuzundan serbest bırakıldı.'),
                      backgroundColor: Color(0xFF10B981),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text(
                'Hizmet Tamamlandı Onayla & Escrow Aktar',
                style: GoogleFonts.manrope(
                    fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onOpenChat,
            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
            label: Text(
              '${booking.providerName} ile Canlı Sohbet',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? palette.goldAccent : Colors.black,
              foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _showSupportModal(context, booking, palette, isDark);
            },
            icon: Icon(Icons.support_agent_rounded, size: 18, color: palette.textPrimary),
            label: Text(
              'Rezervasyon Desteği / İptal Talebi',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: palette.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  void _showSupportModal(BuildContext context, BookingModel booking, AppThemePalette palette, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rezervasyon Desteği',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rezervasyon ID: #${booking.id} • Şef: ${booking.providerName}',
                  style: GoogleFonts.manrope(fontSize: 13, color: palette.textMuted),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.help_outline_rounded, color: palette.goldAccent),
                  title: Text('GastroHost Müşteri Desteği', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: palette.textPrimary)),
                  subtitle: Text('7/24 canlı destek ekibimize bağlanın', style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('GastroHost Canlı Destek ekibine aktarılıyorsunuz...')),
                    );
                  },
                ),
                Divider(color: palette.borderSubtle),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
                  title: Text('Rezervasyonu İptal Et', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: const Color(0xFFEF4444))),
                  subtitle: Text('Escrow iade politikasına göre ücret iade edilir', style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmCancellation(booking, palette);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancellation(BookingModel booking, AppThemePalette palette) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'Rezervasyonu İptal Et?',
          style: GoogleFonts.libreCaslonText(fontWeight: FontWeight.bold, color: palette.textPrimary),
        ),
        content: Text(
          'Rezervasyonunuz iptal edilecek ve ₺${booking.totalPrice.toStringAsFixed(0)} tutarındaki Escrow bakiyesi kartınıza iade edilecektir.',
          style: GoogleFonts.manrope(fontSize: 13, color: palette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç', style: GoogleFonts.manrope(color: palette.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).updateBookingStatus(booking.id, 'cancelled');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Rezervasyon iptal edildi ve Escrow iadesi başlatıldı.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSubCard({
    required IconData icon,
    required String label,
    required String value,
    required AppThemePalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: palette.goldAccent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentBadge(String title, IconData icon, AppThemePalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.emerald),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required AppThemePalette palette,
    required bool isDark,
    bool isDone = false,
    bool isCurrent = false,
    bool isUpcoming = false,
    bool isLast = false,
  }) {
    Color iconBgColor;
    Color iconColor;
    Widget? innerIcon;

    if (isDone) {
      iconBgColor = isDark ? palette.goldAccent : Colors.black;
      iconColor = isDark ? const Color(0xFF0B0D11) : Colors.white;
      innerIcon = Icon(Icons.check_rounded, color: iconColor, size: 14);
    } else if (isCurrent) {
      iconBgColor = palette.goldAccent;
      iconColor = const Color(0xFF0B0D11);
      innerIcon = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
      );
    } else {
      iconBgColor = palette.surfaceElevated;
      iconColor = palette.textMuted;
      innerIcon = Text(
        '$stepNumber',
        style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
                border: Border.all(
                  color: isUpcoming ? palette.border : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: innerIcon,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: (isDone || isCurrent)
                    ? palette.goldAccent.withValues(alpha: 0.5)
                    : palette.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isUpcoming ? palette.textMuted : palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: isUpcoming
                      ? palette.textMuted.withValues(alpha: 0.6)
                      : palette.textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, AppThemePalette palette, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? palette.textPrimary : palette.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal ? palette.goldAccent : palette.textPrimary,
          ),
        ),
      ],
    );
  }

  // 3.1 3-Criteria Review & Rating Card
  Widget _buildReviewSummaryOrPromptCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    if (booking.isReviewed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.goldAccent.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: palette.goldAccent.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: palette.goldAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Değerlendirmeniz',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.goldGlow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.goldAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: palette.goldAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.ratingOverall?.toStringAsFixed(1) ?? "5.0"} / 5.0',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 3 criteria breakdown
            Row(
              children: [
                Expanded(
                  child: _buildCriteriaScoreChip(
                    label: 'Lezzet',
                    score: booking.ratingFood ?? 5.0,
                    palette: palette,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCriteriaScoreChip(
                    label: 'Hijyen',
                    score: booking.ratingHygiene ?? 5.0,
                    palette: palette,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCriteriaScoreChip(
                    label: 'Sunum',
                    score: booking.ratingPresentation ?? 5.0,
                    palette: palette,
                  ),
                ),
              ],
            ),
            if (booking.reviewComment != null && booking.reviewComment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderSubtle),
                ),
                child: Text(
                  '"${booking.reviewComment}"',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: palette.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Prompt to review
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E242B), const Color(0xFF15191E)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.goldAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.goldAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rate_review_rounded, color: palette.goldAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etkinliği Değerlendirin',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  'Lezzet, mutfak hijyeni ve sunum kriterlerine göre 1-5 yıldız verin.',
                  style: GoogleFonts.manrope(fontSize: 11, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _openReviewModal(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? palette.goldAccent : Colors.black,
              foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Puanla',
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaScoreChip({
    required String label,
    required double score,
    required AppThemePalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: palette.textMuted),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: palette.goldAccent, size: 14),
              const SizedBox(width: 2),
              Text(
                score.toStringAsFixed(1),
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5.1 Alerjen & Özel Diyet Tercihleri Card
  Widget _buildAllergiesDietCard(BookingModel booking, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_rounded, color: palette.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alerjen & Özel Diyet Tercihleri',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.goldGlow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.goldAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Şefe İletildi',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: palette.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: booking.allergies.map((allergy) {
              final isNote = allergy.startsWith('Özel Not:');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isNote
                      ? palette.goldAccent.withValues(alpha: 0.12)
                      : palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNote
                        ? palette.goldAccent.withValues(alpha: 0.4)
                        : palette.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNote ? Icons.note_alt_outlined : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: isNote ? palette.goldAccent : palette.emerald,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        allergy,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Şefiniz ve servis ekibi mutfakta çapraz bulaşmayı önlemek üzere özel hazırlık tezgahı ve ayrı pişirme ekipmanı kullanacaktır.',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: palette.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

