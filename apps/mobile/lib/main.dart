import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/discovery/presentation/home_discovery_screen.dart';
import 'features/discovery/presentation/provider_detail_screen.dart';
import 'features/booking/presentation/booking_wizard_screen.dart';
import 'features/booking/presentation/booking_status_tracker_screen.dart';
import 'features/provider/presentation/provider_dashboard_screen.dart';
import 'features/provider/presentation/provider_onboarding_screen.dart';
import 'features/provider/presentation/provider_menu_management_screen.dart';
import 'features/admin/presentation/admin_approval_simulator_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

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

class GastroHostApp extends StatefulWidget {
  const GastroHostApp({super.key});

  @override
  State<GastroHostApp> createState() => _GastroHostAppState();
}

class _GastroHostAppState extends State<GastroHostApp> {
  // Navigation Flow State: 'login' -> 'home' -> 'detail' -> 'wizard' -> 'tracker' | 'provider_dashboard' | 'chat'
  String _currentScreen = 'home';

  Map<String, dynamic>? _selectedProvider;
  Map<String, dynamic>? _selectedMenu;
  String? _activeBookingId;

  // Chat Parameters
  String _chatBookingId = '';
  String _chatRecipientName = '';
  String _chatRecipientRole = 'chef';
  String _chatBackScreen = 'tracker';

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  void _checkActiveSession() async {
    try {
      final supabaseService = SupabaseService();
      final user = supabaseService.currentUser;
      if (user != null) {
        final role = user.userMetadata?['role'] ?? 'customer';
        if (role == 'chef') {
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
          setState(() => _currentScreen = 'home');
        }
      }
    } catch (_) {}
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
    final activeBody = _buildActiveScreenContent();

    return MaterialApp(
      title: 'GastroHost',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isMainCustomerTab()
          ? Scaffold(
              backgroundColor: const Color(0xFFFBF9F8),
              body: activeBody,
              bottomNavigationBar: _buildPersistentBottomNav(),
            )
          : activeBody,
    );
  }

  Widget _buildPersistentBottomNav() {
    final selectedIndex = _getNavIndex();

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E2E2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.explore_rounded, 'Explore', selectedIndex),
          _buildNavItem(1, Icons.calendar_today_outlined, 'Bookings', selectedIndex),
          _buildNavItem(2, Icons.chat_bubble_outline_rounded, 'Messages', selectedIndex),
          _buildNavItem(3, Icons.person_outline_rounded, 'Profile', selectedIndex),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int currentIndex) {
    final isSelected = currentIndex == index;
    return InkWell(
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
            color: isSelected ? Colors.black : const Color(0xFF747878),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : const Color(0xFF747878),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveScreenContent() {
    switch (_currentScreen) {
      case 'login':
        return LoginScreen(
          onLoginSuccess: (role, {bool isSignUp = false}) async {
            if (role == 'chef') {
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
        );
      case 'wizard':
        if (_selectedProvider == null || _selectedMenu == null) {
          return HomeDiscoveryScreen(
            onSelectMenu: (_, __) {},
            onTapProfile: () {
              setState(() => _currentScreen = 'profile');
            },
          );
        }
        return BookingWizardScreen(
          provider: _selectedProvider!,
          menu: _selectedMenu!,
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
        return BookingStatusTrackerScreen(
          bookingId: _activeBookingId,
          onBackToHome: () {
            setState(() => _currentScreen = 'home');
          },
          onOpenChat: () {
            setState(() {
              _chatBookingId = _activeBookingId ?? 'demo_booking_123';
              _chatRecipientName = _selectedProvider?['name'] ?? 'Şef Marco';
              _chatRecipientRole = 'chef';
              _chatBackScreen = 'tracker';
              _currentScreen = 'chat';
            });
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
        return ChatScreen(
          bookingId: _chatBookingId,
          recipientName: _chatRecipientName,
          recipientRole: _chatRecipientRole,
          onBack: () {
            setState(() {
              _currentScreen = _chatBackScreen;
            });
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
