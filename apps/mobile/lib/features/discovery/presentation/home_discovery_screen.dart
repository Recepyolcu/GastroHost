import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/theme/app_theme.dart';

class HomeDiscoveryScreen extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> provider, Map<String, dynamic> menu)
      onSelectMenu;
  final VoidCallback onTapProfile;
  final VoidCallback? onTapBookings;
  final VoidCallback? onTapMessages;

  final Function(Map<String, dynamic> provider)? onTapChefProfile;

  const HomeDiscoveryScreen({
    super.key,
    required this.onSelectMenu,
    required this.onTapProfile,
    this.onTapBookings,
    this.onTapMessages,
    this.onTapChefProfile,
  });

  @override
  ConsumerState<HomeDiscoveryScreen> createState() =>
      _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends ConsumerState<HomeDiscoveryScreen> {
  // 0: Tümü (Vitrin), 1: Özel Şef, 2: Miksolojist, 3: Şef + Barmen Kombine
  int _selectedCategoryIndex = 0;
  String _selectedSubSpecialty = 'Tümü';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Selected pair for Mode 3 (Combined Chef + Mixologist Experience)
  int _selectedPairedChefIdx = 0;
  int _selectedPairedMixIdx = 0;

  static const Color _mixologistPurple = Color(0xFF9333EA);
  static const Color _mixologistLilac = Color(0xFFC084FC);

  List<Map<String, dynamic>> _recommendedChefs = [
    {
      'id': '22222222-3333-4444-8555-666666660001',
      'provider_type': 'chef',
      'name': 'Chef Julian Vance',
      'title': 'Executive Michelin Fine Dining Şefi',
      'price': '₺2.150/kişi',
      'unit_price': 2150.0,
      'rating': '4.9',
      'distance_km': '0.4 km',
      'description':
          'Milano ve Paris\'te 12 yıllık Michelin yıldızlı restoran deneyiminin ardından İstanbul\'da özel davetler için beyaz eldiven tadım menüleri sunuyor.',
      'tags': ['İtalyan Fine Dining', 'Fransız Gastronomi'],
      'verified_hygiene': true,
      'verified_diploma': true,
      'image':
          'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': 'e0816dbb-dda7-4bda-aef6-dd02eab1bb4a',
      'provider_type': 'chef',
      'name': 'Şef Recep Özkan',
      'title': 'Modern Anadolu & Dry-Age Uzmanı',
      'price': '₺1.650/kişi',
      'unit_price': 1650.0,
      'rating': '5.0',
      'distance_km': '4.8 km',
      'description':
          'Ege ve Akdeniz mutfağının mevsimsel deniz ürünlerini ve dry-age etlerini Michelin standartlarında sunuyor.',
      'tags': ['Ege/Akdeniz', 'Dry-Age Et'],
      'verified_hygiene': true,
      'verified_diploma': true,
      'image':
          'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': '22222222-3333-4444-8555-666666660002',
      'provider_type': 'chef',
      'name': 'Chef Elena Rostova',
      'title': 'Omakase & Nikkei Gastronomi Şefi',
      'price': '₺2.400/kişi',
      'unit_price': 2400.0,
      'rating': '4.9',
      'distance_km': '9.5 km',
      'description':
          'Tokyo ve Londra\'daki Nikkei mutfaklarından ilham alan 8 aşamalı Omakase suşi ve Wagyu tadım menüleri.',
      'tags': ['Japon & Omakase', 'Asya Füzyon'],
      'verified_hygiene': true,
      'verified_diploma': true,
      'image':
          'https://images.unsplash.com/photo-1595273670150-bd0c3c392e46?w=800&auto=format&fit=crop&q=80',
    },
  ];

  List<Map<String, dynamic>> _topMixologists = [
    {
      'id': '22222222-3333-4444-8555-666666660003',
      'provider_type': 'bartender',
      'name': 'Marcus Thorne',
      'title': 'Master Miksolojist & Moleküler Bar Tasarımcısı',
      'price': '₺950/saat',
      'unit_price': 950.0,
      'rating': '5.0',
      'distance_km': '7.8 km',
      'tag': 'Moleküler Miksoloji',
      'tags': ['Moleküler Miksoloji', 'İmza Kokteyller', 'Mobil Bar Dahil'],
      'verified_hygiene': true,
      'verified_diploma': true,
      'description':
          'Taşınabilir mobil bar istasyonu, el kesimi kristal buzlar, tütsü aromaları ve botanik infüzyonlarla imza kokteyl deneyimi.',
      'image':
          'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800&auto=format&fit=crop&q=80',
    },
    {
      'id': '22222222-3333-4444-8555-666666660004',
      'provider_type': 'bartender',
      'name': 'Sarah Jenkins',
      'title': 'WSET Level 3 Sommelier & Botanik Miksolojist',
      'price': '₺850/saat',
      'unit_price': 850.0,
      'rating': '4.9',
      'distance_km': '3.8 km',
      'tag': 'Botanik Cin & Sommelier',
      'tags': ['Botanik Cin & Sommelier', 'Akdeniz Aperitivo', 'Kristal Cam Servis'],
      'verified_hygiene': true,
      'verified_diploma': true,
      'description':
          'WSET Level 3 sertifikalı sommelier ve miksolojist. Taze Akdeniz otları, ev yapımı şuruplar ve fine-dining kokteyl eşleşmeleri.',
      'image':
          'https://images.unsplash.com/photo-1574096079513-d8259312b785?w=800&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveProvidersFromSupabase();
  }

  Future<void> _loadLiveProvidersFromSupabase() async {
    try {
      final locationState = ref.read(userProfileProvider);
      double lat = locationState.latitude;
      double lng = locationState.longitude;
      if (lat < 35.0 || lat > 43.0 || lng < 25.0 || lng > 45.0) {
        lat = 40.9833;
        lng = 29.0254;
      }

      final allProviders = await SupabaseService().getDiscoveryProviders(
        latitude: lat,
        longitude: lng,
      );

      if (!mounted || allProviders.isEmpty) return;

      final chefs = allProviders
          .where((p) =>
              p['provider_type'] == 'chef' || p['provider_type'] == 'both')
          .toList();
      final bartenders = allProviders
          .where((p) =>
              p['provider_type'] == 'bartender' || p['provider_type'] == 'both')
          .toList();

      setState(() {
        if (chefs.isNotEmpty) _recommendedChefs = chefs;
        if (bartenders.isNotEmpty) _topMixologists = bartenders;
      });
    } catch (e) {
      debugPrint('HomeDiscovery live fetch error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getSubSpecialtiesForMode() {
    if (_selectedCategoryIndex == 1) {
      return [
        'Tümü',
        'İtalyan',
        'Ege/Akdeniz',
        'Japon & Omakase',
        'Dry-Age Et',
        'Fransız',
      ];
    } else if (_selectedCategoryIndex == 2) {
      return [
        'Tümü',
        'Moleküler Miksoloji',
        'İmza Kokteyller',
        'Botanik Cin',
        'Sommelier',
        'Aperitivo',
      ];
    }
    return [
      'Tümü',
      'İtalyan',
      'Ege/Akdeniz',
      'Japon & Omakase',
      'Moleküler Miksoloji',
      'İmza Kokteyller',
      'Botanik Cin',
    ];
  }

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    return list.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final desc = (item['description'] ?? '').toString().toLowerCase();
      final tag = (item['tag'] ?? '').toString().toLowerCase();
      final tagsList =
          (item['tags'] as List?)?.map((e) => e.toString()).join(' ').toLowerCase() ?? '';
      final combined = '$name $desc $tag $tagsList';

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        if (!combined.contains(q)) return false;
      }

      if (_selectedSubSpecialty != 'Tümü') {
        final subQ = _selectedSubSpecialty.toLowerCase();
        if (!combined.contains(subQ)) return false;
      }

      return true;
    }).toList();
  }

  void _handleSelectMenu(
      Map<String, dynamic> provider, Map<String, dynamic> menu) {
    widget.onSelectMenu(provider, menu);
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final settings = ref.watch(appSettingsProvider);
    final bookingState = ref.watch(bookingProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);

    final showChefs = _selectedCategoryIndex == 0 ||
        _selectedCategoryIndex == 1 ||
        _selectedCategoryIndex == 3;
    final showMixologists = _selectedCategoryIndex == 0 ||
        _selectedCategoryIndex == 2 ||
        _selectedCategoryIndex == 3;

    final filteredChefs = _filterList(_recommendedChefs);
    final filteredMixologists = _filterList(_topMixologists);
    final hasActiveSearch =
        _searchQuery.trim().isNotEmpty || _selectedSubSpecialty != 'Tümü';
    final hasNoResults = hasActiveSearch &&
        ((showChefs && filteredChefs.isEmpty) &&
            (showMixologists && filteredMixologists.isEmpty));

    final subSpecialties = _getSubSpecialtiesForMode();

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GPS Location Header Bar & Search Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () => ref
                          .read(userProfileProvider.notifier)
                          .refreshDeviceLocation(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: palette.emeraldGlow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? palette.emerald.withValues(alpha: 0.45)
                                : palette.emerald.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location_rounded,
                                color: palette.emerald, size: 18),
                            const SizedBox(width: 6),
                            if (userProfile.isLoadingLocation) ...[
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: palette.emerald),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Konum Alınıyor...',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: palette.emerald,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else ...[
                              Flexible(
                                child: Text(
                                  userProfile.location,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.refresh_rounded,
                                  color: palette.emerald, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearchOpen = !_isSearchOpen;
                        if (!_isSearchOpen) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    icon: Icon(
                      _isSearchOpen
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: _isSearchOpen
                          ? palette.goldAccent
                          : palette.textPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),

              // Search Input Bar (Shown when search button is tapped)
              if (_isSearchOpen) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? palette.goldAccent.withValues(alpha: 0.5)
                          : palette.goldAccent,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Şef, miksolojist, kokteyl veya mutfak ara...',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 13,
                        color: palette.textMuted,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: palette.goldAccent, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: palette.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Active Booking Status Reminder Banner
              if (bookingState.hasActiveBooking &&
                  bookingState.currentActiveBooking != null) ...[
                _buildActiveBookingBanner(
                    bookingState.currentActiveBooking!, palette, isDark),
                const SizedBox(height: 16),
              ],

              // 2. Equal-Hierarchy Experience Mode Switcher (Tümü / Özel Şef / Miksolojist / Kombine)
              _buildExperienceModeSwitcher(palette, isDark),
              const SizedBox(height: 12),

              // 2.5 Sub-Specialty Filter Pills
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: subSpecialties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = subSpecialties[idx];
                    final isSelected = _selectedSubSpecialty == item;
                    final isMixMode = _selectedCategoryIndex == 2;
                    final activeColor = isMixMode
                        ? (isDark ? _mixologistLilac : _mixologistPurple)
                        : (isDark ? palette.goldAccent : Colors.black);

                    return InkWell(
                      onTap: () => setState(() => _selectedSubSpecialty = item),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: isDark ? 0.2 : 0.12)
                              : palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? activeColor : palette.borderSubtle,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? activeColor : palette.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // 3. Dynamic Mode Hero Banner (Adapts to Tümü, Özel Şef, Miksolojist, or Kombine)
              if (_searchQuery.trim().isEmpty) ...[
                _buildDynamicHeroSection(
                    userProfile.location, palette, isDark),
                const SizedBox(height: 24),
              ],

              // Empty Search Results State
              if (hasNoResults) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 40, color: palette.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'Seçili kriterlere uygun uzman bulunamadı',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Farklı bir uzmanlık etiketi veya arama terimi deneyebilirsiniz.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: palette.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedSubSpecialty = 'Tümü';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: Text(
                          'Filtreleri Temizle',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 4. Chefs Section (Full Showcase Cards)
              if (showChefs && filteredChefs.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.restaurant_menu_rounded,
                  accentColor: palette.goldAccent,
                  title: _selectedCategoryIndex == 1
                      ? 'Özel Şefler & Tadım Menüleri'
                      : 'Öne Çıkan Özel Şefler',
                  subtitle:
                      'Alışveriş, hazırlık, fine-dining sunum ve mutfak temizliği dahil',
                  showAllAction: _selectedCategoryIndex == 0 && !hasActiveSearch,
                  onTapShowAll: () => setState(() {
                    _selectedCategoryIndex = 1;
                    _selectedSubSpecialty = 'Tümü';
                  }),
                  palette: palette,
                ),
                const SizedBox(height: 14),
                ...filteredChefs.map((chef) => _buildProviderShowcaseCard(
                      provider: chef,
                      isBartender: false,
                      palette: palette,
                      isDark: isDark,
                    )),
                const SizedBox(height: 12),
              ],

              // 5. Mixologists Section (Equal Full Showcase Cards!)
              if (showMixologists && filteredMixologists.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.local_bar_rounded,
                  accentColor: isDark ? _mixologistLilac : _mixologistPurple,
                  title: _selectedCategoryIndex == 2
                      ? 'Master Miksolojistler & Mobil Bar'
                      : 'Öne Çıkan Miksolojistler & Kokteyl Barı',
                  subtitle:
                      'Taşınabilir bar istasyonu, kristal camlar, özel buz ve imza kokteyller',
                  showAllAction: _selectedCategoryIndex == 0 && !hasActiveSearch,
                  onTapShowAll: () => setState(() {
                    _selectedCategoryIndex = 2;
                    _selectedSubSpecialty = 'Tümü';
                  }),
                  palette: palette,
                ),
                const SizedBox(height: 14),
                ...filteredMixologists.map((mix) => _buildProviderShowcaseCard(
                      provider: mix,
                      isBartender: true,
                      palette: palette,
                      isDark: isDark,
                    )),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceModeSwitcher(AppThemePalette palette, bool isDark) {
    final modes = [
      {
        'index': 0,
        'label': 'Vitrin',
        'subtitle': '${_recommendedChefs.length + _topMixologists.length} Uzman',
        'icon': Icons.auto_awesome_rounded,
        'accent': palette.goldAccent,
      },
      {
        'index': 1,
        'label': 'Özel Şef',
        'subtitle': '${_recommendedChefs.length} Şef',
        'icon': Icons.restaurant_menu_rounded,
        'accent': palette.goldAccent,
      },
      {
        'index': 2,
        'label': 'Miksolojist',
        'subtitle': '${_topMixologists.length} Barmen',
        'icon': Icons.local_bar_rounded,
        'accent': isDark ? _mixologistLilac : _mixologistPurple,
      },
      {
        'index': 3,
        'label': 'Şef + Bar',
        'subtitle': 'Kombine',
        'icon': Icons.celebration_rounded,
        'accent': palette.emerald,
      },
    ];

    return Row(
      children: modes.map((mode) {
        final idx = mode['index'] as int;
        final isSelected = _selectedCategoryIndex == idx;
        final accent = mode['accent'] as Color;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < 3 ? 8.0 : 0.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = idx;
                  _selectedSubSpecialty = 'Tümü';
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: isDark ? 0.20 : 0.12)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? accent : palette.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode['icon'] as IconData,
                      size: 20,
                      color: isSelected ? accent : palette.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['label'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color:
                            isSelected ? palette.textPrimary : palette.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      mode['subtitle'] as String,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? accent : palette.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicHeroSection(
      String location, AppThemePalette palette, bool isDark) {
    // Mode 2: Mixologist Dedicated Hero
    if (_selectedCategoryIndex == 2) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _mixologistPurple.withValues(alpha: 0.5), width: 1.2),
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=900&auto=format&fit=crop&q=80',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF1A0B2E).withValues(alpha: 0.94),
                const Color(0xFF1A0B2E).withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.25),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _mixologistPurple.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_bar_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      'CRAFT COCKTAIL & MOBİL BAR',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Evinizde Nitelikli Kokteyl Barı & Miksoloji Deneyimi',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Taşınabilir bar ünitesi, kristal kadehler, el kesimi buzlar ve ev yapımı botanik infüzyonlarla davetinizi üst seviyeye taşıyın.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildHeroFeaturePill(
                      Icons.liquor_rounded, 'Mobil Bar İstasyonu'),
                  _buildHeroFeaturePill(
                      Icons.ac_unit_rounded, 'El Kesimi Kristal Buz'),
                  _buildHeroFeaturePill(
                      Icons.verified_user_rounded, '%100 Escrow Güvencesi'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Mode 3: Combined Chef + Bartender Pairing Builder
    if (_selectedCategoryIndex == 3) {
      final pairedChef = _recommendedChefs.isNotEmpty
          ? _recommendedChefs[_selectedPairedChefIdx % _recommendedChefs.length]
          : null;
      final pairedMix = _topMixologists.isNotEmpty
          ? _topMixologists[_selectedPairedMixIdx % _topMixologists.length]
          : null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: palette.goldAccent.withValues(alpha: 0.6), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.goldAccent.withValues(alpha: isDark ? 0.14 : 0.08),
              _mixologistPurple.withValues(alpha: isDark ? 0.14 : 0.06),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.emerald,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GASTRONOMİ & MİKSOLOJİ İKİLİSİ',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Kombine Davet Paketi',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.goldAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Özel Şef + Master Miksolojist Eşleşmesi',
              style: GoogleFonts.libreCaslonText(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Şefiniz çok aşamalı tadım menüsünü hazırlarken, miksolojistiniz her tabağa uyumlu imza kokteyller servis eder.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: palette.textMuted,
                height: 1.35,
              ),
            ),
            if (pairedChef != null && pairedMix != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPairedChefIdx = (_selectedPairedChefIdx + 1) %
                              _recommendedChefs.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: palette.goldAccent.withValues(alpha: 0.45)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.restaurant_menu_rounded,
                                    size: 13, color: palette.goldAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Özel Şef (Değiştir)',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: palette.goldAccent,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pairedChef['name'],
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              pairedChef['price'],
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.add_circle_rounded,
                        color: palette.goldAccent, size: 20),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPairedMixIdx =
                              (_selectedPairedMixIdx + 1) %
                                  _topMixologists.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _mixologistPurple.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_bar_rounded,
                                    size: 13,
                                    color: isDark
                                        ? _mixologistLilac
                                        : _mixologistPurple),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Miksolojist (Değiştir)',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? _mixologistLilac
                                          : _mixologistPurple,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pairedMix['name'],
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              pairedMix['price'],
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final unitPrice = (pairedChef['unit_price'] as num?)
                            ?.toDouble() ??
                        2150.0;
                    _handleSelectMenu({
                      'id': pairedChef['id'],
                      'name':
                          '${pairedChef['name']} & ${pairedMix['name']}',
                      'image': pairedChef['image'],
                      'price': pairedChef['price'],
                      'price_per_person': unitPrice,
                      'provider_type': 'chef',
                      'include_bartender_upsell': true,
                      'addon_bartender_name': pairedMix['name'],
                      'addon_bartender_id': pairedMix['id'],
                    }, {
                      'id': 'combo_${pairedChef['id']}_${pairedMix['id']}',
                      'title':
                          'Şef Tadım Menüsü + ${pairedMix['name']} İmza Kokteyl Barı',
                      'price_per_person': unitPrice,
                    });
                  },
                  icon: const Icon(Icons.celebration_rounded, size: 16),
                  label: Text(
                    'Kombine Paketi Rezerve Et',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? palette.goldAccent : Colors.black,
                    foregroundColor:
                        isDark ? const Color(0xFF0B0D11) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Mode 0 (Tümü) or Mode 1 (Özel Şef): Dual-Showcase Hero Card
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.92),
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.20),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.goldAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ÖZEL ŞEF & MİKSOLOJİ PLATFORMU',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B0D11),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _selectedCategoryIndex == 1
                  ? 'Evinizde Michelin Standartlarında Özel Şef'
                  : 'Evinizde Fine Dining Şef & Nitelikli Kokteyl Barı',
              style: GoogleFonts.libreCaslonText(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$location bölgesindeki sertifikalı özel şefleri ve master miksolojistleri keşfedin; %100 Escrow güvencesiyle rezerve edin.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.90),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _selectedCategoryIndex = 1),
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 15),
                    label: Text(
                      'Özel Şef Seç',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.goldAccent,
                      foregroundColor: const Color(0xFF0B0D11),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _selectedCategoryIndex = 2),
                    icon: const Icon(Icons.local_bar_rounded, size: 15),
                    label: Text(
                      'Miksolojist Seç',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mixologistPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required bool showAllAction,
    required VoidCallback onTapShowAll,
    required AppThemePalette palette,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (showAllAction)
              InkWell(
                onTap: onTapShowAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümü',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: accentColor),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }

  // Safe Image with fallback
  Widget _buildSafeNetworkImage(String url, double height,
      {double? width,
      BoxFit fit = BoxFit.cover,
      IconData placeholderIcon = Icons.restaurant_rounded,
      required AppThemePalette palette}) {
    return Image.network(
      url,
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width ?? double.infinity,
          color: palette.surfaceElevated,
          child: Center(
            child: Icon(placeholderIcon,
                size: 36, color: palette.goldAccent.withValues(alpha: 0.6)),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width ?? double.infinity,
          color: palette.surfaceElevated,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.goldAccent,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  // Unified Equal-Hierarchy Showcase Card for BOTH Chefs and Mixologists
  Widget _buildProviderShowcaseCard({
    required Map<String, dynamic> provider,
    required bool isBartender,
    required AppThemePalette palette,
    required bool isDark,
  }) {
    final Color roleAccent = isBartender
        ? (isDark ? _mixologistLilac : _mixologistPurple)
        : palette.goldAccent;
    final Color roleBadgeBg =
        isBartender ? _mixologistPurple : const Color(0xFF13171F);
    final String roleLabel =
        isBartender ? 'Master Miksolojist' : 'Özel Şef';
    final IconData roleIcon = isBartender
        ? Icons.local_bar_rounded
        : Icons.restaurant_menu_rounded;

    final List<String> tagsList = (provider['tags'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (provider['tag'] != null
            ? [provider['tag'].toString(), 'Mobil Bar Dahil']
            : ['İmza Deneyim']);

    final double unitPrice = (provider['unit_price'] as num?)?.toDouble() ??
        (isBartender ? 900.0 : 1850.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBartender
              ? roleAccent.withValues(alpha: 0.35)
              : palette.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: _buildSafeNetworkImage(
                  provider['image'] ?? '',
                  200,
                  palette: palette,
                  placeholderIcon: roleIcon,
                ),
              ),
              // Top-Left: Role & Distance Badges
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: roleBadgeBg.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon,
                              color: isBartender
                                  ? Colors.white
                                  : palette.goldAccent,
                              size: 12),
                          const SizedBox(width: 4),
                          Text(
                            roleLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: palette.emerald,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded,
                              color: Colors.white, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            provider['distance_km'] ?? '3.2 km',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Top-Right: Rating Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF13171F).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: palette.goldAccent, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        provider['rating']?.toString() ?? '4.9',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom-Left on Image: Verification Badges
              Positioned(
                bottom: 10,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF10B981), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            isBartender
                                ? 'Hijyen & WSET Sertifikalı'
                                : 'Hijyen & Gastronomi Diplomalı',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    if (widget.onTapChefProfile != null) {
                      widget.onTapChefProfile!({
                        'id': provider['id'],
                        'name': provider['name'],
                        'image': provider['image'],
                        'price': provider['price'],
                        'rating': provider['rating'],
                        'role': isBartender
                            ? 'Master Mixologist'
                            : 'Executive Chef',
                        'provider_type':
                            isBartender ? 'bartender' : 'chef',
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    provider['name'] ?? '',
                                    style: GoogleFonts.libreCaslonText(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 12, color: roleAccent),
                              ],
                            ),
                            if (provider['title'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                provider['title'].toString(),
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: roleAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: roleAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: roleAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          provider['price'] ?? '',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: roleAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider['description'] ??
                      (isBartender
                          ? 'Taşınabilir kokteyl istasyonu, özel buzlar ve taze botaniklerle hazırlanan imza kokteyl barı hizmeti.'
                          : 'Özel davetleriniz için mevsimsel ürünlerle hazırlanan çok aşamalı şef tadım menüsü.'),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: palette.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tagsList.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: palette.borderSubtle),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (widget.onTapChefProfile != null) {
                            widget.onTapChefProfile!({
                              'id': provider['id'],
                              'name': provider['name'],
                              'image': provider['image'],
                              'price': provider['price'],
                              'rating': provider['rating'],
                              'role': isBartender
                                  ? 'Master Mixologist'
                                  : 'Executive Chef',
                              'provider_type':
                                  isBartender ? 'bartender' : 'chef',
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: palette.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Profili Gör',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSelectMenu({
                          'id': provider['id'],
                          'name': provider['name'],
                          'image': provider['image'],
                          'price': provider['price'],
                          'hourly_rate': isBartender ? unitPrice : null,
                          'price_per_person': !isBartender ? unitPrice : null,
                          'provider_type':
                              isBartender ? 'bartender' : 'chef',
                        }, {
                          'id': 'm_${provider['id']}',
                          'title': isBartender
                              ? '${provider['name']} - İmza Kokteyl & Mobil Bar Paketi'
                              : (provider['description'] ??
                                  'Özel Şef Tadım Menüsü'),
                          'price_per_person': unitPrice,
                        }),
                        icon: Icon(
                          isBartender
                              ? Icons.local_bar_rounded
                              : Icons.restaurant_menu_rounded,
                          size: 14,
                        ),
                        label: Text(
                          isBartender ? 'Bar Paketi Seç' : 'Menüyü İncele',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBartender
                              ? _mixologistPurple
                              : (isDark ? palette.goldAccent : Colors.black),
                          foregroundColor: isBartender
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF0B0D11)
                                  : Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
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

  Widget _buildActiveBookingBanner(
      BookingModel activeBooking, AppThemePalette palette, bool isDark) {
    return InkWell(
      onTap: () {
        if (widget.onTapBookings != null) {
          widget.onTapBookings!();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.goldAccent.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: palette.goldAccent.withValues(alpha: isDark ? 0.1 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.goldGlow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_rounded,
                  color: palette.goldAccent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Devam Eden Rezervasyon',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.goldAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${activeBooking.providerName} • #${activeBooking.id}',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: palette.goldAccent, size: 14),
          ],
        ),
      ),
    );
  }
}
