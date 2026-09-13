import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/services/supabase_service.dart';


class ProfileScreen extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onSwitchToChef;
  final VoidCallback? onStartChefOnboarding;
  final VoidCallback? onManageMenus;
  final VoidCallback? onOpenAdminSimulator;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.onSwitchToChef,
    this.onStartChefOnboarding,
    this.onManageMenus,
    this.onOpenAdminSimulator,
  });

  // 1. My Bookings History Modal Sheet
  void _showBookingsHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Bookings History',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1C1C),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildBookingHistoryCard(
                    chefName: 'Chef Marco',
                    title: 'Tuscan Truffle Experience',
                    date: 'Oct 24, 2026 • 7:30 PM',
                    guests: 6,
                    price: '₺8,700.00',
                    status: 'Active Escrow',
                    statusColor: const Color(0xFF7B5800),
                  ),
                  const SizedBox(height: 16),
                  _buildBookingHistoryCard(
                    chefName: 'Chef Elena',
                    title: 'Grand Tasting (5-Course)',
                    date: 'Aug 12, 2026 • 8:00 PM',
                    guests: 4,
                    price: '₺5,800.00',
                    status: 'Completed',
                    statusColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildBookingHistoryCard(
                    chefName: 'Marcus T.',
                    title: 'Botanical Craft Cocktails',
                    date: 'Jul 04, 2026 • 9:00 PM',
                    guests: 8,
                    price: '₺3,200.00',
                    status: 'Completed',
                    statusColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHistoryCard({
    required String chefName,
    required String title,
    required String date,
    required int guests,
    required String price,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  chefName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878))),
          Text('$date • $guests Guests', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800))),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Download Receipt', style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF1B1C1C))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Wallet & Escrow Balance Modal Sheet
  void _showWalletEscrowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GastroWallet & Escrow',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1C1C),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1C1C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available GastroWallet Balance', style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    '₺1,450.00',
                    style: GoogleFonts.libreCaslonText(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF7B5800), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '100% Escrow Protection Active for current bookings',
                        style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF7B5800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Recent Transactions', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildTransactionTile('Escrow Hold: Chef Marco Event', 'Oct 20, 2026', '-₺8,700.00', isDebit: true),
                  _buildTransactionTile('GastroPoints Cashback', 'Oct 15, 2026', '+₺450.00', isDebit: false),
                  _buildTransactionTile('Credit Card Top-Up', 'Sep 01, 2026', '+₺1,000.00', isDebit: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(String title, String date, String amount, {required bool isDebit}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isDebit ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
        child: Icon(
          isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: isDebit ? Colors.red : const Color(0xFF10B981),
          size: 18,
        ),
      ),
      title: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(date, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
      trailing: Text(
        amount,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDebit ? Colors.red : const Color(0xFF10B981),
        ),
      ),
    );
  }

  // 3. Saved Locations & Venues Sheet
  void _showSavedLocationsSheet(BuildContext context, String currentLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Venues & Kitchens',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B1C1C),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildVenueCard(
                    name: 'Kadıköy Apartment (Primary Home)',
                    address: 'Fenerbahçe Mah. Kadıköy, İstanbul',
                    specs: ['4-Burner Gas Stove', 'Convection Oven', 'Dishwasher'],
                    isDefault: currentLocation.contains('Kadıköy'),
                  ),
                  const SizedBox(height: 14),
                  _buildVenueCard(
                    name: 'Bodrum Summer Villa',
                    address: 'Gündoğan Mah. Bodrum, Muğla',
                    specs: ['Induction Cooktop', 'Outdoor BBQ Grill', 'Wine Cooler'],
                    isDefault: currentLocation.contains('Bodrum'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard({
    required String name,
    required String address,
    required List<String> specs,
    required bool isDefault,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDefault ? const Color(0xFF7B5800) : const Color(0xFFE4E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B5800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Active GPS', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(address, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: specs.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEDED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(s, style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF1B1C1C))),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // 4. Chef Application Modal Sheet
  void _showChefApplicationSheet(BuildContext context) {
    bool isSubmitting = false;
    String selectedDocType = 'identity';
    String uploadUrl = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Apply to Become a Chef',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1C),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Join our premium community of private chefs and mixologists. Upload your credentials for verification.',
                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                ),
                const SizedBox(height: 24),
                Text('DOCUMENT TYPE', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF747878))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedDocType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'identity', child: Text('Identity Document (ID Card / Passport)')),
                    DropdownMenuItem(value: 'hygiene_cert', child: Text('Hygiene & Sanitation Certificate')),
                    DropdownMenuItem(value: 'diploma', child: Text('Gastronomy Diploma / Professional Cert')),
                    DropdownMenuItem(value: 'portfolio', child: Text('Menu / Plate Portfolio Link')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (val != null) selectedDocType = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text('DOCUMENT LINK / FILE', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF747878))),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter file URL or document link',
                  ),
                  onChanged: (val) {
                    uploadUrl = val;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (uploadUrl.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a document URL'), backgroundColor: Colors.redAccent),
                        );
                        return;
                      }
                      setState(() => isSubmitting = true);
                            try {
                              final supabaseService = SupabaseService();
                              final response = await supabaseService.client
                                  .from('provider_profiles')
                                  .select('id')
                                  .eq('user_id', supabaseService.currentUser?.id ?? '')
                                  .maybeSingle();

                              if (response != null) {
                                final providerId = response['id'] as String;
                                await supabaseService.addProviderDocument(
                                  providerId: providerId,
                                  documentType: selectedDocType,
                                  fileUrl: uploadUrl,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Application document submitted successfully! Admin will review it.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                throw Exception('Provider profile not found. Please verify your role is Chef.');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            } finally {
                              setState(() => isSubmitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Submit Application', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: onBack,
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          if (userProfile.isVerifiedChef)
            IconButton(
              onPressed: onSwitchToChef,
              icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF7B5800)),
              tooltip: 'Switch to Chef Mode',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Header Profile Card
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF7B5800).withValues(alpha: 0.1),
                            child: Text(
                              userProfile.initials,
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7B5800),
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
                                    Text(
                                      userProfile.name,
                                      style: GoogleFonts.libreCaslonText(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1B1C1C),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFEDED),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'VIP Gourmet',
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF7B5800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userProfile.email,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF747878),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Color(0xFF7B5800), size: 13),
                                    const SizedBox(width: 2),
                                    Text(
                                      userProfile.location,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1B1C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE4E2E2)),
                      const SizedBox(height: 12),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('12', 'Events Hosted'),
                          _buildStatItem('8', 'Saved Chefs'),
                          _buildStatItem('1.450', 'GastroPoints', isGold: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Culinary & Allergy Passport
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
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF7B5800), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Culinary & Allergy Passport',
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B1C1C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shared automatically with booking chefs for customized preparation.',
                        style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878)),
                      ),
                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge('Gluten-Free Option'),
                          _buildBadge('No Shellfish'),
                          _buildBadge('Italian Fine Dining', isPrimary: true),
                          _buildBadge('4-Burner Stove'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Quick Options Section (Connected to Sub-Screen Modals)
              Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE4E2E2)),
                ),
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.history_rounded,
                      title: 'My Bookings History',
                      onTap: () => _showBookingsHistorySheet(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E2E2)),
                    _buildOptionTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet & Escrow Balance (₺1,450.00)',
                      onTap: () => _showWalletEscrowSheet(context),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E2E2)),
                    _buildOptionTile(
                      icon: Icons.location_on_outlined,
                      title: 'Saved Location (${userProfile.location})',
                      onTap: () => _showSavedLocationsSheet(context, userProfile.location),
                    ),
                    const Divider(height: 1, color: Color(0xFFE4E2E2)),
                    if (userProfile.isVerifiedChef) ...[
                      _buildOptionTile(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Switch to Chef Dashboard',
                        onTap: onSwitchToChef,
                      ),
                      const Divider(height: 1, color: Color(0xFFE4E2E2)),
                      _buildOptionTile(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'Menülerim ve Paketlerim (Manage Menus)',
                        onTap: () {
                          if (onManageMenus != null) {
                            onManageMenus!();
                          } else {
                            onSwitchToChef();
                          }
                        },
                      ),
                    ]
                    else
                      _buildOptionTile(
                        icon: Icons.edit_note_rounded,
                        title: 'Başvuruyu İncele & Düzenle (Şef / Barmen Kaydı)',
                        onTap: () {
                          if (onStartChefOnboarding != null) {
                            onStartChefOnboarding!();
                          } else {
                            _showChefApplicationSheet(context);
                          }
                        },
                      ),
                    const Divider(height: 1, color: Color(0xFFE4E2E2)),
                    _buildOptionTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Belge Onay Simülasyonu (Test)',
                      onTap: () {
                        if (onOpenAdminSimulator != null) {
                          onOpenAdminSimulator!();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  label: Text(
                    'Log Out',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String label, {bool isGold = false}) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isGold ? const Color(0xFF7B5800) : const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: const Color(0xFF747878),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF7B5800).withValues(alpha: 0.1) : const Color(0xFFEFEDED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFF7B5800) : const Color(0xFFE4E2E2),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          color: isPrimary ? const Color(0xFF7B5800) : const Color(0xFF1B1C1C),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF1B1C1C), size: 22),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1B1C1C),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF747878)),
    );
  }
}
