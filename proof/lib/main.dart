import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/proof_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_dashboard.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'services/preferences_service.dart';
import 'services/notification_service.dart';

import 'screens/splash/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/proof/pin_verification_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Timezone
    tz.initializeTimeZones();

    // Initialize SharedPreferences
    await PreferencesService.init();

    // Initialize NotificationService
    await NotificationService().init();

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e, stackTrace) {
    debugPrint('Initialization failed: $e\n$stackTrace');
    // Consider reporting this to a crash reporting service
  } finally {
    // Always run the app, even if initialization failed
    // This prevents the splash screen from hanging indefinitely
    runApp(const ProofItApp());
  }
}

class ProofItApp extends StatelessWidget {
  const ProofItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProofProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ProofIT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: const Color(0xFF00FF7F),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00FF7F),
            secondary: const Color(0xFF00FF7F),
            surface: Colors.black,
            error: const Color(0xFFFF4C4C),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF7F),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00FF7F), width: 2),
            ),
          ),
          textTheme: GoogleFonts.poppinsTextTheme().copyWith(
            bodyLarge: GoogleFonts.poppins(color: Colors.white),
            bodyMedium: GoogleFonts.poppins(color: Colors.white),
            bodySmall: GoogleFonts.poppins(color: Colors.white),
            titleLarge: GoogleFonts.poppins(color: Colors.white),
            labelLarge: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
        builder: (context, child) {
          return AppLifecycleManager(child: child!);
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final authProvider = context.read<AuthProvider>();

      // Check if user is logged in and has PIN setup
      // Note: We need to handle async check carefully in lifecycle method
      if (authProvider.isAuthenticated && !_isLocked) {
        // We need to re-verify existence of PIN because user might have cleared it
        // Check local storage synchronously if possible, or assume state is roughly correct.
        // authProvider.hasPinSetup() is async.

        final hasPin = await authProvider.hasPinSetup();

        if (hasPin && !_isLocked && mounted) {
          _isLocked = true;
          navigatorKey.currentState
              ?.push(
                MaterialPageRoute(
                  builder: (_) => PinVerificationScreen(
                    isAppLock: true,
                    onSuccess: () {
                      _isLocked = false;
                    },
                  ),
                ),
              )
              .then((_) {
                // Ensure lock state is cleared if popped (though back button is disabled)
                // This handles potential programmatic pops or edge cases
                if (mounted) {
                  // We rely on onSuccess to clear _isLocked for success path.
                  // If popped without success (shouldn't happen due to PopScope), keep locked?
                  // Actually, if generic pop happens, we should probably check if verified.
                }
              });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Keep splash for a minimum duration matches animation time in SplashScreen
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Always show splash first until timer completes
    if (_showSplash) {
      return const SplashScreen();
    }

    // 2. Consume AuthProvider state for routing
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // If still loading auth state, you might want to show splash or loader
        // But assuming defaults are safe (false/null)

        if (!auth.isOnboardingCompleted) {
          return const OnboardingScreen();
        }

        if (auth.isAuthenticated) {
          return const HomeDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}
