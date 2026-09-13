import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuEditorModal extends StatefulWidget {
  final Map<String, dynamic>? existingMenu;
  final String providerType; // 'chef' or 'bartender'
  final ValueChanged<Map<String, dynamic>> onSave;

  const MenuEditorModal({
    super.key,
    this.existingMenu,
    required this.providerType,
    required this.onSave,
  });

  @override
  State<MenuEditorModal> createState() => _MenuEditorModalState();
}

class _MenuEditorModalState extends State<MenuEditorModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _minLimitController;
  late TextEditingController _customImageController;

  late String _selectedCategory;
  late String _selectedImage;
  late List<String> _items;
  late bool _isGlutenFree;
  late bool _isVegan;
  late bool _includesEquipment;

  static const List<String> _chefCategories = [
    'Fine Dining & Tasting',
    'Modern Ege & Akdeniz',
    'Osmanlı & Anadolu',
    'Asya & Fusion',
    'İtalyan & Pasta Artisanal',
    'BBQ & Izgara Özel',
  ];

  static const List<String> _bartenderCategories = [
    'Signature Craft Cocktails',
    'Classic & Vintage Bar',
    'Botanical & Infusion Bar',
    'Tiki & Tropical Party',
    'Mocktail & Non-Alcoholic Artisanal',
    'Molecular Mixology Show',
  ];

  static const List<String> _presetFoodImages = [
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80', // Steak / Fine dining
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80', // Gourmet dish
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800&q=80', // Salad bowl
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80', // Gourmet pizza
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80', // Salad / healthy
    'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=80', // Dessert
  ];

  static const List<String> _presetCocktailImages = [
    'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800&q=80', // Old Fashioned
    'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=80', // Cocktail glass
    'https://images.unsplash.com/photo-1536935338788-846bb9981813?w=800&q=80', // Tropical drink
    'https://images.unsplash.com/photo-1560512823-829485b8bf24?w=800&q=80', // Gin Tonic
    'https://images.unsplash.com/photo-1574096079513-d8259312b785?w=800&q=80', // Whiskey Sour
    'https://images.unsplash.com/photo-1517685352821-92cf88aee5a5?w=800&q=80', // Espresso Martini
  ];

  @override
  void initState() {
    super.initState();
    final isBartender = widget.providerType == 'bartender';
    final menu = widget.existingMenu;

    _titleController = TextEditingController(text: menu?['title'] ?? '');
    _descriptionController = TextEditingController(text: menu?['description'] ?? '');
    _priceController = TextEditingController(
      text: menu?['price']?.toString() ?? (isBartender ? '80' : '1200'),
    );
    _minLimitController = TextEditingController(
      text: menu?['min_limit']?.toString() ?? (isBartender ? '2' : '4'),
    );
    _customImageController = TextEditingController(text: menu?['image'] ?? '');

    final categories = isBartender ? _bartenderCategories : _chefCategories;
    _selectedCategory = menu?['category'] ?? categories.first;

    final defaultImages = isBartender ? _presetCocktailImages : _presetFoodImages;
    _selectedImage = menu?['image'] ?? defaultImages.first;

    _items = List<String>.from(menu?['items'] ?? [
      if (isBartender) ...[
        'Smoked Rosemary Old Fashioned',
        'Passionfruit & Basil Spritz',
        'Artisanal Craft Mocktail',
      ] else ...[
        'Başlangıç: Ege Otlu Burrata',
        'Ana Yemek: Ağır Ateşte Dana Yanak',
        'Tatlı: İncir & Çam Fıstıklı Uyutma',
      ]
    ]);

    final tags = List<String>.from(menu?['tags'] ?? []);
    _isGlutenFree = tags.contains('Glutensiz');
    _isVegan = tags.contains('Vegan');
    _includesEquipment = tags.contains('Ekipman Dahil') || tags.contains('Portatif Bar Dahil');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _minLimitController.dispose();
    _customImageController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add('');
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen menü başlığı girin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final minLimit = int.tryParse(_minLimitController.text.trim()) ?? 1;

    final isBartender = widget.providerType == 'bartender';
    final List<String> tags = [
      if (_isGlutenFree) 'Glutensiz',
      if (_isVegan) 'Vegan',
      if (_includesEquipment) (isBartender ? 'Portatif Bar Dahil' : 'Mutfak Ekipmanı Dahil'),
    ];

    final imageUrl = _customImageController.text.trim().isNotEmpty
        ? _customImageController.text.trim()
        : _selectedImage;

    final updatedMenu = {
      if (widget.existingMenu?['id'] != null) 'id': widget.existingMenu!['id'],
      'title': title,
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'price': price,
      'min_limit': minLimit,
      'image': imageUrl,
      'items': _items.where((it) => it.trim().isNotEmpty).toList(),
      'tags': tags,
      'is_active': widget.existingMenu?['is_active'] ?? true,
      'type': widget.providerType,
    };

    widget.onSave(updatedMenu);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBartender = widget.providerType == 'bartender';
    final categories = isBartender ? _bartenderCategories : _chefCategories;
    final presetImages = isBartender ? _presetCocktailImages : _presetFoodImages;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFFBF9F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isBartender ? Icons.local_bar_rounded : Icons.restaurant_menu_rounded,
                      color: const Color(0xFF7B5800),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.existingMenu == null
                          ? (isBartender ? 'Yeni Kokteyl Bar Paketi Ekle' : 'Yeni Menü Ekle')
                          : (isBartender ? 'Kokteyl Paketini Düzenle' : 'Menüyü Düzenle'),
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1C),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF747878)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E2E2)),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Title
                  Text('Menü / Paket Başlığı', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.manrope(fontSize: 14),
                    decoration: _inputDecoration(
                      hint: isBartender ? 'Örn: Signature Craft Cocktail Tasting Bar' : 'Örn: Ege Otları & Deniz Mahsulleri Tadım Menüsü',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category & Style
                  Text('Kategori & Konsept', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                    decoration: _inputDecoration(hint: 'Kategori Seçin'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.manrope(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Limits Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBartender ? 'Saatlik Ücret (₺)' : 'Kişi Başı Ücret (₺)',
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.manrope(fontSize: 14),
                              decoration: _inputDecoration(hint: '1200'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBartender ? 'Min. Süre (Saat)' : 'Min. Davetli Sayısı',
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _minLimitController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.manrope(fontSize: 14),
                              decoration: _inputDecoration(hint: '4'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text('Menü/Paket Açıklaması', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.manrope(fontSize: 13),
                    decoration: _inputDecoration(
                      hint: 'Menünüzün konseptini, kullanılan taze malzemeleri ve öne çıkan lezzet hikayesini özetleyin...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cover Image Picker
                  Text('Kapak Görseli Seçin', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: presetImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final imgUrl = presetImages[idx];
                        final isSelected = _selectedImage == imgUrl;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedImage = imgUrl),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF7B5800) : Colors.transparent,
                                width: 3,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(imgUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: isSelected
                                ? const Center(child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 24))
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Items List (Courses or Cocktail List)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isBartender ? 'Kokteyl & İkram Listesi' : 'Menü Aşamaları (Courses)',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF7B5800)),
                        label: Text(
                          'Öğe Ekle',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final text = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: text)..selection = TextSelection.collapsed(offset: text.length),
                              onChanged: (val) => _items[idx] = val,
                              style: GoogleFonts.manrope(fontSize: 13),
                              decoration: _inputDecoration(
                                hint: isBartender ? 'Örn: Smoked Rosemary Old Fashioned' : 'Örn: Başlangıç: Burrata & İncir',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeItem(idx),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Feature Checkboxes / Tags
                  Text('Özellikler & Etiketler', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _isGlutenFree,
                        label: Text('Glutensiz Seçenek', style: GoogleFonts.manrope(fontSize: 12)),
                        onSelected: (val) => setState(() => _isGlutenFree = val),
                        selectedColor: const Color(0xFF7B5800).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF7B5800),
                      ),
                      FilterChip(
                        selected: _isVegan,
                        label: Text('Vegan Uyumlu', style: GoogleFonts.manrope(fontSize: 12)),
                        onSelected: (val) => setState(() => _isVegan = val),
                        selectedColor: const Color(0xFF7B5800).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF7B5800),
                      ),
                      FilterChip(
                        selected: _includesEquipment,
                        label: Text(
                          isBartender ? 'Portatif Bar Dahil' : 'Mutfak Ekipmanı Dahil',
                          style: GoogleFonts.manrope(fontSize: 12),
                        ),
                        onSelected: (val) => setState(() => _includesEquipment = val),
                        selectedColor: const Color(0xFF7B5800).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF7B5800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.existingMenu == null ? 'Menüyü Kaydet ve Yayınla' : 'Değişiklikleri Kaydet',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFA0A0A0)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1C1C))),
    );
  }
}
