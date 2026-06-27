// ============================================================
//  GEMS — Landing Screen (world-class redesign)
//  Scroll-driven animations, particle field, animated counters,
//  parallax hero, feature cards, faculty preview, CTA sections
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/gems_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;
  Offset _mouse = Offset.zero;
  double _scrollY = 0;

  final List<_Particle> _particles =
      List.generate(60, (i) => _Particle(i));

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _scrollCtrl.addListener(
        () => setState(() => _scrollY = _scrollCtrl.offset));
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: MouseRegion(
        onHover: (e) => setState(() => _mouse = e.position),
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          child: Column(
            children: [
              _HeroSection(
                isWide: isWide,
                particleCtrl: _particleCtrl,
                pulseCtrl: _pulseCtrl,
                bgCtrl: _bgCtrl,
                particles: _particles,
                mouse: _mouse,
                scrollY: _scrollY,
              ),
              _StatsStrip(isWide: isWide),
              _FeaturesSection(isWide: isWide),
              _FacultyPreviewSection(isWide: isWide),
              _HowItWorksSection(isWide: isWide),
              _GreenGuideTeaser(isWide: isWide),
              _AboutSection(isWide: isWide),
              _CTAFooter(isWide: isWide),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HERO SECTION
// ══════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  final bool isWide;
  final AnimationController particleCtrl;
  final AnimationController pulseCtrl;
  final AnimationController bgCtrl;
  final List<_Particle> particles;
  final Offset mouse;
  final double scrollY;

  const _HeroSection({
    required this.isWide,
    required this.particleCtrl,
    required this.pulseCtrl,
    required this.bgCtrl,
    required this.particles,
    required this.mouse,
    required this.scrollY,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final parallaxY = scrollY * 0.4;

    return AnimatedBuilder(
      animation: Listenable.merge([particleCtrl, bgCtrl, pulseCtrl]),
      builder: (_, __) {
        return Container(
          height: size.height,
          width: double.infinity,
          child: Stack(
            children: [
              // ── Animated gradient background ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(const Color(0xFF071A09),
                          const Color(0xFF0D2B0F), bgCtrl.value)!,
                      Color.lerp(const Color(0xFF0D2B0F),
                          const Color(0xFF1B5E20), bgCtrl.value)!,
                      Color.lerp(const Color(0xFF1B5E20),
                          const Color(0xFF004D40), bgCtrl.value)!,
                    ],
                  ),
                ),
              ),

              // ── Particle field ──
              ...particles.map((p) {
                final t = (particleCtrl.value + p.offset) % 1.0;
                final x = p.x * size.width +
                    math.sin(t * math.pi * 2 + p.wobble) * 60 +
                    (mouse.dx / (size.width + 1) - 0.5) * p.depth * 40;
                final y = -80.0 + t * (size.height + 160) + parallaxY * p.depth;
                return Positioned(
                  left: x, top: y,
                  child: Transform.rotate(
                    angle: t * p.rotSpeed * math.pi * 4,
                    child: Opacity(
                      opacity: p.opacity *
                          (1 - (parallaxY / size.height).abs()).clamp(0.0, 1.0),
                      child: Icon(p.icon,
                          color: Colors.white, size: p.size),
                    ),
                  ),
                );
              }),

              // ── Parallax glow orbs ──
              Positioned(
                left: size.width * 0.15 +
                    (mouse.dx / (size.width + 1) - 0.5) * 60,
                top: size.height * 0.2 +
                    (mouse.dy / (size.height + 1) - 0.5) * 40 -
                    parallaxY * 0.3,
                child: Container(
                  width: 500, height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF4CAF50).withOpacity(0.15),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(
                right: size.width * 0.1 -
                    (mouse.dx / (size.width + 1) - 0.5) * 80,
                bottom: size.height * 0.1 - parallaxY * 0.2,
                child: Container(
                  width: 350, height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF00897B).withOpacity(0.12),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              // ── Grid overlay ──
              CustomPaint(
                  size: size, painter: _GridPainter()),

              // ── Main content ──
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 80 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.eco,
                                color: Color(0xFF69F0AE), size: 14),
                            const SizedBox(width: 8),
                            Text(
                              'Abiola Ajimobi Technical University',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

                      const SizedBox(height: 32),

                      // Main headline
                      Text(
                        'GEMS',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: isWide ? 96 : 64,
                          fontWeight: FontWeight.w800,
                          height: 0.9,
                          letterSpacing: 8,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 800.ms)
                          .scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 12),

                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(colors: [
                          Color(0xFF69F0AE),
                          Color(0xFF4CAF50),
                          Color(0xFF00BFA5),
                        ]).createShader(bounds),
                        child: Text(
                          'Green Environment Maintenance System',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isWide ? 18 : 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                      const SizedBox(height: 28),

                      Text(
                        'Monitor. Manage. Maintain.\nTransform your campus, one faculty at a time.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: isWide ? 18 : 15,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                      const SizedBox(height: 52),

                      // CTA buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GlowButton(
                            label: 'Enter Dashboard',
                            icon: Icons.eco_rounded,
                            onTap: () => Navigator.pushNamed(
                                context, '/gate'),
                            primary: true,
                          ),
                          const SizedBox(width: 16),
                          _GlowButton(
                            label: 'Create Account',
                            icon: Icons.person_add_outlined,
                            onTap: () => Navigator.pushNamed(
                                context, '/login'),
                            primary: false,
                          ),
                        ],
                      ).animate().fadeIn(delay: 800.ms, duration: 600.ms)
                          .slideY(begin: 0.3),

                      const SizedBox(height: 60),

                      // Live GHI bars
                      _LiveGHIBars(pulseCtrl: pulseCtrl)
                          .animate().fadeIn(delay: 1000.ms),
                    ],
                  ),
                ),
              ),

              // ── Scroll indicator ──
              Positioned(
                bottom: 32, left: 0, right: 0,
                child: Column(
                  children: [
                    Text('Scroll to explore',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: pulseCtrl,
                      builder: (_, __) => Opacity(
                        opacity: 0.4 + pulseCtrl.value * 0.4,
                        child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LIVE GHI BARS
// ══════════════════════════════════════════════════════════════

class _LiveGHIBars extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _LiveGHIBars({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    final faculties = [
      ('NAS — Natural & Applied Sciences', 0.22, GEMSTheme.nasFacultyColor, '22'),
      ('ENV — Environmental Science',      0.78, GEMSTheme.esFacultyColor,  '78'),
      ('ENG — Engineering',                0.28, GEMSTheme.engFacultyColor, '28'),
      ('MED — Medical Science',            0.51, GEMSTheme.medFacultyColor, '51'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: pulseCtrl,
                builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF69F0AE)
                          .withOpacity(0.4 + pulseCtrl.value * 0.4),
                      blurRadius: 8,
                    )],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('LIVE CAMPUS GREEN HEALTH INDEX',
                  style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ...faculties.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Text(f.$1,
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: pulseCtrl,
                        builder: (_, __) => Stack(children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: f.$2,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: f.$3,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(
                                  color: f.$3.withOpacity(
                                      0.4 + pulseCtrl.value * 0.3),
                                  blurRadius: 8,
                                )],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(f.$4,
                        style: GoogleFonts.poppins(
                            color: f.$3,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text('/100',
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STATS STRIP
// ══════════════════════════════════════════════════════════════

class _StatsStrip extends StatelessWidget {
  final bool isWide;
  const _StatsStrip({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF071A09),
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 36),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 40,
        runSpacing: 24,
        children: const [
          _StatPill('4',  'Faculties Monitored'),
          _StatPill('47', 'Hectares of Campus'),
          _StatPill('15', 'Years Young'),
          _StatPill('10', 'Active Tasks'),
          _StatPill('∞',  'Data Points Tracked'),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF69F0AE), Color(0xFF4CAF50)])
                .createShader(b),
            child: Text(value,
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800)),
          ),
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 12)),
        ],
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3);
}

// ══════════════════════════════════════════════════════════════
//  FEATURES SECTION
// ══════════════════════════════════════════════════════════════

class _FeaturesSection extends StatelessWidget {
  final bool isWide;
  const _FeaturesSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: GEMSTheme.offWhite,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _SectionLabel('WHAT GEMS DOES'),
          const SizedBox(height: 12),
          Text('Everything you need to manage\nyour campus green environment',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 42 : 28,
                  fontWeight: FontWeight.w800,
                  color: GEMSTheme.textDark,
                  height: 1.2))
              .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24, runSpacing: 24,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureCard(
                icon: Icons.sensors_rounded,
                title: 'Real-time Monitoring',
                body: 'Live Green Health Index scores for every faculty zone. Watch your campus improve month by month.',
                color: GEMSTheme.primaryGreen,
              ),
              _FeatureCard(
                icon: Icons.task_alt_rounded,
                title: 'Task Management',
                body: 'Create, assign, and track bush clearing, grass cutting, tree planting and more — with status updates.',
                color: GEMSTheme.emerald,
              ),
              _FeatureCard(
                icon: Icons.grass_rounded,
                title: 'Vegetation Reports',
                body: 'Groundskeepers submit field observations. Officers review and escalate. Admins see everything.',
                color: GEMSTheme.accentGreen,
              ),
              _FeatureCard(
                icon: Icons.bar_chart_rounded,
                title: 'Analytics & Reports',
                body: 'Monthly trend charts, faculty comparisons, vegetation breakdowns and task completion analytics.',
                color: GEMSTheme.forestGreen,
              ),
              _FeatureCard(
                icon: Icons.park_rounded,
                title: 'Tree Registry',
                body: 'Track every tree planted on campus — species, location, age, and growth status across all faculties.',
                color: Color(0xFF2E7D32),
              ),
              _FeatureCard(
                icon: Icons.menu_book_rounded,
                title: 'Green Campus Guide',
                body: 'Interactive vegetation assessment tool with cutting standards, burning rules, and chemical guidelines.',
                color: Color(0xFF00695C),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String   title, body;
  final Color    color;
  const _FeatureCard(
      {required this.icon,
      required this.title,
      required this.body,
      required this.color});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 280,
        padding: const EdgeInsets.all(28),
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -8.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.3)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color
                  .withOpacity(_hovered ? 0.18 : 0.07),
              blurRadius: _hovered ? 32 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.15),
                    widget.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
            const SizedBox(height: 20),
            Text(widget.title,
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: GEMSTheme.textDark)),
            const SizedBox(height: 10),
            Text(widget.body,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: GEMSTheme.textLight,
                    height: 1.6)),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FACULTY PREVIEW SECTION
// ══════════════════════════════════════════════════════════════

class _FacultyPreviewSection extends StatelessWidget {
  final bool isWide;
  const _FacultyPreviewSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final faculties = [
      (
        'Natural & Applied Sciences', 'NAS', 22.0,
        'critical', 'Dense bush covers 62% of zone. Urgent clearing needed.',
        GEMSTheme.nasFacultyColor,
        'https://images.unsplash.com/photo-1448375240586-882707db888b?w=600&q=80',
      ),
      (
        'Environmental Science', 'ENV', 78.0,
        'low', 'Benchmark faculty. Well-maintained lawns and flower beds.',
        GEMSTheme.esFacultyColor,
        'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=600&q=80',
      ),
      (
        'Engineering', 'ENG', 28.0,
        'critical', 'Dense dry bush near workshops. Active fire risk.',
        GEMSTheme.engFacultyColor,
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&q=80',
      ),
      (
        'Medical Science', 'MED', 51.0,
        'medium', 'Mixed zones — hostel area good, clinic perimeter bushy.',
        GEMSTheme.medFacultyColor,
        'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=600&q=80',
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _SectionLabel('FACULTY ZONES'),
          const SizedBox(height: 12),
          Text('Live status across all 4 faculties',
              style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 42 : 28,
                  fontWeight: FontWeight.w800,
                  color: GEMSTheme.textDark))
              .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20, runSpacing: 20,
            alignment: WrapAlignment.center,
            children: faculties.asMap().entries.map((e) {
              final f = e.value;
              return _FacultyPreviewCard(
                name: f.$1, short: f.$2, score: f.$3,
                hazard: f.$4, desc: f.$5, color: f.$6,
                imageUrl: f.$7,
              ).animate().fadeIn(delay: (e.key * 120).ms)
                  .slideY(begin: 0.2);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FacultyPreviewCard extends StatefulWidget {
  final String name, short, hazard, desc, imageUrl;
  final double score;
  final Color  color;
  const _FacultyPreviewCard({
    required this.name, required this.short, required this.score,
    required this.hazard, required this.desc, required this.color,
    required this.imageUrl,
  });

  @override
  State<_FacultyPreviewCard> createState() => _FacultyPreviewCardState();
}

class _FacultyPreviewCardState extends State<_FacultyPreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hazardColor = widget.hazard == 'critical'
        ? GEMSTheme.danger
        : widget.hazard == 'medium'
            ? GEMSTheme.warning
            : GEMSTheme.success;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 260,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.4)
                : Colors.grey.shade100,
            width: _hovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color
                  .withOpacity(_hovered ? 0.2 : 0.06),
              blurRadius: _hovered ? 28 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: widget.color.withOpacity(0.15),
                        child: Icon(Icons.eco,
                            color: widget.color, size: 40))),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent,
                        Colors.black.withOpacity(0.6)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${widget.score.toInt()}',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 12,
                  child: Text(widget.short,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: GEMSTheme.textDark)),
                  const SizedBox(height: 6),
                  Text(widget.desc,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: GEMSTheme.textLight,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hazardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.hazard.toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: hazardColor)),
                    ),
                    const Spacer(),
                    // GHI mini bar
                    SizedBox(
                      width: 80,
                      child: Stack(children: [
                        Container(height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(2))),
                        FractionallySizedBox(
                          widthFactor: widget.score / 100,
                          child: Container(height: 4,
                              decoration: BoxDecoration(
                                  color: widget.color,
                                  borderRadius: BorderRadius.circular(2))),
                        ),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HOW IT WORKS
// ══════════════════════════════════════════════════════════════

class _HowItWorksSection extends StatelessWidget {
  final bool isWide;
  const _HowItWorksSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: GEMSTheme.offWhite,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _SectionLabel('HOW IT WORKS'),
          const SizedBox(height: 12),
          Text('Four roles. One system. Total visibility.',
              style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 42 : 28,
                  fontWeight: FontWeight.w800,
                  color: GEMSTheme.textDark))
              .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'GEMS gives every stakeholder exactly what they need.',
            style: GoogleFonts.poppins(
                color: GEMSTheme.textLight, fontSize: 16),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 60),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _RoleCard('🌿', 'Groundskeeper',
                    'Walks the campus. Measures grass height and bush coverage. Submits a field report with one tap.',
                    GEMSTheme.accentGreen),
                _Arrow(),
                _RoleCard('👷', 'Faculty Officer',
                    'Reviews field reports for their faculty. Creates maintenance tasks. Assigns groundskeepers.',
                    GEMSTheme.emerald),
                _Arrow(),
                _RoleCard('🏛️', 'University Admin',
                    'Sees the full campus. Compares faculty GHI scores. Approves budgets and generates reports.',
                    GEMSTheme.primaryGreen),
                _Arrow(),
                _RoleCard('🎓', 'Students & Public',
                    'View the campus green score dashboard. Report issues like illegal dumping or fire hazards.',
                    GEMSTheme.medFacultyColor),
              ],
            )
          else
            Column(
              children: const [
                _RoleCard('🌿', 'Groundskeeper',
                    'Measures and submits field vegetation reports.',
                    GEMSTheme.accentGreen),
                SizedBox(height: 16),
                _RoleCard('👷', 'Faculty Officer',
                    'Reviews reports and creates maintenance tasks.',
                    GEMSTheme.emerald),
                SizedBox(height: 16),
                _RoleCard('🏛️', 'University Admin',
                    'Full campus oversight, reports, and analytics.',
                    GEMSTheme.primaryGreen),
                SizedBox(height: 16),
                _RoleCard('🎓', 'Students & Public',
                    'View scores and report environmental issues.',
                    GEMSTheme.medFacultyColor),
              ],
            ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji, title, desc;
  final Color  color;
  const _RoleCard(this.emoji, this.title, this.desc, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [GEMSTheme.softShadow],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(height: 8),
              Text(desc,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: GEMSTheme.textLight,
                      height: 1.5)),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
      );
}

