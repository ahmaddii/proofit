import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/proof_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_dashboard.dart';
import 'dart:async';

import 'package:timezone/data/latest_all.dart' as tz;
import 'services/preferences_service.dart';
import 'services/notification_service.dart';

import 'screens/splash/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/proof/pin_verification_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Wrap entire app in error handler
  runZonedGuarded(
    () async {
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

        debugPrint('✅ All services initialized successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ Initialization failed: $e\n$stackTrace');
      } finally {
        runApp(const ProofItApp());
      }
    },
    (error, stack) {
      debugPrint('❌ Uncaught error: $error\n$stack');
    },
  );
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
          // Add global error boundary
          ErrorWidget.builder = (FlutterErrorDetails details) {
            debugPrint('❌ Widget error: ${details.exception}');
            return Material(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        navigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const AuthWrapper(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Restart'),
                    ),
                  ],
                ),
              ),
            );
          };
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
      try {
        final authProvider = context.read<AuthProvider>();

        if (authProvider.isAuthenticated && !_isLocked) {
          final hasPin = await authProvider.hasPinSetup();

          if (hasPin && !_isLocked && mounted) {
            _isLocked = true;
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => PinVerificationScreen(
                  isAppLock: true,
                  onSuccess: () {
                    _isLocked = false;
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error in lifecycle state change: $e');
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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for splash animation
      await Future.delayed(const Duration(milliseconds: 2800));

      // Wait for AuthProvider to initialize
      if (mounted) {
        final authProvider = context.read<AuthProvider>();

        // Wait until provider is initialized (max 5 seconds)
        int attempts = 0;
        while (!authProvider.isInitialized && attempts < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        debugPrint(
          '✅ Auth ready - Onboarding: ${authProvider.isOnboardingCompleted}, Auth: ${authProvider.isAuthenticated}',
        );
      }
    } catch (e) {
      debugPrint('❌ Auth wrapper initialization error: $e');
    } finally {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen
    if (_showSplash) {
      return const SplashScreen();
    }

    // Main navigation logic
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loader if not initialized yet (safety check)
        if (!auth.isInitialized) {
          debugPrint('⏳ Waiting for auth initialization...');
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
            ),
          );
        }

        debugPrint(
          '🔄 AuthWrapper rebuild - Onboarding: ${auth.isOnboardingCompleted}, Auth: ${auth.isAuthenticated}',
        );

        // Navigate based on auth state
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
