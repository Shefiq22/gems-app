// ============================================================
//  GEMS — Login Screen
//  - Role selector validates against actual Supabase profile
//  - Benchmark bar loaded LIVE from faculties table
//  - No hardcoded scores anywhere
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/gems_theme.dart';
import '../services/supabase_service.dart';
import 'forgot_password_screen.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _leafController;
  late AnimationController _bgController;
  late AnimationController _pulseController;

  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _fullNameCtrl = TextEditingController();

  bool   _obscure  = true;
  bool   _loading  = false;
  bool   _isSignUp = false;

  String _selectedRole      = 'admin';
  String _selectedFacultyId = 'nas';

  Offset _mousePosition = Offset.zero;
  final List<_FloatingLeaf> _leaves =
      List.generate(18, (i) => _FloatingLeaf(i));

  // Live faculty scores for benchmark bar — no hardcoding
  List<_FacultyBar> _liveBars = [];

  static const _roles = [
    ('admin',           'University Admin'),
    ('faculty_officer', 'Faculty Officer'),
    ('groundskeeper',   'Groundskeeper'),
    ('student',         'Student / Public'),
  ];

  static const _faculties = [
    ('nas', 'Natural & Applied Sciences'),
    ('es',  'Environmental Science'),
    ('eng', 'Engineering'),
    ('med', 'Medical Science'),
  ];

  static const _facultyColors = {
    'nas': Color(0xFFD32F2F),
    'es':  Color(0xFF388E3C),
    'eng': Color(0xFFE65100),
    'med': Color(0xFF1565C0),
  };

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _bgController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _loadLiveFacultyScores();
  }

  /// Fetch real GHI scores from Supabase for the benchmark bar.
  Future<void> _loadLiveFacultyScores() async {
    if (!SupabaseService.isConfigured) return;
    try {
      final raw = await SupabaseService.getFaculties();
      if (!mounted) return;
      setState(() {
        _liveBars = raw.map((f) {
          final id    = f['id'] as String? ?? '';
          final score = (f['green_health_score'] as num?)?.toDouble() ?? 0;
          final name  = f['short_name'] as String? ?? id.toUpperCase();
          final color = _facultyColors[id] ?? GEMSTheme.accentGreen;
          return _FacultyBar(name, score / 100, color);
        }).toList();
      });
    } catch (_) {
      // If not logged in yet, Supabase may reject — that's fine,
      // the bar just stays empty until data loads.
    }
  }

  @override
  void dispose() {
    _leafController.dispose();
    _bgController.dispose();
    _pulseController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────
  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (_isSignUp && _fullNameCtrl.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (_isSignUp && password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (_isSignUp && password != _confirmCtrl.text) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await SupabaseService.signUp(
          email,
          password,
          _fullNameCtrl.text.trim(),
          _selectedRole,
          facultyId: (_selectedRole == 'faculty_officer' ||
                      _selectedRole == 'groundskeeper')
              ? _selectedFacultyId
              : null,
        );
        if (!mounted) return;
        _showSuccess(
            'Account created! Check your email to confirm, then sign in.');
        setState(() {
          _isSignUp = false;
          _confirmCtrl.clear();
          _fullNameCtrl.clear();
        });
      } else {
        // ── Role-validating sign in ──
        await SupabaseService.signInWithRoleCheck(
          email,
          password,
          _selectedRole,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: GEMSTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: GEMSTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 6),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (e) =>
            setState(() => _mousePosition = e.position),
        child: Stack(
          children: [
            _buildBackground(),
            _buildLeaves(),
            CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _GridPainter()),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() => AnimatedBuilder(
        animation: _bgController,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFF0D2B0F),
                    const Color(0xFF1B5E20), _bgController.value)!,
                Color.lerp(const Color(0xFF1B5E20),
                    const Color(0xFF2E7D32), _bgController.value)!,
                Color.lerp(const Color(0xFF004D40),
                    const Color(0xFF00695C), _bgController.value)!,
              ],
            ),
          ),
        ),
      );

  Widget _buildLeaves() => AnimatedBuilder(
        animation: _leafController,
        builder: (_, __) {
          final size = MediaQuery.of(context).size;
          return Stack(
            children: _leaves.map((leaf) {
              final t =
                  (_leafController.value + leaf.offset) % 1.0;
              final x = leaf.startX * size.width +
                  math.sin(t * math.pi * 2 + leaf.wobble) * 40;
              final y = -60.0 + t * (size.height + 120);
              return Positioned(
                left: x,
                top:  y,
                child: Transform.rotate(
                  angle: t * leaf.rotSpeed * math.pi * 4,
                  child: Opacity(
                    opacity: leaf.opacity,
                    child: Icon(leaf.icon,
                        color: Colors.white, size: leaf.size),
                  ),
                ),
              );
            }).toList(),
          );
        },
      );

  Widget _buildContent() => Row(
        children: [
          // ── Left hero ──
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.eco,
                                  color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('GEMS',
                                    style: GoogleFonts
                                        .playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight:
                                          FontWeight.w800,
                                    )),
                                Text(
                                    'Abiola Ajimobi University',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        letterSpacing: 1.2)),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(duration: 600.ms)
                            .slideX(begin: -0.3),

                        const SizedBox(height: 80),

                        Text(
                          'Nurturing\nNature,\nShaping Tomorrow.',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ).animate()
                            .fadeIn(delay: 200.ms, duration: 800.ms)
                            .slideY(begin: 0.3),

                        const SizedBox(height: 24),

                        Text(
                          'Monitor, manage, and transform the green '
                          'landscape of your university — faculty by faculty.',
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 16,
                              height: 1.7),
                        ).animate()
                            .fadeIn(delay: 400.ms, duration: 800.ms),

                        const SizedBox(height: 60),

                        // Stat pills — these still come from
                        // the university_settings table via
                        // the dashboard; on the login page
                        // we show known-stable facts only.
                        const Row(
                          children: [
                            _StatPill(label: '4',  sub: 'Faculties'),
                            SizedBox(width: 20),
                            _StatPill(label: '47', sub: 'Hectares'),
                            SizedBox(width: 20),
                            _StatPill(label: '15', sub: 'Years Young'),
                          ],
                        ).animate()
                            .fadeIn(delay: 600.ms, duration: 800.ms),

                        const SizedBox(height: 50),

                        // ── LIVE benchmark bar ──
                        if (_liveBars.isNotEmpty)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) => _LiveBenchmarkBar(
                              bars:  _liveBars,
                              pulse: _pulseController.value,
                            ),
                          ).animate().fadeIn(delay: 800.ms)
                        else
                          // Skeleton while loading
                          _BenchmarkSkeleton()
                              .animate().fadeIn(delay: 800.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Right login card ──
          Expanded(
            flex: 4,
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: c.maxHeight),
                  child: Center(
                    child: Container(
                      width: 460,
                      margin: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 40),
                      padding: const EdgeInsets.all(44),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ),
            ),
          ).animate()
              .fadeIn(delay: 300.ms, duration: 800.ms)
              .slideX(begin: 0.3),
        ],
      );

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSignUp ? 'Create Account' : 'Welcome Back',
          style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: GEMSTheme.textDark),
        ),
        const SizedBox(height: 6),
        Text(
          _isSignUp
              ? 'Join the GEMS platform'
              : 'Sign in to your GEMS account',
          style: GoogleFonts.poppins(
              fontSize: 14, color: GEMSTheme.textLight),
        ),
        const SizedBox(height: 28),

        // Role selector
        Text('I am a...',
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: GEMSTheme.textLight,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: _roles.map((r) {
            final selected = _selectedRole == r.$1;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = r.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? GEMSTheme.primaryGreen
                      : GEMSTheme.offWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? GEMSTheme.primaryGreen
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(r.$2,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : GEMSTheme.textMid)),
              ),
            );
          }).toList(),
        ),

        // Role hint (sign-in only)
        if (!_isSignUp) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GEMSTheme.primaryGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 14, color: GEMSTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select the role you signed up with. '
                  'Wrong role = access denied.',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: GEMSTheme.primaryGreen),
                ),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 20),

        // Full name (sign-up only)
        if (_isSignUp) ...[
          _InputField(
            controller: _fullNameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            hint: 'e.g. Amina Bello',
          ),
          const SizedBox(height: 14),
        ],

        // Faculty (sign-up, officer/groundskeeper)
        if (_isSignUp &&
            (_selectedRole == 'faculty_officer' ||
                _selectedRole == 'groundskeeper')) ...[
          Text('Your Faculty',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: GEMSTheme.textMid,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: GEMSTheme.offWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFacultyId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: GEMSTheme.textLight, size: 18),
                style: GoogleFonts.poppins(
                    fontSize: 13, color: GEMSTheme.textDark),
                items: _faculties
                    .map((f) => DropdownMenuItem(
                        value: f.$1, child: Text(f.$2)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedFacultyId = v!),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Email
        _InputField(
          controller: _emailCtrl,
          label: 'Email Address',
          icon: Icons.mail_outline_rounded,
          hint: 'yourname@aatu.edu.ng',
        ),
        const SizedBox(height: 14),

        // Password
        _InputField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••',
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: GEMSTheme.textLight,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscure = !_obscure),
          ),
        ),

        // Confirm password (sign-up)
        if (_isSignUp) ...[
          const SizedBox(height: 14),
          _InputField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            icon: Icons.lock_outline_rounded,
            hint: '••••••••',
            obscure: _obscure,
          ),
        ],

        // Forgot password
        if (!_isSignUp) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        const ForgotPasswordScreen()),
              ),
              child: Text('Forgot password?',
                  style: GoogleFonts.poppins(
                      color: GEMSTheme.accentGreen,
                      fontSize: 13)),
            ),
          ),
        ],

        const SizedBox(height: 20),

        _HoverButton(
          loading: _loading,
          label: _isSignUp ? 'Create Account' : 'Enter GEMS',
          icon:  _isSignUp ? Icons.person_add_alt_1 : Icons.eco,
          onTap: _submit,
        ),

        const SizedBox(height: 20),

        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _isSignUp = !_isSignUp;
              _confirmCtrl.clear();
              _fullNameCtrl.clear();
            }),
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : "Don't have an account? Create one",
              style: GoogleFonts.poppins(
                  color: GEMSTheme.accentGreen, fontSize: 13),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Abiola Ajimobi University · Secured by Supabase',
            style: GoogleFonts.poppins(
                fontSize: 11, color: GEMSTheme.textLight),
          ),
        ),
      ],
    );
  }
}