class _Arrow extends StatelessWidget {
  const _Arrow();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Icon(Icons.arrow_forward_rounded,
            color: GEMSTheme.lightGreen, size: 28),
      );
}

// ══════════════════════════════════════════════════════════════
//  GREEN GUIDE TEASER
// ══════════════════════════════════════════════════════════════

class _GreenGuideTeaser extends StatelessWidget {
  final bool isWide;
  const _GreenGuideTeaser({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF00695C)],
        ),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _GuideTeaserText()),
                const SizedBox(width: 60),
                Expanded(child: _GuideTeaserCards()),
              ],
            )
          : Column(children: [
              _GuideTeaserText(),
              const SizedBox(height: 40),
              _GuideTeaserCards(),
            ]),
    );
  }
}

class _GuideTeaserText extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('📗 Built-in Green Campus Guide',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          Text('Expert vegetation\nmanagement at\nyour fingertips',
              style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.2))
              .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            'GEMS includes a full interactive guide covering cutting heights, '
            'burning rules, chemical herbicide use, and an AI-powered '
            'vegetation assessment tool.',
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 15, height: 1.6),
          ).animate().fadeIn(delay: 200.ms),
        ],
      );
}

class _GuideTeaserCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12, runSpacing: 12,
        children: const [
          _GuideChip('✂️ Cutting Standards', '5–7 cm ideal'),
          _GuideChip('🔥 Burning Rules',     'Permit required'),
          _GuideChip('🧪 Herbicides',        'PPE mandatory'),
          _GuideChip('🌱 Recovery Guide',    'Scalped lawn fix'),
          _GuideChip('🐍 Bush Safety',       'Snake-proof gear'),
          _GuideChip('🌊 Erosion Control',   'Bare land fix'),
        ],
      );
}

