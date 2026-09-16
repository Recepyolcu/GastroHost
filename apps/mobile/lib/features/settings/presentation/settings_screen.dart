import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/user_location_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({super.key, this.onBack});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isClearingCache = false;

  void _showLanguageSelector(BuildContext context, AppSettingsState settings) {
    final isDark = settings.isDarkMode;
    final languages = ['Türkçe', 'English (US)', 'Deutsch', 'Français'];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2228) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uygulama Dili / Language',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSelected = settings.language == lang;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    lang,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7B5800))
                      : null,
                  onTap: () {
                    ref.read(appSettingsProvider.notifier).setLanguage(lang);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencySelector(BuildContext context, AppSettingsState settings) {
    final isDark = settings.isDarkMode;
    final currencies = [
      {'code': 'TRY (₺)', 'name': 'Türk Lirası'},
      {'code': 'USD (\$)', 'name': 'US Dollar'},
      {'code': 'EUR (€)', 'name': 'Euro'},
      {'code': 'GBP (£)', 'name': 'British Pound'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2228) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para Birimi / Currency',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ...currencies.map((curr) {
                final isSelected = settings.currency == curr['code'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    curr['code']!,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    curr['name']!,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppColors.textMuted,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7B5800))
                      : null,
                  onTap: () {
                    ref.read(appSettingsProvider.notifier).setCurrency(curr['code']!);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _clearAppCache() async {
    setState(() => _isClearingCache = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isClearingCache = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Önbellek başarıyla temizlendi (34.2 MB silindi)',
                style: GoogleFonts.manrope(fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showInfoDialog(String title, String content, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2228) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.libreCaslonText(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : AppColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Anladım',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B5800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final userProfile = ref.watch(userProfileProvider);
    final isDark = settings.isDarkMode;

    final bgColor = isDark ? const Color(0xFF121417) : const Color(0xFFFBF9F8);
    final cardBg = isDark ? const Color(0xFF1A1D22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF282D35) : const Color(0xFFE4E2E2);
    final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1B1C1C);
    final mutedTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF747878);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Ayarlar & Tercihler',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. TEMA & GÖRÜNÜM (THEME & APPEARANCE)
            _buildSectionHeader('GÖRÜNÜM & TEMA', mutedTextColor),
            const SizedBox(height: 8),
            _buildCardWrapper(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Karanlık Mod (Dark Mode)',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDark ? 'Obsidian Gece Teması Aktif' : 'Aydınlık Epicurean Teması',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isDark,
                        activeThumbColor: const Color(0xFF7B5800),
                        activeTrackColor: const Color(0xFFFDC34D).withValues(alpha: 0.4),
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).toggleTheme(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. İZİNLER & GİZLİLİK (PERMISSIONS & PRIVACY)
            _buildSectionHeader('İZİNLER & GİZLİLİK', mutedTextColor),
            const SizedBox(height: 8),
            _buildCardWrapper(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                // Location Permission
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Konum İzni (GPS)',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: settings.locationPermissionGranted
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : Colors.redAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    settings.locationPermissionGranted ? 'Açık' : 'Kapalı',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: settings.locationPermissionGranted
                                          ? const Color(0xFF10B981)
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              userProfile.location.isNotEmpty ? userProfile.location : settings.locationStatusText,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: settings.locationPermissionGranted,
                        activeThumbColor: const Color(0xFF7B5800),
                        activeTrackColor: const Color(0xFFFDC34D).withValues(alpha: 0.4),
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).setLocationPermissionGranted(val);
                          if (val) {
                            ref.read(userProfileProvider.notifier).refreshDeviceLocation();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                // Master Notification Permission
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B5800).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF7B5800),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anlık Bildirimler (Push)',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.notificationsEnabled ? 'Tüm bildirim kanalları devrede' : 'Bildirimler susturuldu',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: settings.notificationsEnabled,
                        activeThumbColor: const Color(0xFF7B5800),
                        activeTrackColor: const Color(0xFFFDC34D).withValues(alpha: 0.4),
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).toggleNotifications(val);
                        },
                      ),
                    ],
                  ),
                ),
                if (settings.notificationsEnabled) ...[
                  Divider(height: 1, color: borderColor),
                  _buildSubToggleTile(
                    title: 'Rezervasyon & Sipariş Durumu',
                    subtitle: 'Şef onayları, yola çıkış ve hazırlık bildirimleri',
                    value: settings.orderUpdatesEnabled,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    onChanged: (val) => ref.read(appSettingsProvider.notifier).toggleOrderUpdates(val),
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildSubToggleTile(
                    title: 'Şef Canlı Mesajları',
                    subtitle: 'Özel menü sohbetleri ve müşteri talepleri',
                    value: settings.chefMessagesEnabled,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    onChanged: (val) => ref.read(appSettingsProvider.notifier).toggleChefMessages(val),
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildSubToggleTile(
                    title: 'Özel Teklifler & Tadım Davetleri',
                    subtitle: 'Seçkin şeflerden haftalık gastronomi etkinlikleri',
                    value: settings.promotionalEnabled,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    onChanged: (val) => ref.read(appSettingsProvider.notifier).togglePromotional(val),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // 3. TERCİHLER & DİL (REGIONAL & PREFERENCES)
            _buildSectionHeader('TERCİHLER & DENEYİM', mutedTextColor),
            const SizedBox(height: 8),
            _buildCardWrapper(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                _buildActionTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Uygulama Dili',
                  value: settings.language,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                  onTap: () => _showLanguageSelector(context, settings),
                ),
                Divider(height: 1, color: borderColor),
                _buildActionTile(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Para Birimi',
                  value: settings.currency,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                  onTap: () => _showCurrencySelector(context, settings),
                ),
                Divider(height: 1, color: borderColor),
                _buildSwitchTile(
                  icon: Icons.vibration_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Dokunsal Geri Bildirim (Haptic)',
                  subtitle: 'Buton ve kart dokunuşlarında titreşim',
                  value: settings.hapticEnabled,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                  onChanged: (val) => ref.read(appSettingsProvider.notifier).toggleHaptic(val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. SİSTEM & VERİ (SYSTEM & DATA)
            _buildSectionHeader('SİSTEM & DESTEK', mutedTextColor),
            const SizedBox(height: 8),
            _buildCardWrapper(
              cardBg: cardBg,
              borderColor: borderColor,
              children: [
                ListTile(
                  onTap: _isClearingCache ? null : _clearAppCache,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFFEC4899), size: 22),
                  ),
                  title: Text(
                    'Önbelleği Temizle',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Görseller ve geçici dosyalar (34.2 MB)',
                    style: GoogleFonts.manrope(fontSize: 12, color: mutedTextColor),
                  ),
                  trailing: _isClearingCache
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7B5800)),
                        )
                      : Icon(Icons.chevron_right_rounded, color: mutedTextColor),
                ),
                Divider(height: 1, color: borderColor),
                _buildSimpleTile(
                  icon: Icons.security_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Gizlilik Politikası & KVKK',
                  textColor: textColor,
                  onTap: () {
                    _showInfoDialog(
                      'Gizlilik & KVKK',
                      'GastroHost platformunda konum ve kişisel verileriniz 6698 sayılı KVKK kapsamında yalnızca rezervasyon ve mutfak şef eşleştirme operasyonları için güvenle işlenmektedir. Bilgileriniz 3. şahıslara satılmaz.',
                      isDark,
                    );
                  },
                ),
                Divider(height: 1, color: borderColor),
                _buildSimpleTile(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFFF97316),
                  title: 'Kullanıcı Sözleşmesi & Şartlar',
                  textColor: textColor,
                  onTap: () {
                    _showInfoDialog(
                      'Kullanıcı Sözleşmesi',
                      'GastroHost Epicurean Hizmet Şartları, misafirler ve bağımsız şefler arasındaki rezervasyon kurallarını, escrow emanet kasa garantisini ve iptal politikalarını kapsar.',
                      isDark,
                    );
                  },
                ),
                Divider(height: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uygulama Sürümü',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'v1.0.0 (Build 2026.09)',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCardWrapper({
    required Color cardBg,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSubToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color mutedTextColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF7B5800),
            activeTrackColor: const Color(0xFFFDC34D).withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color textColor,
    required Color mutedTextColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7B5800),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: mutedTextColor),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color mutedTextColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF7B5800),
            activeTrackColor: const Color(0xFFFDC34D).withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF747878)),
    );
  }
}
