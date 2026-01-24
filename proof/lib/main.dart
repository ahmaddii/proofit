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
import 'package:google_fonts/google_fonts.dart';

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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF7F), // Neon green
              ),
            ),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const HomeDashboard();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
