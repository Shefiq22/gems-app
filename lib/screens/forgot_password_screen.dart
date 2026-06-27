import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Please enter your email address.', GEMSTheme.danger);
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.resetPassword(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) _snack('Failed to send reset email. Try again.', GEMSTheme.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2B0F), Color(0xFF1B5E20), Color(0xFF004D40)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 440,
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(44),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 60, spreadRadius: 10,
                  ),
                ],
              ),
              child: _sent ? _success() : _form(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: GEMSTheme.lightGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: GEMSTheme.primaryGreen, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text('Reset Password',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 8),
          Text(
            "Enter your email address and we'll send you a link to reset your password.",
            style: GoogleFonts.poppins(
                fontSize: 14, color: GEMSTheme.textLight, height: 1.5),
          ),
          const SizedBox(height: 32),
          Text('Email Address',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: GEMSTheme.textMid,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.grey.shade50,
            ),
            child: TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: GEMSTheme.textDark),
              decoration: InputDecoration(
                hintText: 'yourname@aatu.edu.ng',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.mail_outline_rounded,
                    color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _Btn(loading: _loading, label: 'Send Reset Link', onTap: _send),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Back to Sign In',
                  style: GoogleFonts.poppins(
                      color: GEMSTheme.accentGreen, fontSize: 13)),
            ),
          ),
        ],
      );

  Widget _success() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: GEMSTheme.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: GEMSTheme.success, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Check Your Email',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 12),
          Text(
            'We\'ve sent a password reset link to\n${_emailCtrl.text.trim()}\n\n'
            'Click the link in the email — it will bring you back here to set a new password.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 14, color: GEMSTheme.textLight, height: 1.5),
          ),
          const SizedBox(height: 32),
          _Btn(
            loading: false,
            label: 'Back to Sign In',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      );
}

// ── Shared hover button ───────────────────────────────────────

class _Btn extends StatefulWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.loading, required this.label, required this.onTap});

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _h = true),
        onExit:  (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.loading ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _h
                    ? [GEMSTheme.accentGreen, GEMSTheme.forestGreen]
                    : [GEMSTheme.forestGreen, GEMSTheme.primaryGreen],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: GEMSTheme.primaryGreen
                      .withOpacity(_h ? 0.5 : 0.25),
                  blurRadius: _h ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(widget.label,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      );
}