class _GuideChip extends StatelessWidget {
  final String title, sub;
  const _GuideChip(this.title, this.sub);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(sub,
                style: GoogleFonts.poppins(
                    color: Colors.white54, fontSize: 11)),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).scale(
          begin: const Offset(0.9, 0.9));
}

// ══════════════════════════════════════════════════════════════
//  ABOUT SECTION
// ══════════════════════════════════════════════════════════════

class _AboutSection extends StatelessWidget {
  final bool isWide;
  const _AboutSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(
        children: [
          _SectionLabel('ABOUT AATU'),
          const SizedBox(height: 12),
          Text('Abiola Ajimobi Technical University',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  fontSize: isWide ? 36 : 24,
                  fontWeight: FontWeight.w800,
                  color: GEMSTheme.textDark))
              .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 20),
          SizedBox(
            width: 700,
            child: Text(
              'AATU is committed to maintaining a safe, sustainable, and visually '
              'appealing campus. GEMS was developed as part of the university\'s '
              'environmental sustainability initiative — digitising vegetation '
              'management, improving campus safety, and promoting ecological '
              'stewardship across all four faculties. The university is 15 years '
              'young and growing greener every semester.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: GEMSTheme.textLight,
                  fontSize: 15,
                  height: 1.7),
            ).animate().fadeIn(delay: 200.ms),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CTA FOOTER
// ══════════════════════════════════════════════════════════════

class _CTAFooter extends StatelessWidget {
  final bool isWide;
  const _CTAFooter({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A09), Color(0xFF0D2B0F), Color(0xFF1B5E20)],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, color: Color(0xFF69F0AE), size: 52),
          const SizedBox(height: 20),
          Text('Ready to green your campus?',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: isWide ? 42 : 28,
                  fontWeight: FontWeight.w800))
              .animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Sign in to the GEMS dashboard and start monitoring today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.white60, fontSize: 16),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 44),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlowButton(
                label: 'Enter Dashboard',
                icon: Icons.eco_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, '/gate'),
                primary: true,
              ),
              const SizedBox(width: 16),
              _GlowButton(
                label: 'Create Account',
                icon: Icons.person_add_outlined,
                onTap: () =>
                    Navigator.pushNamed(context, '/login'),
                primary: false,
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 60),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(
            '© 2026 Abiola Ajimobi Technical University — GEMS v1.0',
            style: GoogleFonts.poppins(
                color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: GEMSTheme.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: GEMSTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                color: GEMSTheme.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
      ).animate().fadeIn();
}

