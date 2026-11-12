import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/discovery/presentation/home_discovery_screen.dart';
import 'features/discovery/presentation/provider_detail_screen.dart';
import 'features/discovery/presentation/chef_profile_screen.dart';
import 'features/booking/presentation/booking_wizard_screen.dart';
import 'features/booking/presentation/booking_status_tracker_screen.dart';
import 'features/provider/presentation/provider_dashboard_screen.dart';
import 'features/provider/presentation/provider_onboarding_screen.dart';
import 'features/provider/presentation/provider_menu_management_screen.dart';
import 'features/admin/presentation/admin_approval_simulator_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/providers/booking_provider.dart';

import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase configuration placeholder detected. Running in Demo Mode: $e');
  }
  runApp(const ProviderScope(child: GastroHostApp()));
}

class GastroHostApp extends ConsumerStatefulWidget {
  const GastroHostApp({super.key});

  @override
  ConsumerState<GastroHostApp> createState() => _GastroHostAppState();
}

class _GastroHostAppState extends ConsumerState<GastroHostApp> {
  // Navigation Flow State: 'login' -> 'home' -> 'detail' -> 'wizard' -> 'tracker' | 'provider_dashboard' | 'chat'
  String _currentScreen = 'home';

  Map<String, dynamic>? _selectedProvider;
  Map<String, dynamic>? _selectedMenu;
  String? _activeBookingId;

  // Chef Profile Navigation State
  Map<String, dynamic>? _selectedProfileProvider;
  String _profileBackScreen = 'home';
  DateTime? _wizardSelectedDate;

  // Chat Parameters
  String _chatBookingId = '';
  String _chatRecipientName = '';
  String _chatRecipientRole = 'chef';
  String _chatBackScreen = 'tracker';

  void _openChefProfile(Map<String, dynamic> provider, {String? backScreen}) {
    setState(() {
      _selectedProfileProvider = provider;
      _profileBackScreen = backScreen ?? _currentScreen;
      _currentScreen = 'chef_profile';
    });
  }

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  void _checkActiveSession() async {
    try {
      final supabaseService = SupabaseService();
      final session = supabaseService.currentSession;
      if (session != null && session.isExpired) {
        debugPrint('Active session expired and host unreachable. Purging local session.');
        await supabaseService.clearLocalSession();
        return;
      }

      final user = supabaseService.currentUser;
      if (user != null) {
        final role = user.userMetadata?['role'] ?? 'customer';
        if (role == 'chef' || role == 'bartender') {
          final profile = await supabaseService.client
              .from('provider_profiles')
              .select('onboarding_status')
              .eq('user_id', user.id)
              .maybeSingle();

          final status = profile?['onboarding_status'];
          if (status == 'approved' || status == 'pending_approval') {
            setState(() => _currentScreen = 'provider_dashboard');
          } else {
            setState(() => _currentScreen = 'provider_onboarding');
          }
        } else if (role == 'admin') {
          setState(() => _currentScreen = 'admin_approval_simulator');
        } else {
          setState(() => _currentScreen = 'home');
        }
      }
    } catch (e) {
      debugPrint('Supabase session check error, clearing stale session: $e');
      try {
        await SupabaseService().clearLocalSession();
      } catch (_) {}
    }
  }

  int _getNavIndex() {
    switch (_currentScreen) {
      case 'home':
        return 0;
      case 'tracker':
        return 1;
      case 'chat':
        return 2;
      case 'profile':
        return 3;
      default:
        return 0;
    }
  }

  bool _isMainCustomerTab() {
    return ['home', 'tracker', 'chat', 'profile'].contains(_currentScreen);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final activeBody = _buildActiveScreenContent();
    final isDark = settings.isDarkMode;

    return MaterialApp(
      title: 'GastroHost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: _isMainCustomerTab()
          ? Scaffold(
              backgroundColor: isDark ? const Color(0xFF121417) : const Color(0xFFFBF9F8),
              body: activeBody,
              bottomNavigationBar: _buildPersistentBottomNav(isDark),
            )
          : activeBody,
    );
  }

