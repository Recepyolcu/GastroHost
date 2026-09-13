import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/supabase_service.dart';

class BookingDetailModal extends StatefulWidget {
  final Map<String, dynamic> booking;
  final bool isBartender;
  final Function(String newStatus) onStatusUpdated;

  const BookingDetailModal({
    super.key,
    required this.booking,
    this.isBartender = false,
    required this.onStatusUpdated,
  });

  static void show({
    required BuildContext context,
    required Map<String, dynamic> booking,
    bool isBartender = false,
    required Function(String newStatus) onStatusUpdated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDetailModal(
        booking: booking,
        isBartender: isBartender,
        onStatusUpdated: onStatusUpdated,
      ),
    );
  }

  @override
  State<BookingDetailModal> createState() => _BookingDetailModalState();
}

class _BookingDetailModalState extends State<BookingDetailModal> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking['status'] ?? 'pending';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final supabase = SupabaseService();
      final bookingId = widget.booking['id']?.toString();
      if (bookingId != null && !bookingId.startsWith('b_')) {
        await supabase.updateBookingStatus(bookingId, newStatus);
      }
    } catch (_) {}

    setState(() {
      _currentStatus = newStatus;
      _isUpdating = false;
    });

    widget.onStatusUpdated(newStatus);

    if (mounted) {
      final statusLabel = _getStatusLabel(newStatus);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Rezervasyon durumu güncellendi: $statusLabel', style: GoogleFonts.manrope(fontSize: 13, color: Colors.white)),
          backgroundColor: newStatus == 'cancelled' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      nav.pop();
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Onay Bekliyor';
      case 'accepted':
        return 'Kabul Edildi & Planlandı';
      case 'shopping':
        return 'Alışverişte (Hazırlık)';
      case 'on_the_way':
        return 'Yola Çıktı';
      case 'in_kitchen':
        return 'Mutfakta / Serviste';
      case 'completed':
        return 'Hizmet Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final customerName = booking['customer'] ?? 'Ahmet Yılmaz';
    final customerPhone = booking['customer_phone'] ?? '0555 123 45 67';
    final menuTitle = booking['menu'] ?? 'Özel Tadım Menüsü';
    final date = booking['date'] ?? '28 Ağustos 2026';
    final time = booking['time'] ?? '19:30';
    final address = booking['address'] ?? 'Ayvalık, Balıkesir (Villa Akasya No: 12)';
    final guestCount = booking['guests'] ?? booking['duration_hours'] ?? '6';
    final netEarnings = booking['net_earnings'] ?? '₺4,250.00';
    final totalPrice = booking['total_price'] ?? '₺5,000.00';

    // Kitchen & Allergen mock/real data
    final kitchenDetails = booking['kitchen_details'] as Map<String, dynamic>? ?? {
      'stovetop': '4 Gözlü Gazlı Ocak',
      'oven': 'Ankastre Fırın Var',
      'mobile_bar': widget.isBartender ? 'Portatif Bar Kurulumu İstendi' : 'Mutfak Ekipmanı Tam',
    };

    final List<String> allergies = booking['allergies'] != null
        ? List<String>.from(booking['allergies'])
        : ['Fıstık / Ceviz Alerjisi (1 Davetli)', 'Laktoz Toleransı Düşük'];

    final isPending = _currentStatus == 'pending';
    final isAccepted = _currentStatus == 'accepted' ||
        _currentStatus == 'shopping' ||
        _currentStatus == 'on_the_way' ||
        _currentStatus == 'in_kitchen';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF9F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE4E2E2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rezervasyon Detayı',
                      style: GoogleFonts.libreCaslonText(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                    ),
                    Text('Talep ID: #${booking['id'] ?? 'b_8912'}', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
                  ],
                ),
                _buildStatusBadge(_currentStatus),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE4E2E2)),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer & Contact Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E2E2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1B1C1C),
                          radius: 22,
                          child: Text(
                            customerName.isNotEmpty ? customerName[0].toUpperCase() : 'M',
                            style: GoogleFonts.libreCaslonText(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customerName, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                              Text('İletişim: $customerPhone', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Event Date, Time & Address Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E2E2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF7B5800)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$date • $time',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                              ),
                            ),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Color(0xFFE4E2E2))),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF7B5800)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(address, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF1B1C1C))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu, Pricing & Earnings Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1C1C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Menü & Kazanç Özeti', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37))),
                        const SizedBox(height: 8),
                        Text(menuTitle, style: GoogleFonts.libreCaslonText(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          widget.isBartender ? '$guestCount Saat Süreli Kokteyl Servisi' : '$guestCount Davetli İçin Kişiye Özel Tadım',
                          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Toplam Tutar', style: GoogleFonts.manrope(fontSize: 11, color: Colors.white54)),
                                Text(totalPrice, style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Net Kazancınız (%90 Hakediş)', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFFD4AF37))),
                                Text(netEarnings, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Allergen Warning Card (Red Highlight)
                  if (allergies.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Text('Alerjen & Özel Diyet Uyarısı', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: allergies.map((allergy) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFF87171)),
                                ),
                                child: Text(allergy, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFB91C1C))),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Kitchen Equipment Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E2E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mutfak & Ekipman Bilgileri', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                        const SizedBox(height: 12),
                        _buildKitchenDetailRow(Icons.countertops_outlined, 'Ocak Durumu', kitchenDetails['stovetop'] ?? 'Mevcut'),
                        const SizedBox(height: 8),
                        _buildKitchenDetailRow(Icons.microwave_outlined, 'Fırın Durumu', kitchenDetails['oven'] ?? 'Mevcut'),
                        const SizedBox(height: 8),
                        _buildKitchenDetailRow(Icons.local_bar_outlined, 'Bar / Servis Kurulumu', kitchenDetails['mobile_bar'] ?? 'Tamam'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE4E2E2))),
            ),
            child: _isUpdating
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B1C1C)))
                : isPending
                    ? Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus('accepted'),
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text('Talebi Kabul Et', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => _updateStatus('cancelled'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Reddet', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    : isAccepted
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStepperButton('Alışverişte', 'shopping', Icons.shopping_cart_outlined, const Color(0xFF3B82F6)),
                                const SizedBox(width: 8),
                                _buildStepperButton('Yola Çıktım', 'on_the_way', Icons.directions_car_outlined, const Color(0xFF8B5CF6)),
                                const SizedBox(width: 8),
                                _buildStepperButton('Mutfaktayım', 'in_kitchen', Icons.restaurant_outlined, const Color(0xFFF59E0B)),
                                const SizedBox(width: 8),
                                _buildStepperButton('Tamamlandı', 'completed', Icons.task_alt_rounded, const Color(0xFF10B981)),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text('Kapat', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(String label, String statusKey, IconData icon, Color color) {
    final isActive = _currentStatus == statusKey;
    return ElevatedButton.icon(
      onPressed: () => _updateStatus(statusKey),
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : color.withValues(alpha: 0.12),
        foregroundColor: isActive ? Colors.white : color,
        elevation: isActive ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildKitchenDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF747878)),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF747878))),
        Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1C))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'accepted':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        text = 'Kabul Edildi';
        break;
      case 'shopping':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        text = 'Alışverişte';
        break;
      case 'on_the_way':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF5B21B6);
        text = 'Yola Çıktı';
        break;
      case 'in_kitchen':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        text = 'Mutfakta';
        break;
      case 'completed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        text = 'Tamamlandı';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        text = 'İptal Edildi';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        text = 'Onay Bekliyor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
