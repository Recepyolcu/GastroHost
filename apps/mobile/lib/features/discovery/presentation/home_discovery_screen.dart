import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/user_location_service.dart';

class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> provider, Map<String, dynamic> menu) onSelectMenu;
  final VoidCallback onTapProfile;
  final VoidCallback? onTapBookings;
  final VoidCallback? onTapMessages;

  const HomeDiscoveryScreen({
    super.key,
    required this.onSelectMenu,
    required this.onTapProfile,
    this.onTapBookings,
    this.onTapMessages,
  });

  @override
  ConsumerState<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends ConsumerState<HomeDiscoveryScreen> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Private Chefs',
    'Mixologists',
    'Waitstaff',
    'Sommelier',
  ];

  final List<Map<String, dynamic>> _recommendedChefs = [
    {
      'id': 'p1',
      'name': 'Chef Julian',
      'price': '₺2.250/kişi',
      'rating': '4.9',
      'distance_km': '1.8 km',
      'description': 'Master of contemporary French cuisine with global influences.',
      'tags': ['French', 'Fine Dining'],
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBZ39tPphYle75Gmb_6AjN9N3Z-66K_iukAW9tqVL7Gvj-M1QjUM5jbY0VtG4Qb2FKmM8YyL6sAdcl9tDWO0IbmiUezB7Q2u4DngEr_sjhOQKmL6MN0XgCF4uRygDK_xMQKt29dslAEAK2j3xcT543wQZ_dDD9oc7hYygS9QN2KC9WxaeYEUk9zCJXaB5Lov9WCtRpFlaFSEs0-YpngYnmp4cKFYZ04BdJLAatycv9bs_LAbzWprbbq',
    },
    {
      'id': 'p2',
      'name': 'Chef Elena',
      'price': '₺1.850/kişi',
      'rating': '4.8',
      'distance_km': '3.2 km',
      'description': 'Authentic Italian heritage meets modern culinary techniques.',
      'tags': ['Italian', 'Rustic'],
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuChn-7FZZhW2-A3ZcBIy-XJfS_u32bim9mUqpimzSY-VOLTfHcAealsuuCTWRH7Tx_BbBSRdyc6rpO8HEUYTUHikNx-biLNWFDtXWR66fAhyO6V1JDFk_GmH3l274X67WAEXc2uzZkvqZ_yig1YVI6ZaUqCioJwLQN1hDUqWTPzV212eSPclZ2cZHGDCpjQLl23vkuvC3duxxx4y8_BXCHS5aKRO-e2AbBgjQQhINV-omXI5c8N1Mbz',
    },
  ];

  final List<Map<String, dynamic>> _topMixologists = [
    {
      'id': 'm1',
      'name': 'Marcus T.',
      'price': '₺850/saat',
      'rating': '4.9',
      'distance_km': '2.1 km',
      'tag': 'Craft Cocktails',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDaVyI-CnIxT8YodSe6yue9G2LBJOi4QhgNlNMPJnjuAr-94xAgbuWyK3sO69pqU0pZHXmZX3vx0-EvNW9DOg84ESyCgW7FSvqZDa2zT8N4D6ipCIfxDraqPiYrQDxbGldcRLyepDXtlsaxJ4xaUgVwlylXd6xBYGqGQPijq1y7LRa8dlusjK03lBDWKMLyvPIZ1WzmLyhaoq4u5QlrvOJ1Do_iiFI3x3_Tyzf3RZvv4ClF9Vfr6xTh',
    },
    {
      'id': 'm2',
      'name': 'Sarah W.',
      'price': '₺750/saat',
      'rating': '4.8',
      'distance_km': '4.5 km',
      'tag': 'Botanical',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBtbnFtqWZqebz3aN6uXggy_L92XIqGpYBbUwJXpBl5iR7wMp8iQoVuhbdHKaDSAlgm74p4NFY_b7XSgAoOfC0k3MnqyQjE_Mk9KnlNYzz91w-ekMJ3n6pa3BmcB_FqEwCQjnOt7H7iaydg1DS2tUH6rhgh4mduKjJPxN_SgVwyHOtAt15ibC97srEOcwj2_Uqv4ckKMpAlEZ8QoGs4xrqljiXo_TrRIv_62z5EvnNPPc4bDZX7xqEQ',
    },
  ];





  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GPS Location Header Bar (Automatic Device Location)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => ref.read(userProfileProvider.notifier).refreshDeviceLocation(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 6),
                          if (userProfile.isLoadingLocation) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Konum Alınıyor (GPS)...',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ] else ...[
                            Text(
                              userProfile.location,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B1C1C),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.refresh_rounded, color: Color(0xFF10B981), size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded, color: Colors.black, size: 22),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Category Horizontal Scroll
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategoryIndex = index),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF000000) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? Colors.black : const Color(0xFFE4E2E2),
                          ),
                        ),
                        child: Text(
                          _categories[index],
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF1B1C1C),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Hero Card (Elevate Your Home Dining)
              Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDrWm9_kH_wWY63k9nHgX6YfxUXxi0uKRMrD22f-unKkAaqP-9Fb81T7f3QXF91nfQShUZjHbOSx4Jy1g_BOzVLsW-0-Ykh6Z3ZWXpcmV-1LPK6yDqQvAh6tX4PhPryF6G4_a8do59HQcSIiFWva55p-6I6U-9cmfVa7l6h3vJ747MMGJ7F-sWBQTCS2-eIDhCW8LI6B84NhfxiVvZ2cbgGZ5GIVk3bd1tQrAfp3oNJvBPnJS6uA9Pw',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elevate Your Home Dining',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover bespoke culinary experiences curated by top professionals for your private events in ${userProfile.location}.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.90),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Explore Experiences',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4. Recommended Chefs Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended Chefs for You',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B1C1C),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'See all',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B5800),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF7B5800)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recommended Chef Cards
              ..._recommendedChefs.map((chef) => _buildChefCard(chef)),

              const SizedBox(height: 24),

              // 5. Top Rated Mixologists Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Rated Mixologists',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B1C1C),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'See all',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B5800),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF7B5800)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Top Rated Mixologist Cards
              ..._topMixologists.map((mix) => _buildMixologistCard(mix)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Chef Card Widget
  Widget _buildChefCard(Map<String, dynamic> chef) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  chef['image'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Distance Proximity Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        chef['distance_km'] ?? '2.4 km',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFF7B5800), size: 14),
                      const SizedBox(width: 2),
                      Text(
                        chef['rating'],
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),


          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      chef['name'],
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1C),
                      ),
                    ),
                    Text(
                      chef['price'],
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7B5800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  chef['description'],
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF747878),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: (chef['tags'] as List<String>).map((t) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE4E2E2)),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: const Color(0xFF747878),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onSelectMenu({
                      'id': chef['id'],
                      'name': chef['name'],
                      'image': chef['image'],
                      'price_per_person': 150.0,
                    }, {
                      'id': 'm_${chef['id']}',
                      'title': chef['description'],
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE4E2E2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View Menu',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1C),
                      ),
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

  Widget _buildMixologistCard(Map<String, dynamic> mix) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              mix['image'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mix['name'],
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1C),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF7B5800), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          mix['rating'],
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B1C1C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE4E2E2)),
                  ),
                  child: Text(
                    mix['tag'],
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: const Color(0xFF747878),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mix['price'],
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7B5800),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        widget.onSelectMenu({
                          'id': mix['id'],
                          'name': mix['name'],
                          'price': mix['price'],
                          'rating': mix['rating'],
                          'image': mix['image'],
                          'provider_type': 'bartender',
                        }, {
                          'id': 'menu_${mix['id']}',
                          'title': '${mix['name']} - Signature Cocktails',
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: Color(0xFFE4E2E2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Book',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B1C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
