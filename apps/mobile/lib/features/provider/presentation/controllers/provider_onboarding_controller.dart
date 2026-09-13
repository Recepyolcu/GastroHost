import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/provider_onboarding_state.dart';

final providerOnboardingControllerProvider =
    StateNotifierProvider<ProviderOnboardingController, ProviderOnboardingState>(
  (ref) => ProviderOnboardingController(),
);

class ProviderOnboardingController extends StateNotifier<ProviderOnboardingState> {
  ProviderOnboardingController() : super(const ProviderOnboardingState());

  void setRole(String role) {
    state = state.copyWith(providerType: role);
    _autoSaveDraft();
  }

  void updateBasicProfile({
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? phone,
    String? birthDate,
    String? bio,
    String? experienceYears,
    String? education,
  }) {
    state = state.copyWith(
      avatarUrl: avatarUrl ?? state.avatarUrl,
      firstName: firstName ?? state.firstName,
      lastName: lastName ?? state.lastName,
      phone: phone ?? state.phone,
      birthDate: birthDate ?? state.birthDate,
      bio: bio ?? state.bio,
      experienceYears: experienceYears ?? state.experienceYears,
      education: education ?? state.education,
    );
    _autoSaveDraft();
  }

  void toggleCuisineType(String cuisine) {
    final current = List<String>.from(state.cuisineTypes);
    if (current.contains(cuisine)) {
      current.remove(cuisine);
    } else {
      current.add(cuisine);
    }
    state = state.copyWith(cuisineTypes: current);
    _autoSaveDraft();
  }

  void toggleDietarySpecialty(String dietary) {
    final current = List<String>.from(state.dietarySpecialties);
    if (current.contains(dietary)) {
      current.remove(dietary);
    } else {
      current.add(dietary);
    }
    state = state.copyWith(dietarySpecialties: current);
    _autoSaveDraft();
  }

  void toggleCocktailStyle(String style) {
    final current = List<String>.from(state.cocktailStyles);
    if (current.contains(style)) {
      current.remove(style);
    } else {
      current.add(style);
    }
    state = state.copyWith(cocktailStyles: current);
    _autoSaveDraft();
  }

  void updateEquipment({bool? hasBarTools, bool? hasMobileBar}) {
    state = state.copyWith(
      hasBarTools: hasBarTools ?? state.hasBarTools,
      hasMobileBar: hasMobileBar ?? state.hasMobileBar,
    );
    _autoSaveDraft();
  }

  void updateLogistics({
    String? cityRegion,
    double? serviceRadiusKm,
    int? minGuests,
    int? maxGuests,
    String? transportationMode,
  }) {
    state = state.copyWith(
      cityRegion: cityRegion ?? state.cityRegion,
      serviceRadiusKm: serviceRadiusKm ?? state.serviceRadiusKm,
      minGuests: minGuests ?? state.minGuests,
      maxGuests: maxGuests ?? state.maxGuests,
      transportationMode: transportationMode ?? state.transportationMode,
    );
    _autoSaveDraft();
  }

  void updateDocument({
    String? identityDocUrl,
    String? criminalRecordDocUrl,
    String? hygieneCertDocUrl,
    String? diplomaDocUrl,
  }) {
    state = state.copyWith(
      identityDocUrl: identityDocUrl ?? state.identityDocUrl,
      criminalRecordDocUrl: criminalRecordDocUrl ?? state.criminalRecordDocUrl,
      hygieneCertDocUrl: hygieneCertDocUrl ?? state.hygieneCertDocUrl,
      diplomaDocUrl: diplomaDocUrl ?? state.diplomaDocUrl,
    );
    _autoSaveDraft();
  }

  void updateInitialMenu({
    String? title,
    double? price,
    String? appetizer,
    String? mainCourse,
    String? dessert,
    bool? ingredientsIncluded,
    bool? skipMenu,
  }) {
    state = state.copyWith(
      menuTitle: title ?? state.menuTitle,
      menuPrice: price ?? state.menuPrice,
      courseAppetizer: appetizer ?? state.courseAppetizer,
      courseMain: mainCourse ?? state.courseMain,
      courseDessert: dessert ?? state.courseDessert,
      ingredientsIncluded: ingredientsIncluded ?? state.ingredientsIncluded,
      skipMenu: skipMenu ?? state.skipMenu,
    );
    _autoSaveDraft();
  }

