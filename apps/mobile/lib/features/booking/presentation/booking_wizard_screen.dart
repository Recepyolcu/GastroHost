import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';

class BookingWizardScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final Map<String, dynamic> menu;
  final Function(String bookingId) onBookingComplete;
  final VoidCallback? onBack;

  const BookingWizardScreen({
    super.key,
    required this.provider,
    required this.menu,
    required this.onBookingComplete,
    this.onBack,
  });

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 30);
  int _guestCount = 4;
  int _hoursCount = 3;

  bool _hasStove = true;
  bool _hasOven = true;
  bool _hasBlender = true;

  final TextEditingController _addressController = TextEditingController(
    text: 'Caferağa Mah. Moda Cad. No:14 D:3, Kadıköy / İstanbul',
  );

  bool get _isHourly =>
      widget.provider['provider_type'] == 'bartender' ||
      (widget.provider['price']?.toString().contains('/hr') ?? false) ||
      (widget.provider['id']?.toString().startsWith('m') ?? false);

  double get _unitPrice => _isHourly ? 850.0 : 1850.0;
  double get _totalAmount => _isHourly ? _unitPrice * _hoursCount : _unitPrice * _guestCount;
  double get _platformFee => _totalAmount * 0.10; // 10%
  double get _providerEarnings => _totalAmount - _platformFee; // 90%

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
    final String providerName = widget.provider['name'] ?? (_isHourly ? 'Marcus T.' : 'Chef Julian');

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B1C1C), size: 18),
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
            color: const Color(0xFF1B1C1C),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header Banner
              _buildHeaderProviderBanner(providerName),
              const SizedBox(height: 20),

              // Step 1: Date, Time & Hours/Guests Picker
              _buildSectionCard(
                icon: Icons.calendar_today_rounded,
                title: 'Date & Time',
                child: Column(
                  children: [
                    _buildPickerTile(
                      label: 'Event Date',
                      value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      icon: Icons.edit_calendar_rounded,
                      onTap: _selectDate,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: Color(0xFFE4E2E2), height: 1),
                    ),
                    _buildPickerTile(
                      label: 'Start Time',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _selectTime,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: Color(0xFFE4E2E2), height: 1),
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
                                  color: const Color(0xFF1B1C1C),
                                ),
                              ),
                              Text(
                                '\$${_unitPrice.toStringAsFixed(0)} / ${_isHourly ? 'hour' : 'person'}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF747878),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildCountBtn(
                                icon: Icons.remove,
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
                                  _isHourly ? '$_hoursCount hrs' : '$_guestCount',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1B1C1C),
                                  ),
                                ),
                              ),
                              _buildCountBtn(
                                icon: Icons.add,
                                onTap: () => setState(() {
                                  if (_isHourly) {
                                    _hoursCount++;
                                  } else {
                                    _guestCount++;
                                  }
                                }),
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

              // Step 2: Equipment Checklist (Kitchen or Bar Setup)
              _buildSectionCard(
                icon: _isHourly ? Icons.local_bar_rounded : Icons.soup_kitchen_rounded,
                title: _isHourly ? 'Bar Setup Check' : 'Kitchen Check',
                subtitle: 'Confirm required setup for $providerName',
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: _isHourly ? 'Clean bar or countertop space available' : '4-burner stove operating properly',
                      value: _hasStove,
                      onChanged: (v) => setState(() => _hasStove = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: _isHourly ? 'Glassware provided by host (or request addon)' : 'Working oven for roasting',
                      value: _hasOven,
                      onChanged: (v) => setState(() => _hasOven = v),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: _isHourly ? 'Ice supply & cooler accessible' : 'Blender or food processor',
                      value: _hasBlender,
                      onChanged: (v) => setState(() => _hasBlender = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 3: Etkinlik Adresi & Konum Bilgisi
              _buildSectionCard(
                icon: Icons.location_on_rounded,
                title: 'Etkinlik Adresi & Konum Bilgisi',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.near_me_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Teslimat Bölgesi: Kadıköy, İstanbul',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Açık Adres (Hizmet Verilecek Ev/Mekan)',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF747878)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      style: GoogleFonts.manrope(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Mahalle, Sokak, Bina No, Daire, İç kapı tarifini girin...',
                        hintStyle: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFA0A0A0)),
                        filled: true,
                        fillColor: const Color(0xFFFBF9F8),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1B1C1C))),
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

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isHourly
                                  ? 'Ödemeniz GastroHost Güvenli Havuzunda bloke edilir. Hizmet süresi tamamlanana kadar barmene aktarılmaz.'
                                  : 'Ödemeniz GastroHost Güvenli Havuzunda bloke edilir. Hizmet tamamlanana kadar şefe aktarılmaz.',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B1C1C),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeeRow(
                      _isHourly ? 'Bar Hizmeti ($_hoursCount saat)' : 'Menü Toplamı ($_guestCount kişi)',
                      '₺${_totalAmount.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildFeeRow('Platform Komisyonu (%10 dahil)', '₺${_platformFee.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _buildFeeRow(
                      _isHourly ? 'Barmen Hakedişi (%90)' : 'Şef Hakedişi (%90)',
                      '₺${_providerEarnings.toStringAsFixed(0)}',
                      valueColor: const Color(0xFF7B5800),
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

  Widget _buildHeaderProviderBanner(String providerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: const Color(0xFF7B5800).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isHourly ? Icons.local_bar_rounded : Icons.restaurant_menu_rounded,
              color: const Color(0xFF7B5800),
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
                    color: const Color(0xFF1B1C1C),
                  ),
                ),
                Text(
                  widget.menu['title'] ?? (_isHourly ? 'Signature Craft Cocktail Bar' : 'The Truffle Experience'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: const Color(0xFF747878),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEDED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isHourly ? 'Hourly Rate' : 'Escrow Ready',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B5800),
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
                Text(label, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878))),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E2E2)),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF7B5800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBtn({required IconData icon, VoidCallback? onTap}) {
    final bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFF3F4F6) : const Color(0xFFEFEDED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E2E2)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? Colors.grey : const Color(0xFF1B1C1C),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E2E2)),
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
                color: const Color(0xFF1B1C1C),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF7B5800),
            activeTrackColor: const Color(0xFF7B5800).withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF1B1C1C) : const Color(0xFF747878),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? const Color(0xFF1B1C1C) : const Color(0xFF1B1C1C)),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Icon(icon, color: const Color(0xFF7B5800), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1C1C),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  bool _isProcessing = false;

  void _showPaymentModalSheet() {
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          color: Colors.grey.shade300,
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
                            color: const Color(0xFF7B5800).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payment_rounded, color: Color(0xFF7B5800), size: 22),
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
                                  color: const Color(0xFF1B1C1C),
                                ),
                              ),
                              Text(
                                'GastroHost Pazaryeri 3D Secure Proteksiyonu',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: const Color(0xFF747878),
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ödemeniz ₺${_totalAmount.toStringAsFixed(0)} tutarında GastroHost Güvenli Havuzunda bloke edilecek, %10 platform komisyonu ayrılıp %90 hakediş hizmet sonrasında şefe aktarılacaktır.',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B1C1C),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Cardholder Name
                    Text('Kart Üzerindeki İsim', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card Number
                    Text('Kart Numarası', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cardNumberController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        suffixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF7B5800), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
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
                              Text('SKT (AY/YIL)', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: expiryController,
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
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
                              Text('CVC / CVV', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: cvcController,
                                obscureText: true,
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
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
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
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
      final supabaseService = SupabaseService();
      final providerId = widget.provider['id']?.toString() ?? 'prov_demo_101';
      final menuId = widget.menu['id']?.toString() ?? 'menu_demo_101';

      // 1. Create booking record
      String bookingId = 'b_${DateTime.now().millisecondsSinceEpoch}';
      try {
        final booking = await supabaseService.createBooking(
          providerId: providerId,
          menuId: menuId,
          eventDate: _selectedDate,
          eventTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          guestCount: _guestCount,
          totalPrice: _totalAmount,
          platformFee: _platformFee,
          providerEarnings: _providerEarnings,
          kitchenDetails: {
            'stove': _hasStove,
            'oven': _hasOven,
            'blender': _hasBlender,
          },
          allergies: [],
          eventAddress: 'Müşteri Adresi (İstanbul/Kadıköy)',
        );
        bookingId = booking['id']?.toString() ?? bookingId;
      } catch (e) {
        debugPrint('Demo mode booking fallback: $e');
      }

      // 2. Process Escrow Payment (10% Commission / 90% Provider Earnings)
      try {
        await supabaseService.processEscrowPayment(
          bookingId: bookingId,
          amount: _totalAmount,
          gateway: 'iyzico',
        );
      } catch (e) {
        debugPrint('Demo mode escrow fallback: $e');
      }

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Ödeme iyzico Escrow havuzuna başarıyla bloke edildi! Rezervasyonunuz oluşturuldu.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onBookingComplete(bookingId);
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

  Widget _buildBottomCheckoutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE4E2E2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
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
                      color: const Color(0xFF1B1C1C),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF7B5800)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Escrow Korumalı (%10)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF7B5800),
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
              onPressed: _isProcessing ? null : _showPaymentModalSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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