// ── DATA MODEL ───────────────────────────────────────────────

class _FacultyBar {
  final String name;
  final double fraction; // 0.0 – 1.0
  final Color  color;
  const _FacultyBar(this.name, this.fraction, this.color);
}

// ── LIVE BENCHMARK BAR ────────────────────────────────────────

class _LiveBenchmarkBar extends StatelessWidget {
  final List<_FacultyBar> bars;
  final double pulse;
  const _LiveBenchmarkBar(
      {required this.bars, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LIVE GREEN HEALTH INDEX',
            style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1.8)),
        const SizedBox(height: 12),
        ...bars.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(f.name,
                        style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Stack(children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: f.fraction.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: f.color,
                            borderRadius:
                                BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: f.color.withOpacity(
                                    0.4 + pulse * 0.2),
                                blurRadius: 8,
                              )
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Text('${(f.fraction * 100).toInt()}',
                      style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )),
      ],
    );
  }
}

class _BenchmarkSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LOADING CAMPUS GHI…',
            style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1.8)),
        const SizedBox(height: 12),
        ...List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(width: 30, height: 10,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 8,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4)))),
          ]),
        )),
      ],
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────

class _FloatingLeaf {
  late double startX, offset, wobble, rotSpeed, size, opacity;
  late IconData icon;
  _FloatingLeaf(int seed) {
    final r = math.Random(seed * 137);
    startX   = r.nextDouble();
    offset   = r.nextDouble();
    wobble   = r.nextDouble() * math.pi * 2;
    rotSpeed = (r.nextDouble() - 0.5) * 2;
    size     = 10 + r.nextDouble() * 18;
    opacity  = 0.04 + r.nextDouble() * 0.12;
    final icons = [Icons.eco, Icons.spa, Icons.local_florist,
                   Icons.grass, Icons.nature];
    icon = icons[seed % icons.length];
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _StatPill extends StatelessWidget {
  final String label, sub;
  const _StatPill({required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          Text(sub,
              style: GoogleFonts.poppins(
                  color: Colors.white60, fontSize: 11)),
        ]),
      );
}

class _InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.suffix,
  });
  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: GEMSTheme.textMid,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? GEMSTheme.accentGreen
                  : Colors.grey.shade200,
              width: _focused ? 2 : 1,
            ),
            color: _focused
                ? GEMSTheme.offWhite
                : Colors.grey.shade50,
          ),
          child: Focus(
            onFocusChange: (f) =>
                setState(() => _focused = f),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscure,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: GEMSTheme.textDark),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(widget.icon,
                    color: _focused
                        ? GEMSTheme.accentGreen
                        : Colors.grey.shade400,
                    size: 20),
                suffixIcon: widget.suffix,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverButton extends StatefulWidget {
  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HoverButton(
      {required this.loading,
      required this.label,
      required this.icon,
      required this.onTap});
  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [GEMSTheme.accentGreen, GEMSTheme.forestGreen]
                  : [GEMSTheme.forestGreen, GEMSTheme.primaryGreen],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: GEMSTheme.primaryGreen
                    .withOpacity(_hovered ? 0.5 : 0.25),
                blurRadius: _hovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(widget.label,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      AnimatedSlide(
                        offset: _hovered
                            ? const Offset(0.2, 0)
                            : Offset.zero,
                        duration:
                            const Duration(milliseconds: 200),
                        child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}