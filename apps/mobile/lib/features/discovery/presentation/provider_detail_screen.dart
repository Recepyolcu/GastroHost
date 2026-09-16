import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProviderDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> provider;
  final VoidCallback onStartBooking;
  final VoidCallback? onBack;

  const ProviderDetailScreen({
    super.key,
    required this.provider,
    required this.onStartBooking,
    this.onBack,
  });

  @override
  ConsumerState<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends ConsumerState<ProviderDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _chefGalleryImages = [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAJZXVqfkv9fKvZCsdUi2Bxr3s9CwyTufeVB_W3PS6Id7OqaVmo1JMvMObyDjU7yGhnPoVaLEjSVS62E-5kzbB-zUyeiI1HF8yXGIuCVYZoFp7q0ihfiTsOOrZp8OQWUPGPXBttxV6-DAXw7my_uRLLNEFhdYo5SvhSMZcNrKks3XM90ynbeLnO0EcJxI1bzsx11Kc7Pw0dMKEwqLydHYNj6IqbgabtKiWhXrSgI4GitVdzD2XlHIn5',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA3tJ1a_HwsIPZ3OIOg53YlnNaOgnZbOIQDksiDGQytuEMxpXV9Iaa2QpYzVPIFzb6M4QbWeO4P6Ezl6rZ1iar_HuQOBd1teSmtFvfYg8Bj14vL4W2lMxuTyWwYE2_y8OTYv19vvapgPNXKSbhEomgx3VOuLLJq3lyxbtiHjpbr2EMJNGWpJr-KhA18lqwas4QJuvoAjbTmie9kAYsqEW9x_lVfi8sQAtdqqWNstwAoacUS1Glm40-B',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuA-fnda7XWWcWuDjkkOWdlGdaAAQ0IURxCaYNPIjDKLu0VSPPJoKY28q4moezLVZmjh5Sko_ivXcEfJqp8qAgcMYQHxEHi4hEx0Et7uHbW2ubo-4EOc7nV8MBXUV8l88nMnVmWsueXpuX_5WDm0Ai34nLIdlTI30HZ8GMlgob3iWOUoTgkchlwawb05_RFKrt6Xr6L1F-p7eWhdrLkRnHgPw6FaPssHk7Dm9cOK1JYi8sf61tQEqLfM',
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1546964124-0cce460f38ef?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800&auto=format&fit=crop&q=80',
  ];

  final List<String> _mixologistGalleryImages = [
    'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1536935338788-846bb9981813?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1574096079513-d8259312b785?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1541546006121-5c3bc5e8c7b9?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1595981267035-7b04ca84a82d?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1560512823-829485b8bf24?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1546171753-97d7676e4602?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800&auto=format&fit=crop&q=80',
  ];

  List<String> get _galleryImages => isMixologist ? _mixologistGalleryImages : _chefGalleryImages;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get isMixologist =>
      widget.provider['provider_type'] == 'bartender' ||
      (widget.provider['price']?.toString().contains('/hr') ?? false) ||
      (widget.provider['id']?.toString().startsWith('m') ?? false);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);

    final provider = widget.provider;
    final String name = provider['name'] ?? (isMixologist ? 'Marcus T.' : 'Chef Marco');
    final String rating = (provider['rating'] ?? '4.8').toString();

    return Scaffold(
      backgroundColor: palette.bg,
      bottomNavigationBar: _buildBottomActionBar(palette, isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar (Back & Share)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    icon: Icon(Icons.arrow_back_rounded, color: palette.textPrimary),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.surfaceElevated,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.ios_share_rounded, color: palette.textPrimary),
                    style: IconButton.styleFrom(
                      backgroundColor: palette.surfaceElevated,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Photo Gallery Carousel
                    SizedBox(
                      height: 280,
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: _galleryImages.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                _galleryImages[index],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _showAllPhotosModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: palette.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: palette.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.grid_view_rounded, size: 14, color: palette.textPrimary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Show all ${_galleryImages.length} photos',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Chef Header & Info
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.libreCaslonText(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.star_rounded, color: palette.goldAccent, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        rating,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(124 reviews)',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: palette.goldGlow,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: palette.goldAccent.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.verified_rounded, color: palette.goldAccent, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Verified',
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
                                ],
                              ),

                              // Avatar Photo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  provider['image'] ??
                                      provider['avatar'] ??
                                      (isMixologist
                                          ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuDaVyI-CnIxT8YodSe6yue9G2LBJOi4QhgNlNMPJnjuAr-94xAgbuWyK3sO69pqU0pZHXmZX3vx0-EvNW9DOg84ESyCgW7FSvqZDa2zT8N4D6ipCIfxDraqPiYrQDxbGldcRLyepDXtlsaxJ4xaUgVwlylXd6xBYGqGQPijq1y7LRa8dlusjK03lBDWKMLyvPIZ1WzmLyhaoq4u5QlrvOJ1Do_iiFI3x3_Tyzf3RZvv4ClF9Vfr6xTh'
                                          : 'https://lh3.googleusercontent.com/aida-public/AB6AXuCONoMmOXp0IjymBppcR4QkB6xr80XfagXEBCa0yI1Zt4NWfpJb6dPtzzSmAeUJCZ0UEdd9SEP-anJt2rq_REq4HHH3-K8902WrCKTp-oJluokeNMEJ8w5jKPmGBUZtB0bF9sTCTsBrvbCy2HVMAgcS2n4DSFhUG_gDEO1kbjiiDRKcw16uXYIwjsQE1rioTL1bVJW-635g42PTmwpQTKvuOc7jB-TrTegTDa_K8FhG5mF0rMFZXsHr'),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(color: palette.border),
                          const SizedBox(height: 16),

                          // About Section
                          Text(
                            isMixologist ? 'About the Mixologist' : 'About the Chef',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isMixologist
                                ? 'Award-winning mixologist specializing in bespoke craft cocktail menus, botanical infusions, and luxury private bar service. Brings complete portable bar setup and premium presentation to your event.'
                                : 'Italian Michelin-star background, specializing in truffle pasta and contemporary Mediterranean cuisine. Chef Marco brings the warmth of a rustic Italian kitchen combined with the precision of high-end gastronomy directly to your dining room.',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: palette.textMuted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tag Pills
                          Row(
                            children: isMixologist
                                ? [
                                    _buildTagPill('Craft Cocktails', palette),
                                    _buildTagPill('Botanical', palette),
                                    _buildTagPill('Bar Master', palette),
                                  ]
                                : [
                                    _buildTagPill('Italian', palette),
                                    _buildTagPill('Fine Dining', palette),
                                    _buildTagPill('Pasta Expert', palette),
                                  ],
                          ),
                          const SizedBox(height: 20),
                          Divider(color: palette.border),
                          const SizedBox(height: 16),

                          // Tabs Selector
                          TabBar(
                            controller: _tabController,
                            indicatorColor: palette.goldAccent,
                            labelColor: palette.goldAccent,
                            unselectedLabelColor: palette.textMuted,
                            labelStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                            tabs: [
                              Tab(text: isMixologist ? 'Cocktail Packages' : 'Menus'),
                              const Tab(text: 'Requirements'),
                              const Tab(text: 'Reviews'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Tab Views
                          SizedBox(
                            height: 320,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Menus / Cocktail Packages Tab
                                Column(
                                  children: isMixologist
                                      ? [
                                          _buildMenuItem(
                                            title: 'Signature Craft Cocktail Bar (4 Saat)',
                                            subtitle: 'Customized menu of 4 signature cocktails, house-made syrups, and fresh botanical garnishes.',
                                            price: '₺850/saat',
                                            tag: 'En Popüler',
                                            palette: palette,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildMenuItem(
                                            title: 'Classic & Vintage Tasting (3 Saat)',
                                            subtitle: 'Curated tasting of prohibition-era classics and elevated twists.',
                                            price: '₺750/saat',
                                            palette: palette,
                                            isDark: isDark,
                                          ),
                                        ]
                                      : [
                                          _buildMenuItem(
                                            title: 'The Truffle Experience (3 Aşamalı)',
                                            subtitle: 'A curated journey through Northern Italy focusing on seasonal truffles.',
                                            price: '₺1.850/kişi',
                                            tag: 'En Popüler',
                                            palette: palette,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildMenuItem(
                                            title: 'Grand Tasting (5 Aşamalı)',
                                            subtitle: 'An expansive culinary exploration including seafood, pasta, and premium wagyu.',
                                            price: '₺2.450/kişi',
                                            palette: palette,
                                            isDark: isDark,
                                          ),
                                        ],
                                ),

                                // Requirements Tab
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: isMixologist
                                      ? [
                                          Text(
                                            'Bar & Service Requirements',
                                            style: GoogleFonts.manrope(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildRequirementItem('Clean bar or countertop space', palette),
                                          _buildRequirementItem('Glassware provided by host (or request addon)', palette),
                                          _buildRequirementItem('Ice & cooler access', palette),
                                        ]
                                      : [
                                          Text(
                                            'Kitchen Requirements',
                                            style: GoogleFonts.manrope(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildRequirementItem('Needs 4-burner stove', palette),
                                          _buildRequirementItem('Working oven', palette),
                                          _buildRequirementItem('Blender or food processor', palette),
                                        ],
                                ),

                                // Reviews Tab
                                Center(
                                  child: Text(
                                    '124 Verified Reviews (4.8 ★)',
                                    style: GoogleFonts.manrope(color: palette.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill(String label, AppThemePalette palette) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: palette.textPrimary,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required String price,
    required AppThemePalette palette,
    required bool isDark,
    String? tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: palette.textMuted,
                    height: 1.3,
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: palette.goldAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.goldAccent,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: widget.onStartBooking,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: palette.goldAccent),
                  backgroundColor: isDark ? palette.surfaceElevated : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                ),
                child: Text(
                  'View Menu',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.goldAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, AppThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: palette.goldAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(fontSize: 14, color: palette.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMixologist ? '₺850\'den başlayan' : '₺1.850\'den başlayan',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                isMixologist ? 'saatlik ücret' : 'kişi başı',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: palette.textMuted,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: widget.onStartBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? palette.goldAccent : Colors.black,
              foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              'Book Now',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllPhotosModal() {
    final settings = ref.read(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Photos (${_galleryImages.length})',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: palette.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(color: palette.border),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _galleryImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullscreenImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _galleryImages[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: palette.surfaceElevated,
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: palette.goldAccent,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFullscreenImage(int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: _galleryImages.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (index) {
                      setDialogState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        child: Center(
                          child: Image.network(
                            _galleryImages[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  // Close Button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Image Counter Indicator
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${_galleryImages.length}',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