class _GlowButton extends StatefulWidget {
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  final bool       primary;
  const _GlowButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      required this.primary});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered
                    ? const Color(0xFF4CAF50)
                    : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.primary
                  ? Colors.transparent
                  : Colors.white.withOpacity(
                      _hovered ? 0.6 : 0.3),
              width: 1.5,
            ),
            boxShadow: widget.primary && _hovered
                ? [const BoxShadow(
                    color: Color(0xFF4CAF50),
                    blurRadius: 20,
                    spreadRadius: 0,
                  )]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  color: widget.primary
                      ? (_hovered ? Colors.white : GEMSTheme.primaryGreen)
                      : Colors.white,
                  size: 18),
              const SizedBox(width: 10),
              Text(widget.label,
                  style: GoogleFonts.poppins(
                      color: widget.primary
                          ? (_hovered
                              ? Colors.white
                              : GEMSTheme.primaryGreen)
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Particle model ────────────────────────────────────────────

class _Particle {
  late double x, offset, wobble, rotSpeed, size, opacity, depth;
  late IconData icon;

  _Particle(int seed) {
    final r = math.Random(seed * 137 + 7);
    x        = r.nextDouble();
    offset   = r.nextDouble();
    wobble   = r.nextDouble() * math.pi * 2;
    rotSpeed = (r.nextDouble() - 0.5) * 2;
    size     = 8 + r.nextDouble() * 16;
    opacity  = 0.03 + r.nextDouble() * 0.10;
    depth    = 0.3 + r.nextDouble() * 0.7;
    final icons = [
      Icons.eco, Icons.spa, Icons.local_florist,
      Icons.grass, Icons.nature, Icons.forest,
      Icons.park, Icons.yard,
    ];
    icon = icons[seed % icons.length];
  }
}

// ── Grid painter ──────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
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