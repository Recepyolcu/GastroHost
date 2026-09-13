import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/supabase_service.dart';
import '../../booking/presentation/widgets/booking_detail_modal.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final VoidCallback onSwitchToCustomer;
  final Function(String bookingId, String customerName) onOpenChat;
  final VoidCallback? onManageMenus;

  const ProviderDashboardScreen({
    super.key,
    required this.onSwitchToCustomer,
    required this.onOpenChat,
    this.onManageMenus,
  });

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _isAvailable = true;
  String _providerType = 'chef'; // 'chef' or 'bartender'
  List<Map<String, dynamic>> _activeBookings = [];

  final List<Map<String, dynamic>> _chefBookings = [
    {
      'id': 'b101',
      'customer': 'Ahmet Yılmaz',
      'date': 'Oct 24, 2026 • 7:30 PM',
      'guests': 6,
      'net_earnings': '₺9.990',
      'status': 'pending',
      'menu': 'Tuscan Truffle Experience',
      'tags': ['Gluten-Free Required', '4-Burner Stove'],
    },
    {
      'id': 'b102',
      'customer': 'Zeynep Kaya',
      'date': 'Oct 26, 2026 • 8:00 PM',
      'guests': 4,
      'net_earnings': '₺6.660',
      'status': 'accepted',
      'menu': 'Grand Tasting (5-Course)',
      'tags': ['Lactose Intolerant'],
    },
  ];

  final List<Map<String, dynamic>> _bartenderBookings = [
    {
      'id': 'b201',
      'customer': 'Can Demir',
      'date': 'Oct 25, 2026 • 8:30 PM',
      'guests': 8,
      'duration_hours': 4,
      'net_earnings': '₺3.060',
      'status': 'pending',
      'menu': 'Signature Craft Cocktail Bar',
      'tags': ['Ice Supply Needed', 'Glassware Provided'],
    },
    {
      'id': 'b202',
      'customer': 'Merve Öz',
      'date': 'Oct 27, 2026 • 9:00 PM',
      'guests': 12,
      'duration_hours': 3,
      'net_earnings': '₺2.025',
      'status': 'accepted',
      'menu': 'Classic & Vintage Cocktail Tasting',
      'tags': ['Counter Space Ready'],
    },
  ];


  String _onboardingStatus = 'pending_approval';

  @override
  void initState() {
    super.initState();
    _activeBookings = List.from(_chefBookings);
    _loadProviderType();
  }

  Future<void> _loadProviderType() async {
    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      if (user != null) {
        final profile = await supabase.client
            .from('provider_profiles')
            .select('provider_type, onboarding_status')
            .eq('user_id', user.id)
            .maybeSingle();
        if (profile != null) {
          setState(() {
            _providerType = profile['provider_type'] ?? _providerType;
            _onboardingStatus = profile['onboarding_status'] ?? 'pending_approval';
            _activeBookings = _providerType == 'bartender'
                ? List.from(_bartenderBookings)
                : List.from(_chefBookings);
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isBartender = _providerType == 'bartender';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: widget.onSwitchToCustomer,
        ),
        title: Text(
          isBartender ? 'Mixologist Dashboard' : 'Chef Dashboard',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _providerType = isBartender ? 'chef' : 'bartender';
                _activeBookings = _providerType == 'bartender'
                    ? List.from(_bartenderBookings)
                    : List.from(_chefBookings);
              });
            },
            icon: Icon(
              isBartender ? Icons.restaurant_menu_rounded : Icons.local_bar_rounded,
              color: const Color(0xFF7B5800),
            ),
            tooltip: isBartender ? 'Switch to Chef Dashboard' : 'Switch to Mixologist Dashboard',
          ),
          IconButton(
            onPressed: widget.onSwitchToCustomer,
            icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF7B5800)),
            tooltip: 'Switch to Customer Mode',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Availability Toggle Card
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Available for Booking Requests',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isAvailable
                        ? (isBartender
                            ? 'Receiving craft cocktail requests'
                            : 'Receiving new private dining requests')
                        : 'Offline / Unavailable',
                    style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                  ),
                  value: _isAvailable,
                  activeThumbColor: const Color(0xFF7B5800),
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),
              const SizedBox(height: 16),

              // Manage Menus & Cocktail Packages Banner
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                ),
                child: InkWell(
                  onTap: widget.onManageMenus,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B5800).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isBartender ? Icons.local_bar_rounded : Icons.restaurant_menu_rounded,
                            color: const Color(0xFF7B5800),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBartender ? 'Kokteyl & Bar Paketlerimi Yönet' : 'Menülerimi ve Fiyatlarımı Yönet',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                              ),
                              Text(
                                isBartender ? 'Yeni kokteyl reçetesi ve saatlik tarifeler ekleyin' : 'Yeni yemek menüsü ekleyin veya içerikleri düzenleyin',
                                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF747878)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Document Approval & Verification Badges Status Card
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: Color(0xFF7B5800), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Belge & Rozet Durumu',
                                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _onboardingStatus == 'approved'
                                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _onboardingStatus == 'approved'
                                  ? (isBartender ? 'Aktif Barmen Profili' : 'Aktif Şef Profili')
                                  : 'Başvuru Onay Bekliyor',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _onboardingStatus == 'approved'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _onboardingStatus == 'approved'
                            ? 'Belgeleriniz admin ekibimizce incelenmiş ve onaylanmıştır. Canlı rezervasyon taleplerini kabul edebilirsiniz.'
                            : 'Başvurunuz ve belgeleriniz admin ekibimiz tarafından incelenmektedir. İnceleme tamamlandığında bildirim alacaksınız.',
                        style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadgeChip('Kimlik Doğrulama',
                              isApproved: _onboardingStatus == 'approved', isPending: _onboardingStatus == 'pending_approval'),
                          _buildBadgeChip('Hijyen Sertifikası',
                              isApproved: false, isPending: true),
                          _buildBadgeChip(isBartender ? 'Miksoloji Sertifikası' : 'Gastronomi Diploması',
                              isApproved: false, isPending: false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Earnings Summary Card
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escrow Earnings Summary',
                        style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBartender ? '\$1,850.00' : '\$2,450.00',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE4E2E2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending Payouts', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878))),
                              Text(isBartender ? '\$560.00' : '\$840.00', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Completed Events', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878))),
                              Text(isBartender ? '12 Events' : '18 Events', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Incoming Bookings Header
              Text(
                'Booking Requests',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B1C1C),
                ),
              ),
              const SizedBox(height: 16),

              // Booking Request Cards
              if (_activeBookings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No active booking requests.',
                      style: GoogleFonts.manrope(color: const Color(0xFF747878)),
                    ),
                  ),
                )
              else
                ..._activeBookings.map((booking) {
                  final isPending = booking['status'] == 'pending';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E2E2)),
                      boxShadow: [
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
                              booking['customer'],
                              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                            ),
                            Text(
                              booking['net_earnings'],
                              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBartender
                              ? '${booking['menu']} • ${booking['duration_hours']} hours'
                              : '${booking['menu']} • ${booking['guests']} guests',
                          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
                        ),
                        Text(
                          booking['date'],
                          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                        ),
                        const SizedBox(height: 12),

                        // Tags
                        Wrap(
                          spacing: 6,
                          children: (booking['tags'] as List<String>).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEDED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(tag, style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF1B1C1C))),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  BookingDetailModal.show(
                                    context: context,
                                    booking: booking,
                                    isBartender: isBartender,
                                    onStatusUpdated: (newStatus) {
                                      setState(() {
                                        booking['status'] = newStatus;
                                      });
                                    },
                                  );
                                },
                                icon: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1B1C1C)),
                                label: Text('Talebi İncele & Mutfak Detayları', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => widget.onOpenChat(booking['id'], booking['customer']),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF7B5800)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF7B5800)),
                              label: Text('Chat', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800))),
                            ),
                          ],
                        ),
                        if (isPending) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() => booking['status'] = 'accepted');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Rezervasyon talebi kabul edildi!', style: GoogleFonts.manrope(fontSize: 13, color: Colors.white)),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                                  label: Text('Kabul Et', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() => booking['status'] = 'cancelled');
                                  },
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: Text('Reddet', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String label, {required bool isApproved, bool isPending = false}) {
    final Color bgColor = isApproved
        ? const Color(0xFF10B981).withValues(alpha: 0.1)
        : (isPending ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : const Color(0xFF6B7280).withValues(alpha: 0.1));
    final Color textColor = isApproved
        ? const Color(0xFF10B981)
        : (isPending ? const Color(0xFFD97706) : const Color(0xFF6B7280));
    final IconData icon = isApproved
        ? Icons.check_circle_rounded
        : (isPending ? Icons.hourglass_top_rounded : Icons.info_outline_rounded);
    final String statusText = isApproved ? ' (Onaylı Rozet)' : (isPending ? ' (İncelemede)' : ' (Yüklenmedi)');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$label$statusText',
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }
}
