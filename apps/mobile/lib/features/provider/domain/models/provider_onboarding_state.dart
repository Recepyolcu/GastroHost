class ProviderOnboardingState {
  final int currentStep; // 1 to 8
  final String providerType; // 'chef', 'bartender', 'both'
  
  // Screen 2: Basic Profile
  final String avatarUrl;
  final String firstName;
  final String lastName;
  final String phone;
  final String birthDate;
  final String bio;
  final String experienceYears; // '1-3 yıl', '3-5 yıl', '5-10 yıl', '10+ yıl'
  final String education;

  // Screen 3: Expertise & Preferences
  final List<String> cuisineTypes;
  final List<String> dietarySpecialties;
  final List<String> cocktailStyles;
  final bool hasBarTools;
  final bool hasMobileBar;

  // Screen 4: Region & Logistics
  final String cityRegion;
  final double serviceRadiusKm;
  final int minGuests;
  final int maxGuests;
  final String transportationMode; // 'own_car', 'public_transit'

  // Screen 5: Security & Verification Documents
  final String identityDocUrl;
  final String criminalRecordDocUrl;
  final String hygieneCertDocUrl;
  final String diplomaDocUrl;

  // Screen 6: Initial Menu Setup
  final String menuTitle;
  final double menuPrice;
  final String courseAppetizer;
  final String courseMain;
  final String courseDessert;
  final bool ingredientsIncluded;
  final bool skipMenu;

  // Screen 7: Earnings & IBAN
  final String accountHolderName;
  final String iban;
  final String taxStatus; // 'company', 'individual'

  // Status
  final String onboardingStatus; // 'draft', 'pending_approval'

  const ProviderOnboardingState({
    this.currentStep = 1,
    this.providerType = 'chef',
    this.avatarUrl = '',
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.birthDate = '',
    this.bio = '',
    this.experienceYears = '3-5 yıl',
    this.education = '',
    this.cuisineTypes = const [],
    this.dietarySpecialties = const [],
    this.cocktailStyles = const [],
    this.hasBarTools = true,
    this.hasMobileBar = false,
    this.cityRegion = 'İstanbul - Kadıköy',
    this.serviceRadiusKm = 15.0,
    this.minGuests = 2,
    this.maxGuests = 20,
    this.transportationMode = 'own_car',
    this.identityDocUrl = '',
    this.criminalRecordDocUrl = '',
    this.hygieneCertDocUrl = '',
    this.diplomaDocUrl = '',
    this.menuTitle = '',
    this.menuPrice = 1200.0,
    this.courseAppetizer = '',
    this.courseMain = '',
    this.courseDessert = '',
    this.ingredientsIncluded = true,
    this.skipMenu = false,
    this.accountHolderName = '',
    this.iban = '',
    this.taxStatus = 'individual',
    this.onboardingStatus = 'draft',
  });

  ProviderOnboardingState copyWith({
    int? currentStep,
    String? providerType,
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? phone,
    String? birthDate,
    String? bio,
    String? experienceYears,
    String? education,
    List<String>? cuisineTypes,
    List<String>? dietarySpecialties,
    List<String>? cocktailStyles,
    bool? hasBarTools,
    bool? hasMobileBar,
    String? cityRegion,
    double? serviceRadiusKm,
    int? minGuests,
    int? maxGuests,
    String? transportationMode,
    String? identityDocUrl,
    String? criminalRecordDocUrl,
    String? hygieneCertDocUrl,
    String? diplomaDocUrl,
    String? menuTitle,
    double? menuPrice,
    String? courseAppetizer,
    String? courseMain,
    String? courseDessert,
    bool? ingredientsIncluded,
    bool? skipMenu,
    String? accountHolderName,
    String? iban,
    String? taxStatus,
    String? onboardingStatus,
  }) {
    return ProviderOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      providerType: providerType ?? this.providerType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      education: education ?? this.education,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      dietarySpecialties: dietarySpecialties ?? this.dietarySpecialties,
      cocktailStyles: cocktailStyles ?? this.cocktailStyles,
      hasBarTools: hasBarTools ?? this.hasBarTools,
      hasMobileBar: hasMobileBar ?? this.hasMobileBar,
      cityRegion: cityRegion ?? this.cityRegion,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      minGuests: minGuests ?? this.minGuests,
      maxGuests: maxGuests ?? this.maxGuests,
      transportationMode: transportationMode ?? this.transportationMode,
      identityDocUrl: identityDocUrl ?? this.identityDocUrl,
      criminalRecordDocUrl: criminalRecordDocUrl ?? this.criminalRecordDocUrl,
      hygieneCertDocUrl: hygieneCertDocUrl ?? this.hygieneCertDocUrl,
      diplomaDocUrl: diplomaDocUrl ?? this.diplomaDocUrl,
      menuTitle: menuTitle ?? this.menuTitle,
      menuPrice: menuPrice ?? this.menuPrice,
      courseAppetizer: courseAppetizer ?? this.courseAppetizer,
      courseMain: courseMain ?? this.courseMain,
      courseDessert: courseDessert ?? this.courseDessert,
      ingredientsIncluded: ingredientsIncluded ?? this.ingredientsIncluded,
      skipMenu: skipMenu ?? this.skipMenu,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      iban: iban ?? this.iban,
      taxStatus: taxStatus ?? this.taxStatus,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep,
      'providerType': providerType,
      'avatarUrl': avatarUrl,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'birthDate': birthDate,
      'bio': bio,
      'experienceYears': experienceYears,
      'education': education,
      'cuisineTypes': cuisineTypes,
      'dietarySpecialties': dietarySpecialties,
      'cocktailStyles': cocktailStyles,
      'hasBarTools': hasBarTools,
      'hasMobileBar': hasMobileBar,
      'cityRegion': cityRegion,
      'serviceRadiusKm': serviceRadiusKm,
      'minGuests': minGuests,
      'maxGuests': maxGuests,
      'transportationMode': transportationMode,
      'identityDocUrl': identityDocUrl,
      'criminalRecordDocUrl': criminalRecordDocUrl,
      'hygieneCertDocUrl': hygieneCertDocUrl,
      'diplomaDocUrl': diplomaDocUrl,
      'menuTitle': menuTitle,
      'menuPrice': menuPrice,
      'courseAppetizer': courseAppetizer,
      'courseMain': courseMain,
      'courseDessert': courseDessert,
      'ingredientsIncluded': ingredientsIncluded,
      'skipMenu': skipMenu,
      'accountHolderName': accountHolderName,
      'iban': iban,
      'taxStatus': taxStatus,
      'onboardingStatus': onboardingStatus,
    };
  }
}
