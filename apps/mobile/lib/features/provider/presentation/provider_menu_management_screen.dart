import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/supabase_service.dart';
import 'widgets/menu_editor_modal.dart';

class ProviderMenuManagementScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String initialRole; // 'chef' or 'bartender'

  const ProviderMenuManagementScreen({
    super.key,
    required this.onBack,
    this.initialRole = 'chef',
  });

  @override
  State<ProviderMenuManagementScreen> createState() => _ProviderMenuManagementScreenState();
}

class _ProviderMenuManagementScreenState extends State<ProviderMenuManagementScreen> {
  late String _currentRole;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'active', 'inactive'

  // Pre-populated Mock Menus for Demo & Offline Mode
  late List<Map<String, dynamic>> _chefMenus;
  late List<Map<String, dynamic>> _mixologistMenus;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    _initMockMenus();
    _fetchMenus();
  }

  void _initMockMenus() {
    _chefMenus = [
      {
        'id': 'm101',
        'title': 'Tuscan Truffle & Fine Dining Experience',
        'description': 'İtalya\'dan özel getirilen siyah trüf mantarları, taze el yapımı tagliatelle ve dinlendirilmiş dana antrikot eşliğinde 4 aşamalı gurme deneyimi.',
        'category': 'Fine Dining & Tasting',
        'price': 1200.0,
        'min_limit': 4,
        'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
        'items': [
          'Başlangıç: Trüflü Burrata & Bruschetta',
          'Ara Sıcak: Taze El Yapımı Tagliatelle Al Tartufo',
          'Ana Yemek: 28 Gün Dinlendirilmiş Dana Antrikot',
          'Tatlı: Geleneksel İtalyan Tiramisu',
        ],
        'tags': ['Glutensiz Seçenek', 'Mutfak Ekipmanı Dahil'],
        'is_active': true,
        'type': 'chef',
      },
      {
        'id': 'm102',
        'title': 'Modern Ege & Deniz Mahsulleri Tadımı',
        'description': 'Ayvalık ve Çeşme kıyılarından günlük taze balıklar, soğuk sıkım sızma zeytinyağlı Ege otları ve narenciye soslu karides ceviche.',
        'category': 'Modern Ege & Akdeniz',
        'price': 950.0,
        'min_limit': 6,
        'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
        'items': [
          'Başlangıç: Avokadolu Narenciye Soslu Karides Ceviche',
          'Ara Sıcak: Kadayıfa Sarılı Çıtır Ahtapot',
          'Ana Yemek: Izgara Levrek & Rezene Püresi',
          'Tatlı: Çam Fıstıklı & Sakızlı İncir Uyutması',
        ],
        'tags': ['Glutensiz', 'Zeytinyağlı Özel'],
        'is_active': true,
        'type': 'chef',
      },
      {
        'id': 'm103',
        'title': 'Anadolu & Osmanlı Saray Mutfak Mirası',
        'description': 'Osmanlı saray reçetelerine sadık kalınarak ağır ateşte 12 saat pişen Hünkâr Beğendi ve safranlı vişneli yaprak sarması.',
        'category': 'Osmanlı & Anadolu',
        'price': 850.0,
        'min_limit': 4,
        'image': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80',
        'items': [
          'Başlangıç: Vişneli Yaprak Sarması & Humus',
          'Ara Sıcak: Paçanga Böreği & Erzincan Tulumu',
          'Ana Yemek: Ağır Ateşte Hünkâr Beğendi',
          'Tatlı: Safranlı Baklava & Maras Dondurması',
        ],
        'tags': ['Geleneksel Reçete'],
        'is_active': false,
        'type': 'chef',
      },
    ];

    _mixologistMenus = [
      {
        'id': 'm201',
        'title': 'Signature Craft Cocktail Tasting Bar',
        'description': 'Ev yapımı botanik infüzyonlar, meşe dumanlı Old Fashioned ve tutku meyveli spritz içeren mobil lüks kokteyl barı hizmeti.',
        'category': 'Signature Craft Cocktails',
        'price': 80.0,
        'min_limit': 3,
        'image': 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800&q=80',
        'items': [
          'Smoked Rosemary Old Fashioned',
          'Passionfruit & Basil Spritz',
          'Spicy Cucumber Margarita',
          'Artisanal Craft Mocktail',
        ],
        'tags': ['Portatif Bar Dahil', 'Buz & Bardak Takımı Dahil'],
        'is_active': true,
        'type': 'bartender',
      },
      {
        'id': 'm202',
        'title': 'Classic & Vintage Prohibition Bar',
        'description': '1920\'lerin klasik reçetelerine dayanan Negroni, Manhattan ve French 75 gibi zamansız kokteyllerden oluşan şık vintage bar deneyimi.',
        'category': 'Classic & Vintage Bar',
        'price': 70.0,
        'min_limit': 2,
        'image': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=80',
        'items': [
          'Classic Aged Negroni',
          'Manhattan Special Blend',
          'French 75 & Champagne Flute',
          'Whiskey Sour with Velvet Foam',
        ],
        'tags': ['Portatif Bar Dahil'],
        'is_active': true,
        'type': 'bartender',
      },
    ];
  }

  Future<void> _fetchMenus() async {
    setState(() => _isLoading = true);
    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      if (user != null) {
        final fetched = await supabase.getProviderAllMenus(user.id);
        if (fetched.isNotEmpty) {
          final chefList = fetched.where((m) => m['type'] == 'chef' || m['type'] == null).toList();
          final bartenderList = fetched.where((m) => m['type'] == 'bartender').toList();
          if (chefList.isNotEmpty) _chefMenus = chefList;
          if (bartenderList.isNotEmpty) _mixologistMenus = bartenderList;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _currentMenuList {
    final list = _currentRole == 'bartender' ? _mixologistMenus : _chefMenus;
    if (_selectedFilter == 'active') {
      return list.where((m) => m['is_active'] == true).toList();
    } else if (_selectedFilter == 'inactive') {
      return list.where((m) => m['is_active'] == false).toList();
    }
    return list;
  }

  void _openEditorModal([Map<String, dynamic>? menu]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MenuEditorModal(
          existingMenu: menu,
          providerType: _currentRole,
          onSave: (updatedMenu) async {
            final messenger = ScaffoldMessenger.of(context);
            setState(() {
              final targetList = _currentRole == 'bartender' ? _mixologistMenus : _chefMenus;
              if (updatedMenu['id'] != null) {
                final idx = targetList.indexWhere((m) => m['id'] == updatedMenu['id']);
                if (idx != -1) {
                  targetList[idx] = updatedMenu;
                }
              } else {
                updatedMenu['id'] = 'm_${DateTime.now().millisecondsSinceEpoch}';
                targetList.insert(0, updatedMenu);
              }
            });

            // Sync to Supabase if logged in
            try {
              final supabase = SupabaseService();
              final user = supabase.currentUser;
              if (user != null) {
                final payload = Map<String, dynamic>.from(updatedMenu);
                payload['provider_id'] = user.id;
                if (updatedMenu['id'] != null && !updatedMenu['id'].toString().startsWith('m_')) {
                  await supabase.updateMenu(updatedMenu['id'], payload);
                } else {
                  await supabase.createMenu(payload);
                }
              }
            } catch (_) {}

            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    menu == null ? 'Yeni menü başarıyla yayınlandı!' : 'Menü değişiklikleri kaydedildi.',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _toggleActiveStatus(Map<String, dynamic> menu, bool val) async {
    setState(() {
      menu['is_active'] = val;
    });
    try {
      final supabase = SupabaseService();
      if (menu['id'] != null && !menu['id'].toString().startsWith('m_')) {
        await supabase.toggleMenuStatus(menu['id'], val);
      }
    } catch (_) {}
  }

  void _confirmDelete(Map<String, dynamic> menu) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Menüyü Sil',
            style: GoogleFonts.libreCaslonText(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '"${menu['title']}" menüsünü kalıcı olarak silmek istediğinizden emin misiniz?',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Vazgeç', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  if (_currentRole == 'bartender') {
                    _mixologistMenus.removeWhere((m) => m['id'] == menu['id']);
                  } else {
                    _chefMenus.removeWhere((m) => m['id'] == menu['id']);
                  }
                });
                try {
                  final supabase = SupabaseService();
                  if (menu['id'] != null && !menu['id'].toString().startsWith('m_')) {
                    await supabase.deleteMenu(menu['id']);
                  }
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Sil', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBartender = _currentRole == 'bartender';
    final activeCount = _currentMenuList.where((m) => m['is_active'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: widget.onBack,
        ),
        title: Text(
          isBartender ? 'Kokteyl & Bar Paketlerim' : 'Menülerim & Paketlerim',
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          // Switch Role Toggle
          IconButton(
            onPressed: () {
              setState(() {
                _currentRole = isBartender ? 'chef' : 'bartender';
              });
            },
            icon: Icon(
              isBartender ? Icons.restaurant_menu_rounded : Icons.local_bar_rounded,
              color: const Color(0xFF7B5800),
            ),
            tooltip: isBartender ? 'Şef Menülerine Geç' : 'Barmen Paketlerine Geç',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B5800)))
            : Column(
                children: [
                  // Top Summary & Add Action Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B5800).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isBartender ? Icons.local_bar_rounded : Icons.restaurant_menu_rounded,
                              color: const Color(0xFF7B5800),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBartender ? 'Barmen Kokteyl Kataloğu' : 'Şef Menü Kataloğu',
                                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                                ),
                                Text(
                                  '$activeCount Aktif Yayınlanan Paket',
                                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openEditorModal(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Yeni Ekle',
                              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B1C1C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter Chips (All, Active, Inactive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Tüm Paketler (${_currentMenuList.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('active', 'Aktif'),
                        const SizedBox(width: 8),
                        _buildFilterChip('inactive', 'Yayında Değil'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menus Cards List
                  Expanded(
                    child: _currentMenuList.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _currentMenuList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, idx) {
                              final menu = _currentMenuList[idx];
                              return _buildMenuCard(menu, isBartender);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7B5800) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B5800) : const Color(0xFFE4E2E2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF747878),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> menu, bool isBartender) {
    final bool isActive = menu['is_active'] ?? true;
    final List items = menu['items'] ?? [];
    final List tags = menu['tags'] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Badge & Price Tag
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  menu['image'] ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.restaurant_rounded, color: Colors.grey),
                  ),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // Category Tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    menu['category'] ?? (isBartender ? 'Craft Bar' : 'Tasting'),
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              // Price Tag
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B5800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isBartender ? '₺${menu['price']}/saat' : '₺${menu['price']} / kişi',
                    style: GoogleFonts.libreCaslonText(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        menu['title'] ?? '',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1C),
                        ),
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeThumbColor: const Color(0xFF7B5800),
                      onChanged: (val) => _toggleActiveStatus(menu, val),
                    ),
                  ],
                ),
                if (menu['description'] != null && menu['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    menu['description'],
                    style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878), height: 1.4),
                  ),
                ],
                const SizedBox(height: 12),

                // Items list chips
                if (items.isNotEmpty) ...[
                  Text(
                    isBartender ? 'Kokteyller & İkramlar' : 'Menü Aşamaları',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.take(4).map((it) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF7B5800)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                it.toString(),
                                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF1B1C1C)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Tags
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B5800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.toString(),
                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800)),
                        ),
                      );
                    }).toList(),
                  ),
                const Divider(height: 24, color: Color(0xFFE4E2E2)),

                // Actions Footer (Edit & Delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmDelete(menu),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                      label: Text('Sil', style: GoogleFonts.manrope(fontSize: 12, color: Colors.redAccent)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openEditorModal(menu),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: Text('Düzenle', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1C1C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentRole == 'bartender' ? Icons.local_bar_rounded : Icons.restaurant_menu_rounded,
            size: 48,
            color: const Color(0xFFA0A0A0),
          ),
          const SizedBox(height: 12),
          Text(
            'Henüz paket eklemediniz',
            style: GoogleFonts.libreCaslonText(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
          ),
          const SizedBox(height: 6),
          Text(
            'Misafirlerinize sunmak için ilk menünüzü veya kokteyl paketinizi ekleyin.',
            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openEditorModal(),
            icon: const Icon(Icons.add_rounded),
            label: Text('İlk Paketimi Ekle', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B5800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
