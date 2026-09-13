import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'controllers/provider_onboarding_controller.dart';
import '../domain/models/provider_onboarding_state.dart';

class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const ProviderOnboardingScreen({
    super.key,
    required this.onFinish,
    required this.onBack,
  });

  @override
  ConsumerState<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends ConsumerState<ProviderOnboardingScreen> {
  final _bioController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _educationController = TextEditingController();
  final _menuTitleController = TextEditingController();
  final _menuPriceController = TextEditingController(text: '1200');
  final _courseAppetizerController = TextEditingController();
  final _courseMainController = TextEditingController();
  final _courseDessertController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _ibanController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(providerOnboardingControllerProvider.notifier).loadExistingProfile();
      final state = ref.read(providerOnboardingControllerProvider);
      _firstNameController.text = state.firstName;
      _lastNameController.text = state.lastName;
      _phoneController.text = state.phone;
      _birthDateController.text = state.birthDate;
      _bioController.text = state.bio;
      _educationController.text = state.education;
      _menuTitleController.text = state.menuTitle;
      _courseAppetizerController.text = state.courseAppetizer;
      _courseMainController.text = state.courseMain;
      _courseDessertController.text = state.courseDessert;
      _accountHolderController.text = state.accountHolderName;
      _ibanController.text = state.iban;
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _educationController.dispose();
    _menuTitleController.dispose();
    _menuPriceController.dispose();
    _courseAppetizerController.dispose();
    _courseMainController.dispose();
    _courseDessertController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);
    final controller = ref.read(providerOnboardingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        automaticallyImplyLeading: false,
        leading: state.currentStep == 8
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () {
                  if (state.currentStep > 1) {
                    controller.prevStep();
                  } else {
                    widget.onBack();
                  }
                },
              ),
        title: Text(
          'Şef & Barmen Kaydı',
          style: GoogleFonts.libreCaslonText(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Taslak Kaydedildi',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADIM ${state.currentStep} / 8',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: const Color(0xFF747878),
                      ),
                    ),
                    Text(
                      _getStepTitle(state.currentStep),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B5800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: state.currentStep / 8.0,
                backgroundColor: const Color(0xFFE4E2E2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B1C1C)),
                minHeight: 3,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(state, controller),
              ),
            ),
            if (state.currentStep < 8) _buildBottomActionBar(state, controller),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Rol Seçimi';
      case 2:
        return 'Temel Profil';
      case 3:
        return 'Uzmanlık & Tercihler';
      case 4:
        return 'Hizmet Bölgesi & Lojistik';
      case 5:
        return 'Belge Doğrulaması';
      case 6:
        return 'Hızlı Hizmet Tanımı';
      case 7:
        return 'Kazanç & IBAN';
      case 8:
        return 'Başvuru Alındı';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1RoleSelection(state, controller);
      case 2:
        return _buildStep2BasicProfile(state, controller);
      case 3:
        return _buildStep3Expertise(state, controller);
      case 4:
        return _buildStep4Logistics(state, controller);
      case 5:
        return _buildStep5Verification(state, controller);
      case 6:
        return _buildStep6InitialMenu(state, controller);
      case 7:
        return _buildStep7PayoutInfo(state, controller);
      case 8:
        return _buildStep8SuccessPending(state, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // EKRAN 1: ROL SEÇİMİ
  // ---------------------------------------------------------------------------
  Widget _buildStep1RoleSelection(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platformda nasıl hizmet vermek istersiniz?',
          style: GoogleFonts.libreCaslonText(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.25,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Modern Epicurean topluluğuna katılmak için uzmanlık alanınızı seçin. Bu seçim, profilinizi ve sonraki soruları şekillendirecektir.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            height: 1.5,
            color: const Color(0xFF747878),
          ),
        ),
        const SizedBox(height: 28),

        // Role 1: Şef / Aşçı
        _buildRoleCard(
          title: 'Özel Şef / Aşçı',
          description: 'Kişiye özel menüler tasarlayın, özel etkinliklerde ve akşam yemeklerinde mutfak sanatınızı sergileyin.',
          emojiIcon: '🍳',
          isSelected: state.providerType == 'chef',
          onTap: () => controller.setRole('chef'),
        ),
        const SizedBox(height: 16),

        // Role 2: Barmen / Miksolojist
        _buildRoleCard(
          title: 'Barmen / Miksolojist',
          description: 'Özel kokteyller yaratın, davetlerde içki servisini yönetin ve unutulmaz bir bar deneyimi sunun.',
          emojiIcon: '🍸',
          isSelected: state.providerType == 'bartender',
          onTap: () => controller.setRole('bartender'),
        ),
        const SizedBox(height: 16),

        // Role 3: Her İkisi
        _buildRoleCard(
          title: 'Her İkisi (Mutfak & Bar)',
          description: 'Hem yemek hem de içki konusunda tam donanımlı bir deneyim sunarak etkinliklerin tüm kontrolünü elinize alın.',
          emojiIcon: '🌟',
          isSelected: state.providerType == 'both',
          onTap: () => controller.setRole('both'),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required String emojiIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B1C1C) : const Color(0xFFE4E2E2),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7B5800).withValues(alpha: 0.12)
                    : const Color(0xFFF3F3F3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emojiIcon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1C),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? const Color(0xFF1B1C1C) : const Color(0xFFC0C0C0),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.45,
                      color: const Color(0xFF747878),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 2: TEMEL PROFİL VE PROFESYONEL GEÇMİŞ
  // ---------------------------------------------------------------------------
  Widget _buildStep2BasicProfile(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temel Profil ve Profesyonel Geçmiş',
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Müşterilerinizin profilinizde göreceği vitrin bilgilerini girin.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
        ),
        const SizedBox(height: 24),

        // Profil Fotoğrafı Yükleme Alanı
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFEFEDED),
                    child: state.avatarUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(46),
                            child: Image.network(state.avatarUrl, fit: BoxFit.cover, width: 92, height: 92),
                          )
                        : const Icon(Icons.person_rounded, size: 48, color: Color(0xFF747878)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1B1C1C),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        onPressed: () {
                          // Simulating photo pick
                          controller.updateBasicProfile(
                            avatarUrl: 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=400',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B5800).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF7B5800)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Güleryüzlü ve profesyonel bir fotoğraf rezervasyon şansınızı %40 artırır.',
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF7B5800)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Form Fields
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Ad',
                hint: 'Örn. Caner',
                controller: _firstNameController,
                onChanged: (val) => controller.updateBasicProfile(firstName: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Soyad',
                hint: 'Örn. Yılmaz',
                controller: _lastNameController,
                onChanged: (val) => controller.updateBasicProfile(lastName: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Telefon Numarası',
                hint: '05XXXXXXXXX',
                keyboardType: TextInputType.number,
                controller: _phoneController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (val) => controller.updateBasicProfile(phone: val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Doğum Tarihi',
                hint: 'GG/AA/YYYY',
                keyboardType: TextInputType.number,
                controller: _birthDateController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DateInputFormatter(),
                ],
                onChanged: (val) => controller.updateBasicProfile(birthDate: val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bio (Min 50 char counter)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biyografi (Hakkımda)',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                ),
                Text(
                  '${state.bio.length}/50 min',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: state.bio.length >= 50 ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bioController,
              maxLines: 3,
              onChanged: (val) => controller.updateBasicProfile(bio: val),
              decoration: InputDecoration(
                hintText: 'Mutfak felsefenizi, deneyimlerinizi ve uzmanlıklarınızı özetleyen samimi ve profesyonel bir tanıtım yazısı yazın...',
                hintStyle: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFA0A0A0)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1C1C))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Deneyim Süresi Dropdown/Chips
        Text('Deneyim Süresi', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: ['1-3 yıl', '3-5 yıl', '5-10 yıl', '10+ yıl'].map((exp) {
            final isSel = state.experienceYears == exp;
            return ChoiceChip(
              label: Text(exp),
              selected: isSel,
              selectedColor: const Color(0xFF1B1C1C),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : const Color(0xFF1B1C1C),
              ),
              side: const BorderSide(color: Color(0xFFE4E2E2)),
              onSelected: (_) => controller.updateBasicProfile(experienceYears: exp),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Eğitim / Geçmiş Çalışma Yerleri
        _buildTextField(
          label: 'Eğitim / Geçmiş Çalışma Yerleri (Opsiyonel)',
          hint: 'Örn. Mutfak Sanatları Akademisi (MSA) / Lucca & Zuma İstanbul',
          controller: _educationController,
          onChanged: (val) => controller.updateBasicProfile(education: val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 3: UZMANLIK VE TERCİHLER (DİNAMİK)
  // ---------------------------------------------------------------------------
  Widget _buildStep3Expertise(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    final isChef = state.providerType == 'chef' || state.providerType == 'both';
    final isBartender = state.providerType == 'bartender' || state.providerType == 'both';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uzmanlık ve Tercihler',
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Müşterilerin filtreleme yaparken sizi kolayca bulmasını sağlayan etiketleri seçin.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
        ),
        const SizedBox(height: 24),

        // IF CHEF OR BOTH
        if (isChef) ...[
          Text('Mutfak Tipleri (Çoklu Seçim)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'İtalyan', 'Ege/Akdeniz', 'Uzak Doğu', 'Sushi', 'Barbekü/Et', 
              'Anadolu/Türk', 'Fine Dining', 'Pastacılık/Tatlı', 'Fransız', 'Meksika', 'Sokak Lezzetleri'
            ].map((cuisine) {
              final isSel = state.cuisineTypes.contains(cuisine);
              return FilterChip(
                label: Text(cuisine),
                selected: isSel,
                selectedColor: const Color(0xFF7B5800).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF7B5800),
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? const Color(0xFF7B5800) : const Color(0xFF1B1C1C),
                ),
                side: BorderSide(color: isSel ? const Color(0xFF7B5800) : const Color(0xFFE4E2E2)),
                onSelected: (_) => controller.toggleCuisineType(cuisine),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Text('Diyet Uzmanlıkları', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Vegan', 'Vejetaryen', 'Glütensiz', 'Ketojenik', 'Fit/Sporcu Beslenmesi', 'Laktozsuz', 'Pesketaryen'
            ].map((dietary) {
              final isSel = state.dietarySpecialties.contains(dietary);
              return FilterChip(
                label: Text(dietary),
                selected: isSel,
                selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF10B981),
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? const Color(0xFF10B981) : const Color(0xFF1B1C1C),
                ),
                side: BorderSide(color: isSel ? const Color(0xFF10B981) : const Color(0xFFE4E2E2)),
                onSelected: (_) => controller.toggleDietarySpecialty(dietary),
              );
            }).toList(),
          ),
          if (isBartender) const SizedBox(height: 28),
        ],

        // IF BARTENDER OR BOTH
        if (isBartender) ...[
          Text('Kokteyl Tarzları & Servis', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Klasik Kokteyller', 'İmza/Moleküler Miksoloji', 'Mocktail (Alkolsüz)', 
              'Şarap & Peynir Eşleşmesi', 'Craft Bira & Atıştırmalık', 'Tiki/Tropikal'
            ].map((style) {
              final isSel = state.cocktailStyles.contains(style);
              return FilterChip(
                label: Text(style),
                selected: isSel,
                selectedColor: const Color(0xFF1B1C1C),
                checkmarkColor: Colors.white,
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : const Color(0xFF1B1C1C),
                ),
                side: BorderSide(color: isSel ? const Color(0xFF1B1C1C) : const Color(0xFFE4E2E2)),
                onSelected: (_) => controller.toggleCocktailStyle(style),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Text('Ekipman Sahipliği', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E2E2)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Kendi shaker/bar aletleri setim var', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Jigger, süzgeç, muddle ve özel bar ekipmanları', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878))),
                  value: state.hasBarTools,
                  activeThumbColor: const Color(0xFF7B5800),
                  onChanged: (val) => controller.updateEquipment(hasBarTools: val),
                ),
                const Divider(color: Color(0xFFE4E2E2)),
                SwitchListTile(
                  title: Text('Taşınabilir mobil bar masam var', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('Açık hava ve ev davetlerine özel portatif kurulum', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878))),
                  value: state.hasMobileBar,
                  activeThumbColor: const Color(0xFF7B5800),
                  onChanged: (val) => controller.updateEquipment(hasMobileBar: val),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 4: HİZMET BÖLGESİ VE LOJİSTİK AYARLARI
  // ---------------------------------------------------------------------------
  Widget _buildStep4Logistics(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hizmet Bölgesi ve Lojistik Ayarları',
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Çalışabileceğiniz mesafe ve lojistik sınırlarını belirleyin.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
        ),
        const SizedBox(height: 24),

        // Hizmet Merkezi
        Text('Hizmet Merkezi (İl / İlçe)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCityPickerSheet(context, controller, state.cityRegion),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E2E2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF7B5800), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.cityRegion.isNotEmpty ? state.cityRegion : 'Tüm İl ve İlçelerde Ara / Seç',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: state.cityRegion.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            color: state.cityRegion.isNotEmpty ? const Color(0xFF1B1C1C) : const Color(0xFFA0A0A0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.search_rounded, color: Color(0xFF747878)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Hizmet Yarıçapı (Slider)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Hizmet Yarıçapı', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1C1C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${state.serviceRadiusKm.toInt()} km',
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Bulunduğum noktadan en fazla ${state.serviceRadiusKm.toInt()} km uzağa giderim.',
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878)),
              ),
              Slider(
                value: state.serviceRadiusKm,
                min: 5.0,
                max: 50.0,
                divisions: 9,
                activeColor: const Color(0xFF1B1C1C),
                inactiveColor: const Color(0xFFE4E2E2),
                onChanged: (val) => controller.updateLogistics(serviceRadiusKm: val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Kişi Kapasitesi Min & Max
        Text('Tek Seferde Kişi Kapasitesi', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCounterTile(
                label: 'Min Kişi',
                value: state.minGuests,
                onDecrement: () {
                  if (state.minGuests > 1) controller.updateLogistics(minGuests: state.minGuests - 1);
                },
                onIncrement: () => controller.updateLogistics(minGuests: state.minGuests + 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCounterTile(
                label: 'Max Kişi',
                value: state.maxGuests,
                onDecrement: () {
                  if (state.maxGuests > state.minGuests) controller.updateLogistics(maxGuests: state.maxGuests - 1);
                },
                onIncrement: () => controller.updateLogistics(maxGuests: state.maxGuests + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Ulaşım Şekli
        Text('Ulaşım Şekli', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'Kendi Aracım Var',
                icon: Icons.directions_car_rounded,
                isSelected: state.transportationMode == 'own_car',
                onTap: () => controller.updateLogistics(transportationMode: 'own_car'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                title: 'Toplu Taşıma',
                icon: Icons.directions_bus_rounded,
                isSelected: state.transportationMode == 'public_transit',
                onTap: () => controller.updateLogistics(transportationMode: 'public_transit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterTile({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2E2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
          Row(
            children: [
              InkWell(
                onTap: onDecrement,
                child: const CircleAvatar(radius: 12, backgroundColor: Color(0xFFEFEDED), child: Icon(Icons.remove, size: 14, color: Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$value', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              InkWell(
                onTap: onIncrement,
                child: const CircleAvatar(radius: 12, backgroundColor: Color(0xFF1B1C1C), child: Icon(Icons.add, size: 14, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B1C1C) : const Color(0xFFE4E2E2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF7B5800) : const Color(0xFF747878), size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF1B1C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 5: GÜVENLİK VE BELGE DOĞRULAMASI
  // ---------------------------------------------------------------------------
  Widget _buildStep5Verification(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Güvenlik ve Belge Doğrulaması',
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Müşteri güvenliği için belgelerinizi yükleyin. Yalnızca yetkili onay ekibimiz görür.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
        ),
        const SizedBox(height: 20),

        // Document 1: TC Kimlik
        _buildDocumentUploadCard(
          title: '1. T.C. Kimlik / Pasaport (Zorunlu)',
          subtitle: 'Ön ve arka yüz fotoğrafı (Yalnızca admin görür)',
          isMandatory: true,
          uploadedUrl: state.identityDocUrl,
          onUpload: () {
            controller.updateDocument(identityDocUrl: 'https://storage.gastrohost.app/identity_doc_sample.pdf');
          },
        ),
        const SizedBox(height: 14),

        // Document 2: Sabıka Kaydı
        _buildDocumentUploadCard(
          title: '2. Sabıka Kaydı Belgesi (Zorunlu)',
          subtitle: "e-Devlet'ten alınan karekodlu PDF belgesi",
          isMandatory: true,
          uploadedUrl: state.criminalRecordDocUrl,
          onUpload: () {
            controller.updateDocument(criminalRecordDocUrl: 'https://storage.gastrohost.app/sabika_kaydi_sample.pdf');
          },
        ),
        const SizedBox(height: 14),

        // Document 3: Hijyen Eğitimi
        _buildDocumentUploadCard(
          title: '3. Hijyen Eğitimi Belgesi (Zorunlu)',
          subtitle: 'MEB veya yetkili kurumlardan alınan hijyen sertifikası',
          isMandatory: true,
          uploadedUrl: state.hygieneCertDocUrl,
          onUpload: () {
            controller.updateDocument(hygieneCertDocUrl: 'https://storage.gastrohost.app/hijyen_cert_sample.pdf');
          },
        ),
        const SizedBox(height: 14),

        // Document 4: Aşçılık / Barmenlik Diploması (Rozet Kazandırır)
        _buildDocumentUploadCard(
          title: '4. Aşçılık/Barmenlik Diploması (Opsiyonel)',
          subtitle: 'MSA, MEB, WSET vb. belge yükleyenlere "Onaylı Profesyonel" rozeti verilir',
          isMandatory: false,
          hasBadgeBonus: true,
          uploadedUrl: state.diplomaDocUrl,
          onUpload: () {
            controller.updateDocument(diplomaDocUrl: 'https://storage.gastrohost.app/diploma_sample.pdf');
          },
        ),
        const SizedBox(height: 16),

        // Belgeleri Daha Sonra Yükle Option Card
        Material(
          color: const Color(0xFFFBF9F8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE4E2E2)),
          ),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Belge yükleme adımı ertelendi. Profilinizden dilediğiniz zaman belgelerinizi ekleyebilirsiniz.',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF7B5800),
                  duration: const Duration(seconds: 3),
                ),
              );
              controller.nextStep();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFF7B5800), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belgeleri Daha Sonra Yükle ve Devam Et',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                        ),
                        Text(
                          'Kayıt adımlarını tamamlayın, belgelerinizi daha sonra profilinizden yükleyin.',
                          style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878)),
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

        // Privacy Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Belgeleriniz KVKK kapsamında yalnızca onay ekibimizce doğrulanır, profilinizde müşterilere kesinlikle gösterilmez.',
                  style: GoogleFonts.manrope(fontSize: 11, height: 1.4, color: const Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required bool isMandatory,
    bool hasBadgeBonus = false,
    required String uploadedUrl,
    required VoidCallback onUpload,
  }) {
    final isUploaded = uploadedUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUploaded ? const Color(0xFF10B981) : const Color(0xFFE4E2E2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isUploaded ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFF3F3F3),
            child: Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF1B1C1C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C)),
                      ),
                    ),
                    if (hasBadgeBonus) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B5800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('🌟 Rozet', style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF747878)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onUpload,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: BorderSide(color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF1B1C1C)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isUploaded ? 'Yüklendi' : 'Yükle',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF1B1C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 6: İLK MENÜ VEYA SAATLİK HİZMET TANIMLAMA (OPSİYONEL)
  // ---------------------------------------------------------------------------
  Widget _buildStep6InitialMenu(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlk Hizmet / Menü Tanımlama',
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Onaylandıktan sonra hemen rezervasyon alabilmek için hızlı bir başlangıç menüsü ekleyin.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
        ),
        const SizedBox(height: 24),

        _buildTextField(
          label: 'Menü / Hizmet Adı',
          hint: state.providerType == 'bartender'
              ? 'Örn. 4 Saatlik İmza Kokteyl Servisi'
              : 'Örn. 3 Aşamalı Trüflü İtalyan Gecesi',
          controller: _menuTitleController,
          onChanged: (val) => controller.updateInitialMenu(title: val),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          label: 'Kişi Başı / Saatlik Fiyat (₺)',
          hint: '1200',
          keyboardType: TextInputType.number,
          controller: _menuPriceController,
          onChanged: (val) {
            final price = double.tryParse(val) ?? 1200.0;
            controller.updateInitialMenu(price: price);
          },
        ),
        const SizedBox(height: 16),

        Text('Menü / İkram İçeriği', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField(
          label: 'Başlangıç / İkram',
          hint: 'Örn. Burrata Caprese & Bruschetta',
          controller: _courseAppetizerController,
          onChanged: (val) => controller.updateInitialMenu(appetizer: val),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          label: 'Ana Yemek / Kokteyller',
          hint: 'Örn. Ev Yapımı Risotto alla Panna & Negroni',
          controller: _courseMainController,
          onChanged: (val) => controller.updateInitialMenu(mainCourse: val),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          label: 'Tatlı / İkram',
          hint: 'Örn. Geleneksel Tiramisu',
          controller: _courseDessertController,
          onChanged: (val) => controller.updateInitialMenu(dessert: val),
        ),
        const SizedBox(height: 20),

        // Malzeme Dahil mi?
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E2E2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Malzemeler Fiyata Dahil mi?', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Evet'),
                    selected: state.ingredientsIncluded,
                    selectedColor: const Color(0xFF1B1C1C),
                    labelStyle: TextStyle(color: state.ingredientsIncluded ? Colors.white : Colors.black),
                    onSelected: (_) => controller.updateInitialMenu(ingredientsIncluded: true),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Hayır'),
                    selected: !state.ingredientsIncluded,
                    selectedColor: const Color(0xFF1B1C1C),
                    labelStyle: TextStyle(color: !state.ingredientsIncluded ? Colors.white : Colors.black),
                    onSelected: (_) => controller.updateInitialMenu(ingredientsIncluded: false),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton.icon(
            onPressed: () {
              controller.updateInitialMenu(skipMenu: true);
              controller.nextStep();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF747878)),
            label: Text(
              'Şimdilik Atla, Profilimden Ekleyeceğim',
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF747878)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 7: KAZANÇ VE IBAN BİLGİLERİ
  // ---------------------------------------------------------------------------
  Widget _buildStep7PayoutInfo(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kazanç ve IBAN Bilgileri',
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tamamlanan hizmetlerin ödemeleri bu banka hesabına otomatik aktarılır.',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
        ),
        const SizedBox(height: 24),

        _buildTextField(
          label: 'Banka Hesap Sahibi Ad Soyad',
          hint: 'Profil adınızla birebir aynı olmalıdır',
          controller: _accountHolderController,
          onChanged: (val) => controller.updatePayoutInfo(accountHolderName: val),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          label: 'IBAN Numarası',
          hint: 'TRXX XXXX XXXX XXXX XXXX XXXX XX',
          controller: _ibanController,
          onChanged: (val) => controller.updatePayoutInfo(iban: val),
        ),
        const SizedBox(height: 24),

        Text('Vergi ve Şirket Durumu', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        _buildOptionCard(
          title: 'Şahıs / Limited Şirketim Var (Fatura Kesebilirim)',
          icon: Icons.business_rounded,
          isSelected: state.taxStatus == 'company',
          onTap: () => controller.updatePayoutInfo(taxStatus: 'company'),
        ),
        const SizedBox(height: 12),

        _buildOptionCard(
          title: 'Bireysel Hizmet Sağlayıcıyım (Gider Pusulası / Muafiyet)',
          icon: Icons.person_outline_rounded,
          isSelected: state.taxStatus == 'individual',
          onTap: () => controller.updatePayoutInfo(taxStatus: 'individual'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EKRAN 8: BAŞVURU ALINDI & ONAY BEKLEME EKRANI
  // ---------------------------------------------------------------------------
  Widget _buildStep8SuccessPending(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 54),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Harika! Başvurunuz Alındı 🎉',
          textAlign: TextAlign.center,
          style: GoogleFonts.libreCaslonText(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1C),
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ekibimiz belgelerinizi ve profilinizi 24-48 saat içinde inceleyip onaylayacaktır. Bu süre zarfında profilinizi tamamlayabilir veya menülerinizi zenginleştirebilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF747878),
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E2E2)),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Seçilen Rol', state.providerType.toUpperCase()),
              const Divider(color: Color(0xFFE4E2E2)),
              _buildSummaryRow('Hizmet Bölgesi', state.cityRegion),
              const Divider(color: Color(0xFFE4E2E2)),
              _buildSummaryRow('İnceleme Durumu', '24-48 Saat (Onay Bekliyor)', isStatus: true),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Müşteri gözünden profil önizleme modu aktif!')),
              );
            },
            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
            label: Text('Profilimi Önizle (Müşteri Gözünden)', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B1C1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              controller.goToStep(1);
            },
            icon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF7B5800)),
            label: Text(
              'Başvuru Bilgilerimi Düzenle',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF7B5800)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onFinish,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: Text('Şef Paneline Git', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFE4E2E2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF747878))),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isStatus ? const Color(0xFF7B5800) : const Color(0xFF1B1C1C),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E2E2))),
      ),
      child: Row(
        children: [
          if (state.currentStep > 1) ...[
            OutlinedButton(
              onPressed: () => controller.prevStep(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                side: const BorderSide(color: Color(0xFFE4E2E2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Geri', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleNextStep(state, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      state.currentStep == 7 ? 'Başvuruyu Tamamla ve Gönder' : 'Devam Et',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextStep(
    ProviderOnboardingState state,
    ProviderOnboardingController controller,
  ) async {
    // Step 1: Role Selection
    if (state.currentStep == 1) {
      if (state.providerType.isEmpty) {
        _showErrorSnackBar('Lütfen devam etmek için bir hizmet rolü seçin (Şef, Barmen veya Her İkisi).');
        return;
      }
    }

    // Step 2: Basic Profile
    if (state.currentStep == 2) {
      if (state.firstName.trim().isEmpty) {
        _showErrorSnackBar('Lütfen adınızı girin.');
        return;
      }
      if (state.lastName.trim().isEmpty) {
        _showErrorSnackBar('Lütfen soyadınızı girin.');
        return;
      }
      final phone = state.phone.trim();
      if (phone.isEmpty) {
        _showErrorSnackBar('Lütfen telefon numaranızı girin.');
        return;
      }
      if (!phone.startsWith('0')) {
        _showErrorSnackBar('Telefon numarası "0" ile başlamalıdır (Örn: 05551234567).');
        return;
      }
      if (phone.length != 11) {
        _showErrorSnackBar('Telefon numarası tam 11 haneli olmalıdır (Şu an: ${phone.length} hane).');
        return;
      }
      if (state.birthDate.trim().length < 10) {
        _showErrorSnackBar('Lütfen geçerli bir doğum tarihi girin (Örn: 08/10/2001).');
        return;
      }
      if (state.bio.trim().length < 50) {
        _showErrorSnackBar('Biyografi en az 50 karakter olmalıdır (Şu an: ${state.bio.trim().length} karakter).');
        return;
      }
    }

    // Step 3: Expertise
    if (state.currentStep == 3) {
      final bool hasCuisine = state.cuisineTypes.isNotEmpty;
      final bool hasCocktail = state.cocktailStyles.isNotEmpty;
      if (!hasCuisine && !hasCocktail) {
        _showErrorSnackBar('Lütfen en az 1 adet uzmanlık alanı veya kokteyl stili seçin.');
        return;
      }
    }

    // Step 4: Logistics & City Region
    if (state.currentStep == 4) {
      if (state.cityRegion.trim().isEmpty) {
        _showErrorSnackBar('Lütfen çalışacağınız hizmet merkezini (İl / İlçe) seçin.');
        return;
      }
    }

    // Step 5: Verification & Documents
    if (state.currentStep == 5) {
      final bool hasMandatoryDocs = state.identityDocUrl.isNotEmpty && state.criminalRecordDocUrl.isNotEmpty;
      if (!hasMandatoryDocs) {
        final bool? shouldSkip = await _showSkipDocumentsDialog(context);
        if (shouldSkip != true) {
          return;
        }
      }
    }

    // Step 6: Initial Menu
    if (state.currentStep == 6) {
      if (!state.skipMenu && state.menuTitle.trim().isEmpty) {
        _showErrorSnackBar('Lütfen menü başlığı girin veya "Menüyü Sonra Tanımla" seçeneğini işaretleyin.');
        return;
      }
    }

    // Step 7: Payout & IBAN
    if (state.currentStep == 7) {
      if (state.accountHolderName.trim().isEmpty) {
        _showErrorSnackBar('Lütfen hesap sahibi adını girin.');
        return;
      }
      if (state.iban.trim().length < 24) {
        _showErrorSnackBar('Lütfen geçerli bir IBAN numarası girin (Örn: TR12 3456...).');
        return;
      }

      setState(() => _isSubmitting = true);
      await controller.submitFinalApplication();
      setState(() => _isSubmitting = false);
      return;
    }

    controller.nextStep();
  }

  Future<bool?> _showSkipDocumentsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Belgeleri Daha Sonra Yükle',
            style: GoogleFonts.libreCaslonText(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'T.C. Kimlik veya Sabıka kaydı belgenizi henüz yüklemediniz. Başvurunuza devam edebilir, belgelerinizi daha sonra profil ayarlarınızdan tamamlayabilirsiniz.',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF747878)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Şimdi Yükle',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1C1C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Sonra Yükle ve İlerle',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1B1C1C))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: GoogleFonts.manrope(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFA0A0A0)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1C1C))),
          ),
        ),
      ],
    );
  }

  void _showCityPickerSheet(
    BuildContext context,
    ProviderOnboardingController controller,
    String currentCity,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CityPickerModal(
          currentCity: currentCity,
          onSelect: (selectedCity) {
            controller.updateLogistics(cityRegion: selectedCity);
          },
        );
      },
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CityPickerModal extends StatefulWidget {
  final String currentCity;
  final ValueChanged<String> onSelect;

  const _CityPickerModal({
    required this.currentCity,
    required this.onSelect,
  });

  @override
  State<_CityPickerModal> createState() => _CityPickerModalState();
}

