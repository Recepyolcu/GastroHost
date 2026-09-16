import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class BookingStatusTrackerScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final VoidCallback onBackToHome;
  final VoidCallback onOpenChat;

  const BookingStatusTrackerScreen({
    super.key,
    this.bookingId,
    required this.onBackToHome,
    required this.onOpenChat,
  });

  @override
  ConsumerState<BookingStatusTrackerScreen> createState() => _BookingStatusTrackerScreenState();
}

class _BookingStatusTrackerScreenState extends ConsumerState<BookingStatusTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);

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
          "Tonight's Event",
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              Text(
                "Tonight's Event with Chef Marco",
                style: GoogleFonts.libreCaslonText(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tuscan Truffle Experience • 7:30 PM",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Live Status Timeline Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Canlı Etkinlik Durumu',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.goldGlow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.goldAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: palette.goldAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Canlı Takip',
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
                    const SizedBox(height: 20),

                    // Step 1: Accepted
                    _buildTimelineStep(
                      title: 'Rezervasyon Onaylandı',
                      subtitle: 'Şef etkinliğinizi onayladı ve menüye alındınız.',
                      isDone: true,
                      palette: palette,
                      isDark: isDark,
                    ),
                    // Step 2: Shopping
                    _buildTimelineStep(
                      title: 'Malzeme Alışverişi & Tedarik',
                      subtitle: 'Taze malzemeler yerel gurme pazarlardan tedarik ediliyor.',
                      isDone: true,
                      palette: palette,
                      isDark: isDark,
                    ),
                    // Step 3: On The Way
                    _buildTimelineStep(
                      title: 'Şef Yolda',
                      subtitle: 'Şefiniz adresinize doğru yola çıktı.',
                      isCurrent: true,
                      palette: palette,
                      isDark: isDark,
                    ),
                    // Step 4: In Kitchen
                    _buildTimelineStep(
                      title: 'Mutfak Hazırlığı & Servis',
                      subtitle: 'Tabaklama ve canlı sunum gerçekleştiriliyor.',
                      isUpcoming: true,
                      palette: palette,
                      isDark: isDark,
                    ),
                    // Step 5: Completed
                    _buildTimelineStep(
                      title: 'Etkinlik Tamamlandı',
                      subtitle: 'Mutfak temizlendi ve hizmet başarıyla sonlandı.',
                      isUpcoming: true,
                      isLast: true,
                      palette: palette,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Map & Chat Button
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBVy2kw2xBFlyCArG9akCtDTiZHJUx0XGlWhoRI--ZD4OFS2nju_x0WMPCPdZ2H9LrmAVu1Lko9AIOOCwidSXvD00bUkTI9Z9vKQe2MRCTEPmp8i8-eZ7XvNb2wRTiH-_vErWBRcAGQTn7ruY3yfn78O1z0LEyW30e85gDWFYAD8AZ9SdITykQMlqloiJQt93KZsva5AXFOZjI5NSNZcc5zJhCnQgUSViTtxb5Oxel9lWz2qbZETfcW',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: ElevatedButton.icon(
                        onPressed: widget.onOpenChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? palette.goldAccent : Colors.black,
                          foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Chat with Chef', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Procurement Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: palette.goldAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Procurement Receipt',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sourced fresh this morning specifically for your menu.',
                      style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
                    ),
                    const SizedBox(height: 16),

                    _buildReceiptRow('Alba White Truffles', '2 oz', palette),
                    _buildReceiptRow('Hand-milled 00 Flour', '500g', palette),
                    _buildReceiptRow('Aged Parmigiano-Reggiano', '1 wedge', palette),
                    _buildReceiptRow('Chianina Beef Tenderloin', '32 oz', palette),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required AppThemePalette palette,
    required bool isDark,
    bool isDone = false,
    bool isCurrent = false,
    bool isUpcoming = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? (isDark ? palette.goldAccent : Colors.black)
                    : (isCurrent ? (isDark ? palette.goldAccent : const Color(0xFF7B5800)) : palette.surfaceElevated),
                border: Border.all(
                  color: isUpcoming ? palette.border : Colors.transparent,
                ),
              ),
              child: isDone
                  ? Icon(Icons.check_rounded, color: isDark ? const Color(0xFF0B0D11) : Colors.white, size: 14)
                  : (isCurrent
                      ? Icon(Icons.directions_car_rounded, color: isDark ? const Color(0xFF0B0D11) : Colors.white, size: 13)
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone || isCurrent ? palette.goldAccent.withValues(alpha: 0.5) : palette.border,
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isUpcoming ? palette.textMuted : palette.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String item, String qty, AppThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item, style: GoogleFonts.manrope(fontSize: 13, color: palette.textPrimary)),
          Text(qty, style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted)),
        ],
      ),
    );
  }
}

