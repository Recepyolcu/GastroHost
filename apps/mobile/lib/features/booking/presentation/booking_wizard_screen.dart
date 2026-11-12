import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class BookingWizardScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> provider;
  final Map<String, dynamic> menu;
  final Function(String bookingId) onBookingComplete;
  final VoidCallback? onBack;
  final DateTime? initialDate;

  const BookingWizardScreen({
    super.key,
    required this.provider,
    required this.menu,
    required this.onBookingComplete,
    this.onBack,
    this.initialDate,
  });

  @override
  ConsumerState<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 30);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 2));
    _includeBartenderUpsell = widget.provider['include_bartender_upsell'] == true;
  }
  int _guestCount = 4;
  int _hoursCount = 3;

  bool _hasStove = true;
  bool _hasOven = true;
  bool _hasBlender = true;
  bool _ingredientsIncluded = true;
  bool _includeBartenderUpsell = false;
  static const double _bartenderUpsellFee = 2550.0;

  final TextEditingController _addressController = TextEditingController(
    text: 'Caferağa Mah. Moda Cad. No:14 D:3, Kadıköy / İstanbul',
  );

  final Set<String> _selectedAllergies = {};
  final TextEditingController _allergyNoteController = TextEditingController();

  final List<Map<String, dynamic>> _allergenOptions = [
    {'name': 'Glüten Hassasiyeti (Çölyak)', 'icon': Icons.grain_rounded},
    {'name': 'Laktoz İntoleransı', 'icon': Icons.water_drop_outlined},
    {'name': 'Kabuklu Deniz Ürünü', 'icon': Icons.set_meal_rounded},
    {'name': 'Fındık & Fıstık Alerjisi', 'icon': Icons.warning_amber_rounded},
    {'name': 'Yumurta Alerjisi', 'icon': Icons.egg_outlined},
    {'name': 'Soya Alerjisi', 'icon': Icons.grass_rounded},
    {'name': 'Vejetaryen Menü', 'icon': Icons.eco_rounded},
    {'name': 'Vegan Menü', 'icon': Icons.spa_rounded},
    {'name': 'Helal Kesim / Koşer', 'icon': Icons.verified_user_outlined},
    {'name': 'Alkol Hassasiyeti', 'icon': Icons.no_drinks_rounded},
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _allergyNoteController.dispose();
    super.dispose();
  }

  bool get _isHourly =>
      widget.provider['provider_type'] == 'bartender' ||
      (widget.provider['price']?.toString().contains('/hr') ?? false) ||
      (widget.provider['price']?.toString().contains('/saat') ?? false) ||
      (widget.provider['id']?.toString().startsWith('m') ?? false);

  double get _unitPrice {
    final menuPrice = (widget.menu['price_per_person'] as num?)?.toDouble();
    if (menuPrice != null && menuPrice > 0) return menuPrice;
    final provHourly = (widget.provider['hourly_rate'] as num?)?.toDouble();
    if (_isHourly && provHourly != null && provHourly > 0) return provHourly;
    final provPerPerson = (widget.provider['price_per_person'] as num?)?.toDouble();
    if (!_isHourly && provPerPerson != null && provPerPerson > 0) return provPerPerson;
    final provUnitPrice = (widget.provider['unit_price'] as num?)?.toDouble();
    if (provUnitPrice != null && provUnitPrice > 0) return provUnitPrice;
    return _isHourly ? 850.0 : 1850.0;
  }

  double get _effectiveUnitPrice =>
      _ingredientsIncluded ? _unitPrice : (_unitPrice * 0.80);

  double get _baseServiceAmount => _isHourly
      ? _effectiveUnitPrice * _hoursCount
      : _effectiveUnitPrice * _guestCount;

  double get _totalAmount =>
      _baseServiceAmount + (!_isHourly && _includeBartenderUpsell ? _bartenderUpsellFee : 0.0);

  double get _platformFee => _totalAmount * 0.10; // %10 GastroHost Komisyonu
  double get _providerEarnings => _totalAmount - _platformFee; // %90 Uzman Hakedişi

  Future<void> _selectDate(bool isDark, AppThemePalette palette) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: palette.goldAccent,
                    onPrimary: const Color(0xFF0B0D11),
                    surface: palette.surface,
                    onSurface: palette.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF7B5800),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1B1C1C),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isDark, AppThemePalette palette) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: palette.goldAccent,
                    onPrimary: const Color(0xFF0B0D11),
                    surface: palette.surface,
                    onSurface: palette.textPrimary,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF7B5800),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1B1C1C),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);
    final String providerName = widget.provider['name'] ?? (_isHourly ? 'Marcus T.' : 'Chef Julian');

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
          _isHourly ? 'Mixologist Booking & Escrow' : 'Chef Booking & Escrow',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(palette, isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header Banner
              _buildHeaderProviderBanner(providerName, palette, isDark),
              const SizedBox(height: 20),

              // Step 1: Date, Time & Hours/Guests Picker
              _buildSectionCard(
                icon: Icons.calendar_today_rounded,
                title: 'Date & Time',
                palette: palette,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildPickerTile(
                      label: 'Event Date',
                      value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      icon: Icons.edit_calendar_rounded,
                      palette: palette,
                      onTap: () => _selectDate(isDark, palette),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: palette.border, height: 1),
                    ),
                    _buildPickerTile(
                      label: 'Start Time',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time_rounded,
                      palette: palette,
                      onTap: () => _selectTime(isDark, palette),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: palette.border, height: 1),
                    ),
                    // Quantity Selector (Guests for Chef, Hours for Mixologist)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHourly ? 'Service Duration (Hours)' : 'Number of Guests',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Text(
                                '₺${_unitPrice.toStringAsFixed(0)} / ${_isHourly ? 'hour' : 'person'}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildCountBtn(
                                icon: Icons.remove,
                                palette: palette,
                                onTap: (_isHourly ? _hoursCount > 1 : _guestCount > 1)
                                    ? () => setState(() {
                                          if (_isHourly) {
                                            _hoursCount--;
                                          } else {
                                            _guestCount--;
                                          }
                                        })
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  _isHourly ? '$_hoursCount hrs' : '$_guestCount guests',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                              _buildCountBtn(
                                icon: Icons.add,
                                palette: palette,
                                onTap: (_isHourly ? _hoursCount < 12 : _guestCount < 30)
                                    ? () => setState(() {
                                          if (_isHourly) {
                                            _hoursCount++;
                                          } else {
                                            _guestCount++;
                                          }
                                        })
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 2: Kitchen & Bar Equipment Checklist
              _buildSectionCard(
                icon: _isHourly ? Icons.local_bar_rounded : Icons.countertops_rounded,
                title: _isHourly ? 'Bar Setup & Equipment' : 'Kitchen Requirements',
                subtitle: _isHourly
                    ? 'Confirm available bar space and glassware for cocktail service.'
                    : 'Confirm available appliances to ensure smooth food prep.',
                palette: palette,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: _isHourly ? 'Dedicated bar counter or table' : 'Stovetop / Cooktop accessible',
                      value: _hasStove,
                      palette: palette,
                      onChanged: (v) => setState(() => _hasStove = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: _isHourly ? 'Bar glassware & shaker access' : 'Working oven accessible',
                      value: _hasOven,
                      palette: palette,
                      onChanged: (v) => setState(() => _hasOven = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: _isHourly ? 'Ice supply & cooler accessible' : 'Blender or food processor',
                      value: _hasBlender,
                      palette: palette,
                      onChanged: (v) => setState(() => _hasBlender = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Alerjen & Özel Diyet Tercihleri (PRD Tech Spec 3.4)
              _buildSectionCard(
                icon: Icons.health_and_safety_rounded,
                title: 'Alerjen & Özel Diyet Tercihleri',
                subtitle: 'Şefiniz malzeme tedariğini ve hazırlık tezgahını bu tercihlere göre özel organize edecektir.',
                palette: palette,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allergenOptions.map((opt) {
                        final String name = opt['name'];
                        final IconData icon = opt['icon'];
                        final isSelected = _selectedAllergies.contains(name);

                        return FilterChip(
                          avatar: Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? (isDark ? const Color(0xFF0B0D11) : Colors.white)
                                : palette.goldAccent,
                          ),
                          label: Text(name),
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
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : palette.borderSubtle,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAllergies.add(name);
                              } else {
                                _selectedAllergies.remove(name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Özel Alerjen / Diyet Notu (Varsa)',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _allergyNoteController,
                      maxLines: 2,
                      style: GoogleFonts.manrope(fontSize: 13, color: palette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Örn: 1 misafirimizde kabuklu fıstık alerjisi var, ayrı tavada hazırlansın...',
                        hintStyle: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: palette.surfaceElevated,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.goldAccent)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 3.5: Malzeme Tedarik Tercihi (PRD 3.3) & Barmen Upsell (PRD 3.4)
              _buildSectionCard(
                icon: Icons.shopping_basket_rounded,
                title: 'Malzeme Tedariği & Ekstra Deneyim',
                subtitle: 'Taze malzemelerin kim tarafından temin edileceğini ve miksoloji eşleşmesini seçin.',
                palette: palette,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSwitchTile(
                      title: _ingredientsIncluded
                          ? 'Malzemeler Uzmandan (%100 Tedarik Dahil)'
                          : 'Malzemeleri Ev Sahibi Temin Eder (%20 İndirim)',
                      value: _ingredientsIncluded,
                      palette: palette,
                      onChanged: (v) => setState(() => _ingredientsIncluded = v),
                    ),
                    if (!_isHourly) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withValues(alpha: isDark ? 0.14 : 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _includeBartenderUpsell
                                ? const Color(0xFF9333EA)
                                : const Color(0xFF9333EA).withValues(alpha: 0.3),
                            width: _includeBartenderUpsell ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9333EA).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_bar_rounded,
                                color: Color(0xFFC084FC),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Master Miksolojist & Mobil Bar Ekle',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '3 saat boyunca imza kokteyl eşleşmesi (+₺${_bartenderUpsellFee.toStringAsFixed(0)})',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _includeBartenderUpsell,
                              activeThumbColor: const Color(0xFF9333EA),
                              activeTrackColor: const Color(0xFF9333EA).withValues(alpha: 0.35),
                              onChanged: (v) => setState(() => _includeBartenderUpsell = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 4: Etkinlik Adresi & Konum Bilgisi
              _buildSectionCard(
                icon: Icons.location_on_rounded,
                title: 'Etkinlik Adresi & Konum Bilgisi',
                palette: palette,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: palette.emerald, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Teslimat Bölgesi: Kadıköy, İstanbul',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: palette.emerald,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Açık Adres (Hizmet Verilecek Ev/Mekan)',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      style: GoogleFonts.manrope(fontSize: 13, color: palette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Mahalle, Sokak, Bina No, Daire, İç kapı tarifini girin...',
                        hintStyle: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: palette.surfaceElevated,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.goldAccent)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 4: Payment & Escrow Guarantee Summary
              _buildSectionCard(
                icon: Icons.shield_outlined,
                title: 'Escrow Güvencesi & Ödeme Detayı',
                palette: palette,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.emerald.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.emerald.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock_rounded, color: palette.emerald, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ödemeniz hizmet başarıyla tamamlanana kadar GastroHost Güvenli Escrow Havuzunda bloke edilir. Hizmet bitişinde şefe aktarılır.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFeeRow(
                      _isHourly
                          ? 'Saatlik Ücret (₺${_effectiveUnitPrice.toStringAsFixed(0)} × $_hoursCount saat)'
                          : 'Kişi Başı Ücret (₺${_effectiveUnitPrice.toStringAsFixed(0)} × $_guestCount kişi)',
                      '₺${_baseServiceAmount.toStringAsFixed(0)}',
                      palette: palette,
                    ),
                    if (!_isHourly && _includeBartenderUpsell) ...[
                      const SizedBox(height: 8),
                      _buildFeeRow(
                        'Master Miksolojist & Mobil Bar Paketi (3 Saat)',
                        '+₺${_bartenderUpsellFee.toStringAsFixed(0)}',
                        valueColor: const Color(0xFFC084FC),
                        palette: palette,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildFeeRow(
                      'GastroHost Platform Komisyonu (%10)',
                      '₺${_platformFee.toStringAsFixed(0)}',
                      palette: palette,
                    ),
                    Divider(color: palette.border, height: 20),
                    _buildFeeRow(
                      'Toplam Bloke Edilecek Tutar',
                      '₺${_totalAmount.toStringAsFixed(0)}',
                      isBold: true,
                      palette: palette,
                    ),
                    const SizedBox(height: 8),
                    _buildFeeRow(
                      _isHourly ? 'Barmen Hakedişi (%90)' : 'Şef Hakedişi (%90)',
                      '₺${_providerEarnings.toStringAsFixed(0)}',
                      valueColor: palette.goldAccent,
                      palette: palette,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderProviderBanner(String providerName, AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.goldAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isHourly ? Icons.local_bar_rounded : Icons.restaurant_menu_rounded,
              color: palette.goldAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  widget.menu['title'] ?? (_isHourly ? 'Signature Craft Cocktail Bar' : 'The Truffle Experience'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Text(
              _isHourly ? 'Hourly Rate' : 'Escrow Ready',
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
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required AppThemePalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border),
              ),
              child: Icon(icon, size: 18, color: palette.goldAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBtn({
    required IconData icon,
    VoidCallback? onTap,
    required AppThemePalette palette,
  }) {
    final bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled ? palette.surfaceElevated.withValues(alpha: 0.5) : palette.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? palette.textMuted : palette.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppThemePalette palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: palette.goldAccent,
            activeTrackColor: palette.goldAccent.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    required AppThemePalette palette,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? palette.textPrimary : palette.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? palette.textPrimary : palette.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
    required AppThemePalette palette,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.goldAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  bool _isProcessing = false;

  void _showPaymentModalSheet(AppThemePalette palette, bool isDark) {
    final bookingState = ref.read(bookingProvider);
    final hasSameDayConflict = bookingState.bookings.any((b) =>
        b.status != 'completed' &&
        b.status != 'cancelled' &&
        b.eventDate.year == _selectedDate.year &&
        b.eventDate.month == _selectedDate.month &&
        b.eventDate.day == _selectedDate.day);
    if (hasSameDayConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Seçtiğiniz tarihte halihazırda aktif bir rezervasyonunuz bulunuyor. Lütfen farklı bir etkinlik tarihi seçin.'),
          backgroundColor: Color(0xFFD97706),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: 'Ahmet Yılmaz');
    final cardNumberController = TextEditingController(text: '4543 •••• •••• 0000');
    final expiryController = TextEditingController(text: '12/28');
    final cvcController = TextEditingController(text: '321');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: palette.goldAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.payment_rounded, color: palette.goldAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'iyzico Güvenli Ödeme & Escrow',
                                style: GoogleFonts.libreCaslonText(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Text(
                                'GastroHost Pazaryeri 3D Secure Proteksiyonu',
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
                    const SizedBox(height: 16),

                    // Escrow Info Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.emerald.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.emerald.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: palette.emerald, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ödemeniz ₺${_totalAmount.toStringAsFixed(0)} tutarında GastroHost Güvenli Havuzunda bloke edilecek, %10 platform komisyonu ayrılıp %90 hakediş hizmet sonrasında şefe aktarılacaktır.',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: palette.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Cardholder Name
                    Text('Kart Üzerindeki İsim', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: palette.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.goldAccent)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card Number
                    Text('Kart Numarası', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cardNumberController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: palette.surfaceElevated,
                        suffixIcon: Icon(Icons.credit_card_rounded, color: palette.goldAccent, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.goldAccent)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Expiry & CVC
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Son Kullanma', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: expiryController,
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: palette.surfaceElevated,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.goldAccent)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CVC / CVV', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: cvcController,
                                obscureText: true,
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: palette.surfaceElevated,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.goldAccent)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                Navigator.pop(modalContext);
                                _processPayAndReserve();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? palette.goldAccent : Colors.black,
                          foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Ödemeyi Onayla ve Bloke Et (₺${_totalAmount.toStringAsFixed(0)})',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processPayAndReserve() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final List<String> userAllergies = _selectedAllergies.toList();
      if (_allergyNoteController.text.trim().isNotEmpty) {
        userAllergies.add('Özel Not: ${_allergyNoteController.text.trim()}');
      }
      if (userAllergies.isEmpty) {
        userAllergies.add('Belirtilen alerjen veya diyet hassasiyeti yok');
      }

      final supabaseService = SupabaseService();
      final providerId = widget.provider['id']?.toString() ?? 'prov_demo_101';
      final menuId = widget.menu['id']?.toString() ?? 'menu_demo_101';

      // 1. Create booking record
      String bookingId = 'b_${DateTime.now().millisecondsSinceEpoch}';
      String? dbBookingCode;
      try {
        final booking = await supabaseService.createBooking(
          providerId: providerId,
          menuId: menuId,
          eventDate: _selectedDate,
          eventTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          guestCount: _guestCount,
          isHourly: _isHourly,
          hoursCount: _hoursCount,
          unitPrice: _effectiveUnitPrice,
          totalPrice: _totalAmount,
          platformFee: _platformFee,
          providerEarnings: _providerEarnings,
          ingredientsIncluded: _ingredientsIncluded,
          kitchenDetails: {
            'stove': _hasStove,
            'oven': _hasOven,
            'blender': _hasBlender,
            'bartender_upsell': !_isHourly && _includeBartenderUpsell,
          },
          allergies: userAllergies,
          eventAddress: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : 'Caferağa Mah. Moda Cad. No:14 D:3, Kadıköy / İstanbul',
        );
        bookingId = booking['id']?.toString() ?? bookingId;
        dbBookingCode = booking['booking_code']?.toString();
      } catch (e) {
        debugPrint('Demo mode booking fallback: $e');
      }

      // 2. Process Escrow Payment (10% Commission / 90% Provider Earnings)
      try {
        await supabaseService.processEscrowPayment(
          bookingId: bookingId,
          amount: _totalAmount,
          gateway: 'iyzico',
          commissionRate: 0.10,
        );
      } catch (e) {
        debugPrint('Demo mode escrow fallback: $e');
      }

      // 3. Save to central BookingProvider with full details
      final newBooking = ref.read(bookingProvider.notifier).addBooking(
        provider: widget.provider,
        menu: widget.menu,
        eventDate: _selectedDate,
        eventTime: _selectedTime,
        guestCount: _guestCount,
        hoursCount: _hoursCount,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : 'Caferağa Mah. Moda Cad. No:14 D:3, Kadıköy / İstanbul',
        kitchenDetails: {
          'stove': _hasStove,
          'oven': _hasOven,
          'blender': _hasBlender,
          'mobile_bar': _isHourly || _includeBartenderUpsell,
        },
        allergies: userAllergies,
        totalPrice: _totalAmount,
        platformFee: _platformFee,
        providerEarnings: _providerEarnings,
        unitPrice: _effectiveUnitPrice,
        isHourly: _isHourly,
        ingredientsIncluded: _ingredientsIncluded,
        dbUuid: bookingId.startsWith('b_') ? null : bookingId,
        customBookingId: dbBookingCode ?? (bookingId.startsWith('b_') ? 'GH-${bookingId.replaceAll('b_', '').substring(0, 5)}' : bookingId),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ödeme iyzico Escrow havuzuna başarıyla bloke edildi! Rezervasyonunuz oluşturuldu.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onBookingComplete(newBooking.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ödeme hatası: $e')),
        );
      }
    }
  }

  Widget _buildBottomCheckoutBar(AppThemePalette palette, bool isDark) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toplam ₺${_totalAmount.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: palette.goldAccent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Escrow Korumalı (%10)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: palette.goldAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _showPaymentModalSheet(palette, isDark),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? palette.goldAccent : Colors.black,
                foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isProcessing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? const Color(0xFF0B0D11) : Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Öde & Rezerve Et',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