class _CityPickerModalState extends State<_CityPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<String> _allTurkeyLocations = [
    'İstanbul - Kadıköy', 'İstanbul - Beşiktaş', 'İstanbul - Sarıyer', 'İstanbul - Üsküdar', 'İstanbul - Şişli',
    'İstanbul - Beyoğlu', 'İstanbul - Bakırköy', 'İstanbul - Ataşehir', 'İstanbul - Maltepe', 'İstanbul - Florya',
    'Ankara - Çankaya', 'Ankara - Yenimahalle', 'Ankara - Gölbaşı', 'Ankara - Keçiören', 'Ankara - İncek',
    'İzmir - Çeşme', 'İzmir - Alaçatı', 'İzmir - Urla', 'İzmir - Alsancak', 'İzmir - Karşıyaka',
    'Antalya - Kaş', 'Antalya - Muratpaşa', 'Antalya - Alanya', 'Antalya - Kemer', 'Antalya - Konyaaltı',
    'Muğla - Bodrum', 'Muğla - Marmaris', 'Muğla - Fethiye', 'Muğla - Datça', 'Muğla - Göcek',
    'Bursa - Nilüfer', 'Bursa - Osmangazi', 'Gaziantep - Şahinbey', 'Gaziantep - Şehitkamil', 'Trabzon - Ortahisar',
    'Eskişehir - Odunpazarı', 'Adana - Seyhan', 'Mersin - Yenişehir', 'Kocaeli - İzmit', 'Kayseri - Melikgazi',
    'Denizli - Pamukkale', 'Diyarbakır - Kayapınar', 'Samsun - Atakum', 'Konya - Selçuklu', 'Balıkesir - Ayvalık',
    'Çanakkale - Bozcaada', 'Nevşehir - Ürgüp', 'Rize - Merkez', 'Ordu - Altınordu', 'Sakarya - Serdivan',
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin', 'Aydın', 'Balıkesir',
    'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
    'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
    'Hakkari', 'Hatay', 'Isparta', 'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli',
    'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla', 'Muş',
    'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat',
    'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman',
    'Kırıkkale', 'Batman', 'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye', 'Düzce'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allTurkeyLocations.where((loc) {
      return loc.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final bool hasExactMatch = filtered.any((l) => l.toLowerCase() == _query.trim().toLowerCase());

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E2E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hizmet Merkezi Seçin (81 İl & İlçeler)',
            style: GoogleFonts.libreCaslonText(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B1C1C),
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val),
            style: GoogleFonts.manrope(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'İl veya İlçe Ara (Örn. Ankara, Çankaya, Bodrum)...',
              hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFA0A0A0)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF747878)),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFBF9F8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E2E2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B1C1C))),
            ),
          ),
          const SizedBox(height: 12),

          // List or Custom Value Option
          Expanded(
            child: ListView(
              children: [
                if (_query.trim().isNotEmpty && !hasExactMatch)
                  ListTile(
                    leading: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF7B5800)),
                    title: Text(
                      'Özel Konum Ekle: "${_searchController.text.trim()}"',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7B5800)),
                    ),
                    onTap: () {
                      widget.onSelect(_searchController.text.trim());
                      Navigator.pop(context);
                    },
                  ),
                ...filtered.map((location) {
                  final isSelected = location == widget.currentCity;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Icon(
                      Icons.location_on_rounded,
                      color: isSelected ? const Color(0xFF7B5800) : const Color(0xFF747878),
                    ),
                    title: Text(
                      location,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF7B5800) : const Color(0xFF1B1C1C),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7B5800), size: 18)
                        : null,
                    onTap: () {
                      widget.onSelect(location);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
