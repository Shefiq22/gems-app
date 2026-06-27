// ============================================================
//  GEMS — main.dart
//  Full routing, AuthGate, deep-link handler for
//  password-reset redirect (#/reset-password from email)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/gems_theme.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use hash-based URLs (#/) so password-reset redirects work
  // on static web hosts without server-side routing config.
  usePathUrlStrategy(); // comment out if using hash strategy
  // If you see 404s on refresh, swap to: setUrlStrategy(HashUrlStrategy());

  await SupabaseService.initialize();
  runApp(const GEMSApp());
}

class GEMSApp extends StatelessWidget {
  const GEMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEMS — Abiola Ajimobi Technical University',
      theme: GEMSTheme.theme,
      debugShowCheckedModeBanner: false,
      // Landing page is public — auth not required
      home: const LandingScreen(),
      routes: {
        '/gate':            (_) => const AuthGate(),
        '/login':           (_) => const LoginScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password':  (_) => const ResetPasswordScreen(),
        '/dashboard':       (_) => const DashboardScreen(),
      },
    );
  }
}

// ── AUTH GATE ─────────────────────────────────────────────────
// Entry point from the "Sign In" button on the landing page.
// Uses StreamBuilder so the widget rebuilds the moment auth
// state changes — no missed events, no subscription leaks.
//
//  Not configured → LoginScreen (shows setup instructions)
//  Configured + signed-out → LoginScreen
//  Configured + signed-in  → DashboardScreen
//  passwordRecovery event  → ResetPasswordScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If Supabase is not configured yet, always show login
    if (!SupabaseService.isConfigured) {
      return const _NotConfiguredBanner();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While waiting for the first event, check for an
        // existing session (app reopened while already logged in).
        if (!snapshot.hasData) {
          final existing = SupabaseService.currentUser;
          if (existing != null) return const DashboardScreen();
          return const LoginScreen();
        }

        final event   = snapshot.data!.event;
        final session = snapshot.data!.session;

        switch (event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
            return const DashboardScreen();

          case AuthChangeEvent.passwordRecovery:
            // Email link clicked → user needs to set new password
            return const ResetPasswordScreen();

          case AuthChangeEvent.signedOut:
          case AuthChangeEvent.userDeleted:
            return const LoginScreen();

          default:
            // initialSession on startup — use session presence
            return session != null
                ? const DashboardScreen()
                : const LoginScreen();
        }
      },
    );
  }
}

// ── NOT CONFIGURED BANNER ─────────────────────────────────────
// Shown when the developer hasn't pasted Supabase keys yet.
class _NotConfiguredBanner extends StatelessWidget {
  const _NotConfiguredBanner();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GEMSTheme.offWhite,
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [GEMSTheme.strongShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: GEMSTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.settings_outlined,
                    color: GEMSTheme.warning, size: 32),
              ),
              const SizedBox(height: 24),
              Text('GEMS — Setup Required',
                  style: GEMSTheme.headingLarge),
              const SizedBox(height: 12),
              Text(
                'Open lib/services/supabase_service.dart\n'
                'and replace these two constants with your\n'
                'real Supabase project values:\n\n'
                '  _supabaseUrl     → Project URL\n'
                '  _supabaseAnonKey → anon / public key\n\n'
                'Find them at:\n'
                'Supabase Dashboard → Settings → API',
                textAlign: TextAlign.center,
                style: GEMSTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              // Let developer skip to login anyway for testing UI
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                    context, '/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GEMSTheme.primaryGreen,
                  side: const BorderSide(color: GEMSTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                child: const Text('Open Login Screen Anyway'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}