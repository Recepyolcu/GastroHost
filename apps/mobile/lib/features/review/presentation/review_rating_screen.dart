import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/theme/app_theme.dart';

class ReviewRatingScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  final VoidCallback? onBack;
  final VoidCallback? onSubmitComplete;

  const ReviewRatingScreen({
    super.key,
    required this.booking,
    this.onBack,
    this.onSubmitComplete,
  });

  @override
  ConsumerState<ReviewRatingScreen> createState() => _ReviewRatingScreenState();
}

class _ReviewRatingScreenState extends ConsumerState<ReviewRatingScreen> {
  // 3 Distinct Criteria (PRD Tech Spec: rating_food, rating_hygiene, rating_presentation)
  int _ratingFood = 5;
  int _ratingHygiene = 5;
  int _ratingPresentation = 5;

  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedQuickTags = {};

  final List<String> _quickTags = [
    '🌟 Michelin Seviyesi Tabaklar',
    '🧼 Pırıl Pırıl Temiz Mutfak',
    '👨‍🍳 Çok Saygılı ve Nazik Şef',
    '⏱️ Tam Zamanında Servis',
    '🍷 Harika Lezzet Dengesi',
    '✨ Tekrar Kesinlikle Tercih Ederim',
  ];

  double get _overallRating => (_ratingFood + _ratingHygiene + _ratingPresentation) / 3.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getFoodRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Yetersiz Lezzet';
      case 2:
        return 'Geliştirilebilir';
      case 3:
        return 'Lezzetli';
      case 4:
        return 'Çok Başarılı';
      case 5:
        return 'Kusursuz Gurme Lezzet ⭐';
      default:
        return '';
    }
  }

  String _getHygieneRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Yetersiz Temizlik';
      case 2:
        return 'Orta Düzey';
      case 3:
        return 'Temiz';
      case 4:
        return 'Çok Titiz';
      case 5:
        return 'Pırıl Pırıl & Hijyenik Teslim ⭐';
      default:
        return '';
    }
  }

  String _getPresentationRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Zayıf Sunum';
      case 2:
        return 'Standart';
      case 3:
        return 'Şık ve Özenli';
      case 4:
        return 'Çok Zarif Servis';
      case 5:
        return 'Sanat Eseri Tabaklama & Nezaket ⭐';
      default:
        return '';
    }
  }

  void _submitReview() {
    final comment = _commentController.text.trim();
    final combinedComment = _selectedQuickTags.isNotEmpty
        ? (_selectedQuickTags.join(', ') + (comment.isNotEmpty ? '\n\n$comment' : ''))
        : (comment.isNotEmpty ? comment : 'Harika bir gastronomi deneyimiydi, teşekkürler.');

    ref.read(bookingProvider.notifier).submitReview(
          bookingId: widget.booking.id,
          ratingFood: _ratingFood.toDouble(),
          ratingHygiene: _ratingHygiene.toDouble(),
          ratingPresentation: _ratingPresentation.toDouble(),
          comment: combinedComment,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Değerlendirmeniz başarıyla kaydedildi! Şef profil puanı güncellendi.'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );

    if (widget.onSubmitComplete != null) {
      widget.onSubmitComplete!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary, size: 18),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          'Deneyimi Değerlendir',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSubmitBar(palette, isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Chef & Booking Info Header Card
              _buildHeaderCard(booking, palette, isDark),
              const SizedBox(height: 20),

              // 2. Dynamic Overall Score Card
              _buildOverallScoreBanner(palette, isDark),
              const SizedBox(height: 20),

              // 3. Three Individual Criteria Cards
              // Kriter 1: Lezzet & Pişirme
              _buildCriteriaRatingCard(
                title: '1. Lezzet & Pişirme Kalitesi',
                subtitle: 'Tabakların lezzeti, malzeme tazeliği, kıvamı ve pişme dengesi',
                icon: Icons.restaurant_menu_rounded,
                currentRating: _ratingFood,
                ratingLabel: _getFoodRatingLabel(_ratingFood),
                onChanged: (newRating) => setState(() => _ratingFood = newRating),
                palette: palette,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Kriter 2: Mutfak Hijyeni & Temizlik
              _buildCriteriaRatingCard(
                title: '2. Mutfak Hijyeni & Düzeni',
                subtitle: 'Şefin hazırlık sırasındaki titizliği ve mutfağı temiz teslim etme standardı',
                icon: Icons.sanitizer_rounded,
                currentRating: _ratingHygiene,
                ratingLabel: _getHygieneRatingLabel(_ratingHygiene),
                onChanged: (newRating) => setState(() => _ratingHygiene = newRating),
                palette: palette,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Kriter 3: Sunum, Servis & İletişim
              _buildCriteriaRatingCard(
                title: '3. Sunum, Servis & Misafirperverlik',
                subtitle: 'Tabaklama estetiği, servis hızı, şefin iletişimi ve profesyonel tavrı',
                icon: Icons.room_service_rounded,
                currentRating: _ratingPresentation,
                ratingLabel: _getPresentationRatingLabel(_ratingPresentation),
                onChanged: (newRating) => setState(() => _ratingPresentation = newRating),
                palette: palette,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // 4. Quick Praise Tags (Hızlı Övgü Etiketleri)
              _buildQuickTagsSection(palette, isDark),
              const SizedBox(height: 20),

              // 5. Detailed Review & Comments Input
              _buildCommentSection(palette, isDark),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BookingModel booking, AppThemePalette palette, bool isDark) {
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              booking.providerImage,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: palette.surfaceElevated,
                child: Icon(Icons.person, color: palette.goldAccent),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 15, color: palette.goldAccent),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  booking.menuTitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Tamamlanan Etkinlik #${booking.id}',
                    style: GoogleFonts.manrope(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreBanner(AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E242B), const Color(0xFF14171C)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.goldAccent.withValues(alpha: isDark ? 0.4 : 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GENEL DENEYİM PUANI',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: palette.goldAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _overallRating >= 4.5
                    ? 'Olağanüstü Bir Deneyim!'
                    : (_overallRating >= 3.5 ? 'Çok Başarılı Bir Etkinlik' : 'Geliştirilebilir Deneyim'),
                style: GoogleFonts.libreCaslonText(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.star_rounded, color: palette.goldAccent, size: 28),
              const SizedBox(width: 4),
              Text(
                _overallRating.toStringAsFixed(1),
                style: GoogleFonts.libreCaslonText(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                ' / 5.0',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRatingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int currentRating,
    required String ratingLabel,
    required ValueChanged<int> onChanged,
    required AppThemePalette palette,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: palette.goldAccent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Star selection row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = starIndex <= currentRating;
                  return InkWell(
                    onTap: () => onChanged(starIndex),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFilled ? palette.goldAccent : palette.textMuted.withValues(alpha: 0.4),
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.borderSubtle),
                ),
                child: Text(
                  '$currentRating / 5',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ratingLabel,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.goldAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTagsSection(AppThemePalette palette, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Öne Çıkan Özellikler (Hızlı Etiketler)',
          style: GoogleFonts.libreCaslonText(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Şefinizin en çok beğendiğiniz yönlerini seçin.',
          style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickTags.map((tag) {
            final isSelected = _selectedQuickTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF0B0D11) : Colors.white)
                    : palette.textPrimary,
              ),
              backgroundColor: palette.surfaceElevated,
              selectedColor: isDark ? palette.goldAccent : Colors.black,
              checkmarkColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : palette.border,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedQuickTags.add(tag);
                  } else {
                    _selectedQuickTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentSection(AppThemePalette palette, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görüş ve Değerlendirmeniz',
          style: GoogleFonts.libreCaslonText(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Yemekler, servis ve şefin özeni hakkında detaylı görüşleriniz diğer ev sahiplerine rehberlik eder.',
          style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 4,
            style: GoogleFonts.manrope(fontSize: 13, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'Örn: Şef Julian zamanında geldi, trüflü tagliolini unutulmazdı ve mutfağı pırıl pırıl bıraktı...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 12,
                color: palette.textMuted.withValues(alpha: 0.7),
              ),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSubmitBar(AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? palette.goldAccent : Colors.black,
              foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Değerlendirmeyi Yayınla (${_overallRating.toStringAsFixed(1)} ★)',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