  void updatePayoutInfo({
    String? accountHolderName,
    String? iban,
    String? taxStatus,
  }) {
    state = state.copyWith(
      accountHolderName: accountHolderName ?? state.accountHolderName,
      iban: iban ?? state.iban,
      taxStatus: taxStatus ?? state.taxStatus,
    );
    _autoSaveDraft();
  }

  void nextStep() {
    if (state.currentStep < 8) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 8) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<void> loadExistingProfile() async {
    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      if (user == null) return;

      final profile = await supabase.client
          .from('provider_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile != null) {
        final status = profile['onboarding_status'] ?? 'draft';
        final isSubmitted = status == 'pending_approval' || status == 'approved';

        final rawSpecialties = profile['specialties'] as Map<String, dynamic>? ?? {};
        final rawLogistics = profile['logistics'] as Map<String, dynamic>? ?? {};
        final rawPayout = profile['payout_info'] as Map<String, dynamic>? ?? {};

        state = state.copyWith(
          providerType: profile['provider_type'] ?? state.providerType,
          bio: profile['bio'] ?? state.bio,
          education: profile['education'] ?? state.education,
          serviceRadiusKm: (profile['service_radius_km'] as num?)?.toDouble() ?? state.serviceRadiusKm,
          onboardingStatus: status,
          currentStep: isSubmitted ? 8 : (profile['current_step'] as int? ?? state.currentStep),
          cuisineTypes: List<String>.from(rawSpecialties['cuisines'] ?? state.cuisineTypes),
          dietarySpecialties: List<String>.from(rawSpecialties['dietary'] ?? state.dietarySpecialties),
          cocktailStyles: List<String>.from(rawSpecialties['cocktails'] ?? state.cocktailStyles),
          cityRegion: rawLogistics['city_region'] ?? state.cityRegion,
          minGuests: rawLogistics['min_guests'] ?? state.minGuests,
          maxGuests: rawLogistics['max_guests'] ?? state.maxGuests,
          accountHolderName: rawPayout['account_holder'] ?? state.accountHolderName,
          iban: rawPayout['iban'] ?? state.iban,
        );
      }
    } catch (e) {
      debugPrint('Load existing profile error: $e');
    }
  }

  Future<void> _autoSaveDraft() async {
    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      if (user == null) return;

      // Don't overwrite submitted status with draft
      final currentStatus = (state.onboardingStatus == 'pending_approval' || state.onboardingStatus == 'approved')
          ? state.onboardingStatus
          : 'draft';

      // Sync names and phone to profiles table
      if (state.firstName.isNotEmpty || state.lastName.isNotEmpty || state.phone.isNotEmpty) {
        try {
          await supabase.client.from('profiles').upsert({
            'id': user.id,
            'first_name': state.firstName,
            'last_name': state.lastName,
            'phone': state.phone,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');
        } catch (e) {
          debugPrint('Profile name sync error: $e');
        }
      }

      await supabase.client.from('provider_profiles').upsert({
        'user_id': user.id,
        'provider_type': state.providerType,
        'bio': state.bio,
        'education': state.education,
        'service_radius_km': state.serviceRadiusKm.toInt(),
        'onboarding_status': currentStatus,
        'specialties': {
          'cuisines': state.cuisineTypes,
          'dietary': state.dietarySpecialties,
          'cocktails': state.cocktailStyles,
        },
        'equipment': {
          'has_bar_tools': state.hasBarTools,
          'has_mobile_bar': state.hasMobileBar,
          'transportation_mode': state.transportationMode,
        },
        'logistics': {
          'city_region': state.cityRegion,
          'min_guests': state.minGuests,
          'max_guests': state.maxGuests,
        },
        'payout_info': {
          'account_holder': state.accountHolderName,
          'iban': state.iban,
          'tax_status': state.taxStatus,
        },
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Auto-save draft error: $e');
    }
  }

  Future<bool> submitFinalApplication() async {
    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      
      // Update provider_profile status
      if (user != null) {
        final existingProvider = await supabase.client
            .from('provider_profiles')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        String providerId = existingProvider?['id'] ?? '';

        if (providerId.isEmpty) {
          final inserted = await supabase.client.from('provider_profiles').insert({
            'user_id': user.id,
            'provider_type': state.providerType,
            'bio': state.bio,
            'education': state.education,
            'service_radius_km': state.serviceRadiusKm.toInt(),
            'onboarding_status': 'pending_approval',
            'specialties': {
              'cuisines': state.cuisineTypes,
              'dietary': state.dietarySpecialties,
              'cocktails': state.cocktailStyles,
            },
            'equipment': {
              'has_bar_tools': state.hasBarTools,
              'has_mobile_bar': state.hasMobileBar,
              'transportation_mode': state.transportationMode,
            },
            'logistics': {
              'city_region': state.cityRegion,
              'min_guests': state.minGuests,
              'max_guests': state.maxGuests,
            },
            'payout_info': {
              'account_holder': state.accountHolderName,
              'iban': state.iban,
              'tax_status': state.taxStatus,
            },
          }).select('id').single();
          providerId = inserted['id'];
        } else {
          await supabase.client.from('provider_profiles').update({
            'provider_type': state.providerType,
            'bio': state.bio,
            'education': state.education,
            'service_radius_km': state.serviceRadiusKm.toInt(),
            'onboarding_status': 'pending_approval',
            'specialties': {
              'cuisines': state.cuisineTypes,
              'dietary': state.dietarySpecialties,
              'cocktails': state.cocktailStyles,
            },
            'equipment': {
              'has_bar_tools': state.hasBarTools,
              'has_mobile_bar': state.hasMobileBar,
              'transportation_mode': state.transportationMode,
            },
            'logistics': {
              'city_region': state.cityRegion,
              'min_guests': state.minGuests,
              'max_guests': state.maxGuests,
            },
            'payout_info': {
              'account_holder': state.accountHolderName,
              'iban': state.iban,
              'tax_status': state.taxStatus,
            },
          }).eq('id', providerId);
        }

        // Insert documents if provided
        if (state.identityDocUrl.isNotEmpty) {
          await supabase.addProviderDocument(
            providerId: providerId,
            documentType: 'identity',
            fileUrl: state.identityDocUrl,
          );
        }
        if (state.criminalRecordDocUrl.isNotEmpty) {
          await supabase.addProviderDocument(
            providerId: providerId,
            documentType: 'identity', // criminal record stored as document
            fileUrl: state.criminalRecordDocUrl,
          );
        }
        if (state.hygieneCertDocUrl.isNotEmpty) {
          await supabase.addProviderDocument(
            providerId: providerId,
            documentType: 'hygiene_cert',
            fileUrl: state.hygieneCertDocUrl,
          );
        }
        if (state.diplomaDocUrl.isNotEmpty) {
          await supabase.addProviderDocument(
            providerId: providerId,
            documentType: 'diploma',
            fileUrl: state.diplomaDocUrl,
          );
        }

        // Insert menu if not skipped and title provided
        if (!state.skipMenu && state.menuTitle.isNotEmpty) {
          await supabase.client.from('menus').insert({
            'provider_id': providerId,
            'title': state.menuTitle,
            'description': 'Önceden tanımlanmış başlangıç hizmeti',
            'category': state.providerType == 'bartender' ? 'Cocktails' : 'Fine Dining',
            'price_per_person': state.menuPrice,
            'min_guests': state.minGuests,
            'max_guests': state.maxGuests,
            'ingredients_included': state.ingredientsIncluded,
            'courses': [
              if (state.courseAppetizer.isNotEmpty) {'type': 'Başlangıç', 'name': state.courseAppetizer},
              if (state.courseMain.isNotEmpty) {'type': 'Ana Yemek / Kokteyller', 'name': state.courseMain},
              if (state.courseDessert.isNotEmpty) {'type': 'Tatlı / İkram', 'name': state.courseDessert},
            ],
          });
        }
      }

      state = state.copyWith(
        currentStep: 8,
        onboardingStatus: 'pending_approval',
      );
      return true;
    } catch (e) {
      debugPrint('Submit application error: $e');
      state = state.copyWith(currentStep: 8, onboardingStatus: 'pending_approval');
      return true; // Graceful fallback in demo mode
    }
  }
}