  Widget _buildPersistentBottomNav(bool isDark) {
    final selectedIndex = _getNavIndex();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D22) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF282D35) : const Color(0xFFE4E2E2),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _buildNavItem(0, Icons.explore_rounded, 'Explore', selectedIndex, isDark),
              _buildNavItem(1, Icons.calendar_today_outlined, 'Bookings', selectedIndex, isDark),
              _buildNavItem(2, Icons.chat_bubble_outline_rounded, 'Messages', selectedIndex, isDark),
              _buildNavItem(3, Icons.person_outline_rounded, 'Profile', selectedIndex, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int currentIndex, bool isDark) {
    final isSelected = currentIndex == index;
    final selectedColor = isDark ? const Color(0xFFFDC34D) : Colors.black;
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF747878);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            switch (index) {
              case 0:
                _currentScreen = 'home';
                break;
              case 1:
                _currentScreen = 'tracker';
                break;
              case 2:
                _currentScreen = 'chat';
                break;
              case 3:
                _currentScreen = 'profile';
                break;
            }
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScreenContent() {
    switch (_currentScreen) {
      case 'login':
        return LoginScreen(
          onLoginSuccess: (role, {bool isSignUp = false}) async {
            if (role == 'chef' || role == 'bartender') {
              if (isSignUp) {
                // New registration -> MUST complete 8-step onboarding wizard first!
                setState(() {
                  _currentScreen = 'provider_onboarding';
                });
              } else {
                try {
                  final supabaseService = SupabaseService();
                  final user = supabaseService.currentUser;
                  if (user != null) {
                    final profile = await supabaseService.client
                        .from('provider_profiles')
                        .select('onboarding_status')
                        .eq('user_id', user.id)
                        .maybeSingle();

                    final status = profile?['onboarding_status'];
                    if (status == 'approved' || status == 'pending_approval') {
                      setState(() => _currentScreen = 'provider_dashboard');
                    } else {
                      setState(() => _currentScreen = 'provider_onboarding');
                    }
                  } else {
                    setState(() => _currentScreen = 'provider_dashboard');
                  }
                } catch (_) {
                  setState(() => _currentScreen = 'provider_dashboard');
                }
              }
            } else if (role == 'admin') {
              setState(() => _currentScreen = 'admin_approval_simulator');
            } else {
              setState(() => _currentScreen = 'home');
            }
          },
        );
      case 'home':
        return HomeDiscoveryScreen(
          onSelectMenu: (provider, menu) {
            setState(() {
              _selectedProvider = provider;
              _selectedMenu = menu;
              _currentScreen = 'detail';
            });
          },
          onTapChefProfile: (provider) {
            _openChefProfile(provider, backScreen: 'home');
          },
          onTapProfile: () {
            setState(() {
              _currentScreen = 'profile';
            });
          },
          onTapBookings: () {
            setState(() {
              _currentScreen = 'tracker';
            });
          },
          onTapMessages: () {
            setState(() {
              _currentScreen = 'chat';
            });
          },
        );
      case 'detail':
        if (_selectedProvider == null) {
          return HomeDiscoveryScreen(
            onSelectMenu: (_, __) {},
            onTapProfile: () {
              setState(() => _currentScreen = 'profile');
            },
            onTapChefProfile: (p) => _openChefProfile(p, backScreen: 'home'),
          );
        }
        return ProviderDetailScreen(
          provider: _selectedProvider!,
          onStartBooking: () {
            setState(() => _currentScreen = 'wizard');
          },
          onBack: () {
            setState(() => _currentScreen = 'home');
          },
          onOpenChefProfile: (provider) {
            _openChefProfile(provider, backScreen: 'detail');
          },
        );
      case 'chef_profile':
        final prov = _selectedProfileProvider ?? _selectedProvider ?? {
          'id': 'p1',
          'name': 'Chef Julian',
          'role': 'Executive Chef',
          'rating': '4.9',
          'image': 'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=800&auto=format&fit=crop&q=80',
          'provider_type': 'chef',
        };
        return ChefProfileScreen(
          provider: prov,
          onBack: () {
            setState(() => _currentScreen = _profileBackScreen);
          },
          onStartBooking: () {
            setState(() {
              _selectedProvider = prov;
              _selectedMenu = {
                'id': 'm_${prov['id'] ?? 'default'}',
                'title': '${prov['name'] ?? 'Şef'} İmza Deneyimi',
              };
              _wizardSelectedDate = null;
              _currentScreen = 'wizard';
            });
          },
          onStartBookingWithDate: (selectedDate) {
            setState(() {
              _selectedProvider = prov;
              _selectedMenu = {
                'id': 'm_${prov['id'] ?? 'default'}',
                'title': '${prov['name'] ?? 'Şef'} İmza Deneyimi',
              };
              _wizardSelectedDate = selectedDate;
              _currentScreen = 'wizard';
            });
          },
          onOpenChat: () {
            setState(() {
              _chatBookingId = _activeBookingId ?? 'GH-94821';
              _chatRecipientName = prov['name'] ?? 'Chef Julian';
              _chatRecipientRole = prov['role'] ?? 'Executive Chef';
              _chatBackScreen = 'chef_profile';
              _currentScreen = 'chat';
            });
          },
        );
      case 'wizard':
        if (_selectedProvider == null || _selectedMenu == null) {
          return HomeDiscoveryScreen(
            onSelectMenu: (_, __) {},
            onTapProfile: () {
              setState(() => _currentScreen = 'profile');
            },
            onTapChefProfile: (p) => _openChefProfile(p, backScreen: 'home'),
          );
        }
        return BookingWizardScreen(
          provider: _selectedProvider!,
          menu: _selectedMenu!,
          initialDate: _wizardSelectedDate,
          onBookingComplete: (bookingId) {
            setState(() {
              _activeBookingId = bookingId;
              _currentScreen = 'tracker';
            });
          },
          onBack: () {
            setState(() => _currentScreen = 'detail');
          },
        );
      case 'tracker':
        final bookingState = ref.watch(bookingProvider);
        final activeBooking = _activeBookingId != null
            ? bookingState.bookings.firstWhere(
                (b) => b.id == _activeBookingId,
                orElse: () => bookingState.activeBooking ?? bookingState.bookings.first,
              )
            : bookingState.activeBooking;

        return BookingStatusTrackerScreen(
          bookingId: _activeBookingId,
          onBackToHome: () {
            setState(() => _currentScreen = 'home');
          },
          onOpenChat: () {
            setState(() {
              _chatBookingId = _activeBookingId ?? activeBooking?.id ?? 'GH-94821';
              _chatRecipientName = activeBooking?.providerName ?? _selectedProvider?['name'] ?? 'Chef Julian';
              _chatRecipientRole = (activeBooking?.isHourly ?? false) ? 'bartender' : 'chef';
              _chatBackScreen = 'tracker';
              _currentScreen = 'chat';
            });
          },
          onOpenChefProfile: (provider) {
            _openChefProfile(provider, backScreen: 'tracker');
          },
        );
      case 'provider_dashboard':
        return ProviderDashboardScreen(
          onSwitchToCustomer: () {
            setState(() {
              _currentScreen = 'home';
            });
          },
          onManageMenus: () {
            setState(() {
              _currentScreen = 'provider_menu_management';
            });
          },
          onOpenChat: (bookingId, customerName) {
            setState(() {
              _chatBookingId = bookingId;
              _chatRecipientName = customerName;
              _chatRecipientRole = 'customer';
              _chatBackScreen = 'provider_dashboard';
              _currentScreen = 'chat';
            });
          },
        );
      case 'chat':
        final bookingState = ref.watch(bookingProvider);
        final activeBooking = _activeBookingId != null
            ? bookingState.bookings.firstWhere(
                (b) => b.id == _activeBookingId,
                orElse: () => bookingState.activeBooking ?? bookingState.bookings.first,
              )
            : bookingState.activeBooking;

        return ChatScreen(
          bookingId: _chatBookingId.isNotEmpty
              ? _chatBookingId
              : (activeBooking?.id ?? 'GH-94821'),
          recipientName: _chatRecipientName.isNotEmpty
              ? _chatRecipientName
              : (activeBooking?.providerName ?? 'Chef Julian'),
          recipientRole: _chatRecipientRole.isNotEmpty
              ? _chatRecipientRole
              : (activeBooking?.providerRole ?? 'Executive Chef'),
          onBack: () {
            setState(() {
              _currentScreen = _chatBackScreen;
            });
          },
          onOpenChefProfile: (provider) {
            _openChefProfile(provider, backScreen: 'chat');
          },
        );
      case 'provider_onboarding':
        return ProviderOnboardingScreen(
          onFinish: () {
            setState(() {
              _currentScreen = 'provider_dashboard';
            });
          },
          onBack: () {
            setState(() {
              _currentScreen = 'profile';
            });
          },
        );
      case 'provider_menu_management':
        return ProviderMenuManagementScreen(
          onBack: () {
            setState(() {
              _currentScreen = 'provider_dashboard';
            });
          },
        );
      case 'profile':
        return ProfileScreen(
          onBack: () {
            setState(() {
              _currentScreen = 'home';
            });
          },
          onLogout: () {
            setState(() {
              _currentScreen = 'login';
            });
          },
          onSwitchToChef: () {
            setState(() {
              _currentScreen = 'provider_dashboard';
            });
          },
          onStartChefOnboarding: () {
            setState(() {
              _currentScreen = 'provider_onboarding';
            });
          },
          onManageMenus: () {
            setState(() {
              _currentScreen = 'provider_menu_management';
            });
          },
          onOpenAdminSimulator: () {
            setState(() {
              _currentScreen = 'admin_approval_simulator';
            });
          },
          onOpenSettings: () {
            setState(() {
              _currentScreen = 'settings';
            });
          },
        );
      case 'settings':
        return SettingsScreen(
          onBack: () {
            setState(() {
              _currentScreen = 'profile';
            });
          },
        );
      case 'admin_approval_simulator':
        return AdminApprovalSimulatorScreen(
          onBack: () {
            setState(() {
              _currentScreen = 'profile';
            });
          },
        );
      default:
        return LoginScreen(onLoginSuccess: (_, {bool isSignUp = false}) {});
    }
  }
}
