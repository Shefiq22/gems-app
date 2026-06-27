import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  bool _success  = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.isEmpty || confirm.isEmpty) {
      _snack('Please fill in both fields.', GEMSTheme.danger);
      return;
    }
    if (pass.length < 6) {
      _snack('Password must be at least 6 characters.', GEMSTheme.danger);
      return;
    }
    if (pass != confirm) {
      _snack('Passwords do not match.', GEMSTheme.danger);
      return;
    }

    setState(() => _loading = true);
    try {
      await SupabaseService.updatePassword(pass);
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        _snack(
          e.toString().contains('Invalid')
              ? 'Session expired. Request a new reset link.'
              : 'Failed to reset password. Try again.',
          GEMSTheme.danger,
        );
      }
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
              child: _success ? _successView() : _formView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView() => Column(
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
              child: const Icon(Icons.password_rounded,
                  color: GEMSTheme.primaryGreen, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text('Set New Password',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 8),
          Text('Enter your new password below.',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: GEMSTheme.textLight)),
          const SizedBox(height: 32),

          _PwField(
            ctrl: _passCtrl,
            label: 'New Password',
            obscure: _obscure,
            onToggle: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 16),
          _PwField(
            ctrl: _confirmCtrl,
            label: 'Confirm Password',
            obscure: _obscure,
          ),
          const SizedBox(height: 28),

          _Btn(loading: _loading, label: 'Update Password', onTap: _update),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (_) => false),
              child: Text('Back to Sign In',
                  style: GoogleFonts.poppins(
                      color: GEMSTheme.accentGreen, fontSize: 13)),
            ),
          ),
        ],
      );

  Widget _successView() => Column(
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
          Text('Password Updated!',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: GEMSTheme.textDark)),
          const SizedBox(height: 12),
          Text(
            'Your password has been successfully changed.\nYou can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 14, color: GEMSTheme.textLight, height: 1.5),
          ),
          const SizedBox(height: 32),
          _Btn(
            loading: false,
            label: 'Sign In Now',
            onTap: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false),
          ),
        ],
      );
}

// ── Password field ────────────────────────────────────────────

class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool   obscure;
  final VoidCallback? onToggle;
  const _PwField({
    required this.ctrl,
    required this.label,
    required this.obscure,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
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
              controller: ctrl,
              obscureText: obscure,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: GEMSTheme.textDark),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: Colors.grey, size: 20),
                suffixIcon: onToggle != null
                    ? IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: GEMSTheme.textLight, size: 20,
                        ),
                        onPressed: onToggle,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
}

// ── Hover button ──────────────────────────────────────────────

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