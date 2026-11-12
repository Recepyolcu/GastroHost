import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class ChefProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> provider;
  final VoidCallback? onBack;
  final Function(DateTime selectedDate)? onStartBookingWithDate;
  final VoidCallback? onStartBooking;
  final VoidCallback? onOpenChat;

  const ChefProfileScreen({
    super.key,
    required this.provider,
    this.onBack,
    this.onStartBookingWithDate,
    this.onStartBooking,
    this.onOpenChat,
  });

  @override
  ConsumerState<ChefProfileScreen> createState() => _ChefProfileScreenState();
}

class _ChefProfileScreenState extends ConsumerState<ChefProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Calendar State
  late DateTime _displayedMonth;
  DateTime? _selectedCalendarDate;

  // Mock Calendar Availability (day offset from now -> status: 'available', 'booked', 'off')
  late Map<String, String> _dateAvailability;
  List<Map<String, dynamic>> _liveReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
    _selectedCalendarDate = now.add(const Duration(days: 2));
    _generateMockAvailability();
    _loadLiveAvailabilityAndReviews();
  }

  Future<void> _loadLiveAvailabilityAndReviews() async {
    try {
      final provId = (widget.provider['provider_id'] ?? widget.provider['id'])?.toString() ?? '';
      if (provId.length < 30) return;
      final supabase = SupabaseService();
      final slots = await supabase.getProviderAvailability(provId);
      final revs = await supabase.getProviderReviews(provId);
      if (!mounted) return;
      setState(() {
        for (final slot in slots) {
          final rawDate = slot['date']?.toString() ?? '';
          final dt = DateTime.tryParse(rawDate);
          if (dt != null) {
            final key = '${dt.year}-${dt.month}-${dt.day}';
            final isAvail = slot['is_available'] as bool? ?? true;
            final note = slot['note']?.toString() ?? '';
            _dateAvailability[key] = isAvail
                ? 'available'
                : (note.toLowerCase().contains('izin') ? 'off' : 'booked');
          }
        }
        if (revs.isNotEmpty) {
          _liveReviews = revs.map((r) {
            final cust = (r['customer'] as Map<String, dynamic>?) ?? const {};
            final custName = cust['full_name']?.toString() ??
                '${cust['first_name'] ?? ''} ${cust['last_name'] ?? ''}'.trim();
            final rf = (r['rating_food'] as num?)?.toDouble() ?? 5.0;
            final rh = (r['rating_hygiene'] as num?)?.toDouble() ?? 5.0;
            final rp = (r['rating_presentation'] as num?)?.toDouble() ?? 5.0;
            final ro = (r['rating_overall'] as num?)?.toDouble() ?? ((rf + rh + rp) / 3.0);
            return {
              'name': custName.isNotEmpty ? custName : 'Onaylı Misafir',
              'date': 'Doğrulanmış Deneyim',
              'event': 'GastroHost Özel Rezervasyon',
              'rating': double.parse(ro.toStringAsFixed(1)),
              'criteria': {'Lezzet': rf, 'Hijyen': rh, 'Sunum': rp},
              'comment': r['comment']?.toString() ?? 'Kusursuz bir gastronomi deneyimiydi.',
              'tags': <String>['Doğrulanmış Yorum', 'Kusursuz Hijyen'],
            };
          }).toList();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateMockAvailability() {
    _dateAvailability = {};
    final now = DateTime.now();
    for (int i = 0; i < 60; i++) {
      final date = now.add(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      if (date.weekday == DateTime.monday) {
        _dateAvailability[key] = 'off'; // Şefin dinlenme günü
      } else if (i == 1 || i == 5 || i == 8 || i == 12 || i == 19) {
        _dateAvailability[key] = 'booked'; // Dolu / Rezerve
      } else {
        _dateAvailability[key] = 'available'; // Müsait
      }
    }
  }

  bool get _isMixologist {
    final type = widget.provider['provider_type'];
    final id = widget.provider['id']?.toString() ?? '';
    final price = widget.provider['price']?.toString() ?? '';
    return type == 'bartender' || id.startsWith('m') || price.contains('/hr') || price.contains('/saat');
  }

  String get _chefName =>
      widget.provider['name'] ?? (_isMixologist ? 'Marcus T.' : 'Chef Julian');

  String get _chefRole =>
      widget.provider['role'] ??
      (_isMixologist ? 'Master Mixologist & Beverage Director' : 'Executive Chef & Gastronomi Danışmanı');

  String get _chefRating => (widget.provider['rating'] ?? '4.9').toString();

  String get _chefAvatar {
    if (widget.provider['image'] != null) return widget.provider['image'];
    if (widget.provider['avatar'] != null) return widget.provider['avatar'];
    return _isMixologist
        ? 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&auto=format&fit=crop&q=80'
        : 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isDark = settings.isDarkMode;
    final palette = AppThemePalette(isDark);

    return Scaffold(
      backgroundColor: palette.bg,
      bottomNavigationBar: _buildBottomActionBar(palette, isDark),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Top Action Bar
              SliverToBoxAdapter(
                child: Padding(
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
                      Text(
                        'Şef Profili',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$_chefName profili kopyalandı'),
                              backgroundColor: palette.surfaceElevated,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(Icons.share_outlined, color: palette.textPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor: palette.surfaceElevated,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Chef Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _buildChefHeroCard(palette, isDark),
                ),
              ),

              // Sticky / Pinned Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: palette.goldAccent,
                    indicatorWeight: 3,
                    labelColor: palette.goldAccent,
                    unselectedLabelColor: palette.textMuted,
                    labelStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Ustalık & Menü'),
                      Tab(text: 'Eğitim & Sertifika'),
                      Tab(text: 'Değerlendirmeler'),
                      Tab(text: 'Müsaitlik Takvimi'),
                    ],
                  ),
                  palette.bg,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSpecialtiesTab(palette, isDark),
              _buildEducationTab(palette, isDark),
              _buildReviewsTab(palette, isDark),
              _buildCalendarTab(palette, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CHEF HERO CARD
  // ---------------------------------------------------------------------------
  Widget _buildChefHeroCard(AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Gold Accent Border
              Stack(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.goldAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: palette.goldAccent.withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        _chefAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: palette.surfaceElevated,
                          child: Icon(Icons.person, color: palette.goldAccent, size: 40),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Name, Badges & Verification
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _chefName,
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified_rounded, color: palette.goldAccent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _chefRole,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: palette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Verified Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.goldGlow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: palette.goldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: palette.goldAccent, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            _isMixologist ? 'Master Mixologist Lisanslı' : 'Michelin Deneyimli • Doğrulanmış Şef',
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
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('PUAN', '$_chefRating ★', '124 Değerlendirme', palette),
                _buildStatDivider(palette),
                _buildStatItem('DENEYİM', '14 Yıl', 'Yüksek Mutfak', palette),
                _buildStatDivider(palette),
                _buildStatItem('ETKİNLİK', '180+', 'Kusursuz Hizmet', palette),
                _buildStatDivider(palette),
                _buildStatItem('MEMNUNİYET', '%99', 'Tekrar Eden Misafir', palette),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subtext, AppThemePalette palette) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: palette.goldAccent,
          ),
        ),
        Text(
          subtext,
          style: GoogleFonts.manrope(
            fontSize: 9,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(AppThemePalette palette) {
    return Container(
      height: 28,
      width: 1,
      color: palette.borderSubtle,
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: SPECIALTIES & PHILOSOPHY
  // ---------------------------------------------------------------------------
  Widget _buildSpecialtiesTab(AppThemePalette palette, bool isDark) {
    final List<Map<String, dynamic>> signatureDishes = _isMixologist
        ? [
            {
              'title': 'Smoked Rosemary Botanical Old Fashioned',
              'desc': 'Meşe dumanı infüzyonlu bourbon, el yapımı biberiye şurubu ve portakal bitteri.',
              'tag': 'İmza Kokteyl',
              'icon': Icons.local_bar_rounded,
            },
            {
              'title': 'Elysian Garden Gin & Tonic',
              'desc': 'Taze lavanta, yeşil elma dilimleri ve bergamot aromalı butik tonik ile.',
              'tag': 'Özel Reçete',
              'icon': Icons.wine_bar_rounded,
            },
            {
              'title': 'Yuzu & Jalapeño Craft Paloma',
              'desc': 'Tütsülenmiş deniz tuzu kenarlıklı, ferahlatıcı yuzu ve acı dengesi.',
              'tag': 'Füzyon',
              'icon': Icons.local_fire_department_rounded,
            },
          ]
        : [
            {
              'title': 'Trüflü El Yapımı Tagliolini',
              'desc': '36 aylık Parmigiano Reggiano kreması, dağ tereyağı ve taze siyah trüf rendesi.',
              'tag': 'İmza Yemek',
              'icon': Icons.restaurant_menu_rounded,
            },
            {
              'title': 'Sous-Vide Kuzu İncik & Yaban Mersini Redüksiyonu',
              'desc': '18 saat kısık ateşte pişirilmiş, trüflü kereviz püresi ve fırınlanmış arpacık soğan.',
              'tag': 'Fine Dining',
              'icon': Icons.dinner_dining_rounded,
            },
            {
              'title': 'Portakal Çiçeği Aromalı İncirli Panna Cotta',
              'desc': 'Madagaskar vanilyası, karamelize Bodrum inciri ve Antep fıstığı kıtırı ile.',
              'tag': 'Gurme Tatlı',
              'icon': Icons.cake_rounded,
            },
          ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Culinary Philosophy Card
        _buildSectionHeader('Mutfak Felsefesi & Yaklaşımı', Icons.auto_awesome_rounded, palette),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            _isMixologist
                ? 'Kokteyl sanatını yalnızca içki karıştırmak değil, duyusal bir gastronomi deneyimi olarak görüyorum. Taze botanik infüzyonlar, ev yapımı meyve şurupları ve moleküler dumanlama teknikleriyle misafirlerinize unutulmaz bir bar atmosferi sunuyorum.'
                : 'Mutfak felsefem "topraktan sofraya" dürüst gastronomiye dayanır. Michelin yıldızlı mutfaklarda edindiğim yüksek disiplin ve Fransız tekniklerini, mevsimin en taze yerel malzemeleriyle harmanlıyorum. Her tabak bir sanat eseri, eviniz ise seçkin bir şef restoranıdır.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: palette.textMuted,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Mastery & Cuisines
        _buildSectionHeader('Ustalık Alanları & Teknikler', Icons.star_border_rounded, palette),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_isMixologist
                  ? [
                      'Craft Kokteyl Tasarımı',
                      'Botanik İnfüzyonlar',
                      'Moleküler Dumanlama',
                      'Şarap & Menü Eşleşmesi',
                      'Premium Bar Servisi',
                      'Alkolsuz Butik Mocktail',
                      'Buz Heykeltraşlığı',
                    ]
                  : [
                      'Modern İtalyan Mutfağı',
                      'Çağdaş Fransız Teknikleri',
                      'El Yapımı Taze Makarna',
                      'Sous-Vide Pişirme',
                      'Ege & Akdeniz Füzyon',
                      'Moleküler Tabaklama',
                      'Glutensiz & Çölyak Protokolü',
                      'Alerjen İzolasyonu',
                    ])
              .map((badge) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: palette.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: palette.goldAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: palette.goldAccent),
                        const SizedBox(width: 6),
                        Text(
                          badge,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),

        // Signature Dishes / Recipes
        _buildSectionHeader(
            _isMixologist ? 'İmza Kokteyller & Reçeteler' : 'Öne Çıkan İmza Tabaklar',
            Icons.restaurant_rounded,
            palette),
        const SizedBox(height: 8),
        ...signatureDishes.map((dish) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(dish['icon'] as IconData, color: palette.goldAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              dish['title'] as String,
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.goldGlow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dish['tag'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: palette.goldAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dish['desc'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: palette.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: EDUCATION & CERTIFICATIONS
  // ---------------------------------------------------------------------------
  Widget _buildEducationTab(AppThemePalette palette, bool isDark) {
    final educations = _isMixologist
        ? [
            {
              'school': 'European Bartender School (EBS)',
              'degree': 'Advanced Bartending & Mixology Diploma',
              'year': '2016 - 2017',
              'desc': 'Kokteyl dizaynı, botanik ekstraksiyon ve moleküler bar teknikleri.',
              'verified': true,
            },
            {
              'school': 'WSET (Wine & Spirit Education Trust)',
              'degree': 'WSET Level 3 Spirits & Wine Award',
              'year': '2018',
              'desc': 'Uluslararası damıtılmış içkiler ve bağcılık uzmanlığı derecesi.',
              'verified': true,
            },
            {
              'school': 'Barista & Coffee Academy',
              'degree': 'Sensory & Botanical Infusion Specialist',
              'year': '2020',
              'desc': 'Soğuk demleme, taze aroma ekstraksiyonu ve şurup formülasyonu.',
              'verified': true,
            },
          ]
        : [
            {
              'school': 'Le Cordon Bleu Paris',
              'degree': 'Grand Diplôme de Cuisine & Pâtisserie',
              'year': '2012 - 2014',
              'desc': 'Fransız klasik gastronomi teknikleri, mutfak organizasyonu ve tabaklama.',
              'verified': true,
            },
            {
              'school': 'Mutfak Sanatları Akademisi (MSA)',
              'degree': 'Profesyonel Aşçılık & Mutfak Yönetimi',
              'year': '2010 - 2011',
              'desc': 'Uluslararası mutfak standartları ve City & Guilds akreditasyonu.',
              'verified': true,
            },
            {
              'school': 'Alma La Scuola Internazionale di Cucina Italiana (Parma)',
              'degree': 'Master in Taze Makarna & Risotto Zanaatkarlığı',
              'year': '2015',
              'desc': 'Kuzey İtalya trüf gelenekleri ve artisanal pasta imalatı.',
              'verified': true,
            },
          ];

    final certifications = [
      {
        'title': 'HACCP & ISO 22000 İleri Gıda Güvenliği',
        'issuer': 'Uluslararası Gıda Hijyeni Standartları',
        'code': 'GH-CERT-9041',
        'icon': Icons.shield_outlined,
      },
      {
        'title': 'ServSafe Allergen & Celiac Protocol',
        'issuer': 'National Restaurant Association',
        'code': 'GH-ALLERG-2024',
        'icon': Icons.health_and_safety_outlined,
      },
      {
        'title': 'GastroHost Premium Şef Güvenlik & Sicil Doğrulaması',
        'issuer': 'GastroHost Teftiş Kurulu',
        'code': 'VERIFIED-ID-8821',
        'icon': Icons.verified_user_outlined,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trust Guarantee Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.goldGlow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.goldAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: palette.goldAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doğrulanmış Gastronomi Eğitimi',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: palette.goldAccent,
                      ),
                    ),
                    Text(
                      'Tüm diplomalar, gıda güvenliği sertifikaları ve sicil kayıtları GastroHost ekibince onaylanmıştır.',
                      style: GoogleFonts.manrope(fontSize: 11, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Academic Education
        _buildSectionHeader('Akademik Gastronomi Eğitimi', Icons.school_rounded, palette),
        const SizedBox(height: 10),
        ...educations.map((edu) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.goldAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_rounded, color: palette.goldAccent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              edu['school'] as String,
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            edu['year'] as String,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: palette.goldAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        edu['degree'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        edu['desc'] as String,
                        style: GoogleFonts.manrope(fontSize: 11, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Certifications
        _buildSectionHeader('Resmi Sertifikalar & Lisanslar', Icons.badge_outlined, palette),
        const SizedBox(height: 10),
        ...certifications.map((cert) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(cert['icon'] as IconData, color: const Color(0xFF10B981), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert['title'] as String,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        '${cert['issuer']} • Lisans No: ${cert['code']}',
                        style: GoogleFonts.manrope(fontSize: 11, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 18),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: REVIEWS & 3-CRITERIA RATING
  // ---------------------------------------------------------------------------
  Widget _buildReviewsTab(AppThemePalette palette, bool isDark) {
    final List<Map<String, dynamic>> userReviews = [
      ..._liveReviews,
      {
        'name': 'Zeynep & Emre K.',
        'date': 'Geçen Hafta',
        'event': 'Evlilik Yıldönümü (4 Misafir)',
        'rating': 5.0,
        'criteria': {'Lezzet': 5.0, 'Hijyen': 5.0, 'Sunum': 5.0},
        'comment':
            'Şefimizin hazırladığı trüflü tagliolini ve kuzu incik hayatımızda yediğimiz en lezzetli yemeklerdendi. Mutfaktan ayrılırken tezgahlara kadar pırıl pırıl temiz bırakması bizi çok etkiledi. Harika bir deneyim!',
        'tags': ['Kusursuz Hijyen', 'Muazzam Lezzet'],
      },
      {
        'name': 'Murat B.',
        'date': '2 Hafta Önce',
        'event': 'İş Yemeği Ziyafeti (6 Misafir)',
        'rating': 4.9,
        'criteria': {'Lezzet': 5.0, 'Hijyen': 5.0, 'Sunum': 4.8},
        'comment':
            'Yurtdışından gelen önemli iş ortaklarımız için şefimizi çağırdık. Hem dakikliği hem de yemeklerin restoran standardındaki sunumuyla evimizi 5 yıldızlı bir gastronomi kulübüne çevirdi.',
        'tags': ['Dakik & Saygılı', 'Fine Dining Kalitesi'],
      },
      {
        'name': 'Selin T.',
        'date': '3 Hafta Önce',
        'event': 'Doğum Günü Kutlaması (8 Misafir)',
        'rating': 4.8,
        'criteria': {'Lezzet': 4.9, 'Hijyen': 5.0, 'Sunum': 4.8},
        'comment':
            'Alerjenler konusunda çok dikkatliydi, misafirlerimizden birinin glüten hassasiyetine özel ayrı tava ve tepsiler kullandı. Herkese güvenle tavsiye ederim.',
        'tags': ['Alerjen Duyarlılığı', 'Güleryüzlü'],
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall & 3-Criteria Breakdown Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Big Score
                  Column(
                    children: [
                      Text(
                        _chefRating,
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: palette.goldAccent,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(Icons.star_rounded, color: palette.goldAccent, size: 16),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '124 Değerlendirme',
                        style: GoogleFonts.manrope(fontSize: 11, color: palette.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // 3 Criteria Bars
                  Expanded(
                    child: Column(
                      children: [
                        _buildCriteriaBar('Yemek Lezzeti', 4.9, palette),
                        const SizedBox(height: 8),
                        _buildCriteriaBar('Mutfak Hijyeni', 5.0, palette),
                        const SizedBox(height: 8),
                        _buildCriteriaBar('Sunum & Servis', 4.8, palette),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: palette.borderSubtle),
              const SizedBox(height: 10),

              // Positive Badges
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildQuickPill('Kusursuz Hijyen (%100)', palette),
                  _buildQuickPill('Olağanüstü Lezzet (%99)', palette),
                  _buildQuickPill('Zarif Sunum (%97)', palette),
                  _buildQuickPill('Dakik & Güvenilir (%98)', palette),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Real Reviews List
        _buildSectionHeader('Misafir Yorumları', Icons.rate_review_outlined, palette),
        const SizedBox(height: 10),
        ...userReviews.map((rev) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: palette.goldAccent.withValues(alpha: 0.2),
                          child: Text(
                            (rev['name'] as String)[0],
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              color: palette.goldAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rev['name'] as String,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              '${rev['event']} • ${rev['date']}',
                              style: GoogleFonts.manrope(fontSize: 10, color: palette.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.goldGlow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: palette.goldAccent, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${rev['rating']}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: palette.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  rev['comment'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: palette.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: (rev['tags'] as List<String>)
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: palette.goldAccent,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCriteriaBar(String title, double score, AppThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.manrope(fontSize: 11, color: palette.textMuted)),
            Text('$score ★',
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.bold, color: palette.textPrimary)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 5.0,
            backgroundColor: palette.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(palette.goldAccent),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPill(String text, AppThemePalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textPrimary),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: INTERACTIVE AVAILABILITY CALENDAR
  // ---------------------------------------------------------------------------
  Widget _buildCalendarTab(AppThemePalette palette, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Calendar Instruction & Legend Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Canlı Müsaitlik Takvimi',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Şefin güncel takvimini inceleyebilir, müsait bir tarih seçerek doğrudan rezervasyon oluşturabilirsiniz.',
                style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
              ),
              const SizedBox(height: 12),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(const Color(0xFF10B981), 'Müsait', palette),
                  _buildLegendItem(const Color(0xFFEF4444), 'Dolu / Rezerve', palette),
                  _buildLegendItem(palette.textMuted.withValues(alpha: 0.5), 'İzinli / Kapalı', palette),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Month Selector & Calendar Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Month Switcher Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
                      });
                    },
                    icon: Icon(Icons.chevron_left_rounded, color: palette.textPrimary),
                  ),
                  Text(
                    _formatMonthYear(_displayedMonth),
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
                      });
                    },
                    icon: Icon(Icons.chevron_right_rounded, color: palette.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Day of week labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                    .map((d) => SizedBox(
                          width: 38,
                          child: Center(
                            child: Text(
                              d,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Divider(color: palette.borderSubtle),
              const SizedBox(height: 8),

              // Calendar Days Grid
              _buildMonthDaysGrid(palette, isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected Date Details & Booking Action Card
        if (_selectedCalendarDate != null)
          _buildSelectedDateInfoCard(_selectedCalendarDate!, palette, isDark),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, AppThemePalette palette) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: palette.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDaysGrid(AppThemePalette palette, bool isDark) {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;

    // Weekday: Monday is 1, Sunday is 7 -> offset is firstDay.weekday - 1
    final startOffset = firstDayOfMonth.weekday - 1;

    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink(); // Empty padding cell
        }

        final cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNumber);
        final key = '${cellDate.year}-${cellDate.month}-${cellDate.day}';
        final status = _dateAvailability[key] ?? 'available';

        final isSelected = _selectedCalendarDate != null &&
            _selectedCalendarDate!.year == cellDate.year &&
            _selectedCalendarDate!.month == cellDate.month &&
            _selectedCalendarDate!.day == cellDate.day;

        final isPast = cellDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

        Color badgeColor;
        if (isPast) {
          badgeColor = Colors.transparent;
        } else if (status == 'available') {
          badgeColor = const Color(0xFF10B981);
        } else if (status == 'booked') {
          badgeColor = const Color(0xFFEF4444);
        } else {
          badgeColor = palette.textMuted.withValues(alpha: 0.4);
        }

        return InkWell(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _selectedCalendarDate = cellDate;
                  });
                },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? palette.goldAccent.withValues(alpha: 0.2)
                  : (isPast ? Colors.transparent : palette.surfaceElevated),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? palette.goldAccent
                    : (isPast ? Colors.transparent : palette.borderSubtle),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isPast
                          ? palette.textMuted.withValues(alpha: 0.3)
                          : (isSelected ? palette.goldAccent : palette.textPrimary),
                    ),
                  ),
                ),
                if (!isPast)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    left: 4,
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
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
  }

  Widget _buildSelectedDateInfoCard(DateTime date, AppThemePalette palette, bool isDark) {
    final key = '${date.year}-${date.month}-${date.day}';
    final status = _dateAvailability[key] ?? 'available';
    final isAvailable = status == 'available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? (isDark ? const Color(0xFF18221D) : const Color(0xFFF0FDF4))
            : palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? const Color(0xFF10B981) : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAvailable ? Icons.event_available_rounded : Icons.event_busy_rounded,
                    color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatFullDate(date),
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAvailable ? 'Müsait' : (status == 'booked' ? 'Rezerve' : 'İzinli'),
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isAvailable) ...[
            Text(
              'Açık Servis Saat Dilimleri:',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildTimeSlotBadge('Öğle Servisi: 12:30 - 15:30', palette),
                const SizedBox(width: 8),
                _buildTimeSlotBadge('Akşam Ziyafeti: 19:00 - 23:00', palette),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.onStartBookingWithDate != null) {
                    widget.onStartBookingWithDate!(date);
                  } else if (widget.onStartBooking != null) {
                    widget.onStartBooking!();
                  }
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: Text(
                  'Bu Tarihe (${date.day} ${_formatMonthOnly(date)}) Rezervasyon Yap',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? palette.goldAccent : Colors.black,
                  foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Text(
              status == 'booked'
                  ? 'Şefimiz bu tarihte başka bir özel etkinlik için rezerve edilmiştir. Lütfen takvimdeki diğer yeşil günlerden birini seçiniz.'
                  : 'Şefimizin haftalık izin ve dinlenme günüdür.',
              style: GoogleFonts.manrope(fontSize: 12, color: palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotBadge(String text, AppThemePalette palette) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.borderSubtle),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: palette.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatMonthOnly(DateTime dt) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[dt.month - 1];
  }

  String _formatFullDate(DateTime dt) {
    const weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return '${dt.day} ${_formatMonthOnly(dt)} ${weekdays[dt.weekday - 1]}';
  }

  Widget _buildSectionHeader(String title, IconData icon, AppThemePalette palette) {
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.goldAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.libreCaslonText(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. BOTTOM ACTION BAR (SAFEAREA INTACT)
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(AppThemePalette palette, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          children: [
            // Chat Button
            OutlinedButton.icon(
              onPressed: () {
                if (widget.onOpenChat != null) {
                  widget.onOpenChat!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_chefName ile mesajlaşma başlatılıyor...'),
                      backgroundColor: palette.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: palette.textPrimary),
              label: Text(
                'Mesaj Gönder',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                side: BorderSide(color: palette.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(width: 10),

            // Book Now Action
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_selectedCalendarDate != null && widget.onStartBookingWithDate != null) {
                    widget.onStartBookingWithDate!(_selectedCalendarDate!);
                  } else if (widget.onStartBooking != null) {
                    widget.onStartBooking!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                icon: const Icon(Icons.restaurant_rounded, size: 18),
                label: Text(
                  'Rezervasyon Yap',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? palette.goldAccent : Colors.black,
                  foregroundColor: isDark ? const Color(0xFF0B0D11) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _SliverTabBarDelegate(this._tabBar, this._bgColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
