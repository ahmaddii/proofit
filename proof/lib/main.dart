import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/proof_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_dashboard.dart';
import 'utils/constants.dart';
import 'services/preferences_service.dart';
import 'screens/splash/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  await PreferencesService.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ProofItApp());
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
        title: 'ProofIt',
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
        home: const AuthWrapper(),
      ),
    );
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
