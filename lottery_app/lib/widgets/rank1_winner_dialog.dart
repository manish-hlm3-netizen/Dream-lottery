import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────
// Public API — call this from home_screen.dart
// ─────────────────────────────────────────────────────────────
void showRank1WinnerDialog(BuildContext context, Map<String, dynamic> ticket) {
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Rank1Celebration(
      ticket: ticket,
      onDismiss: () {
        entry.remove();
      },
    ),
  );
  Overlay.of(context).insert(entry);
}

// ─────────────────────────────────────────────────────────────
// Full-screen celebration overlay — NO card, just fireworks
// ─────────────────────────────────────────────────────────────
class _Rank1Celebration extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onDismiss;

  const _Rank1Celebration({
    required this.ticket,
    required this.onDismiss,
  });

  @override
  State<_Rank1Celebration> createState() => _Rank1CelebrationState();
}

class _Rank1CelebrationState extends State<_Rank1Celebration>
    with TickerProviderStateMixin {
  // Particle physics ticker (~60 fps)
  late final AnimationController _ticker;

  // Text fade-in
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Pulsing glow on the prize text
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  final List<_FWParticle> _particles = [];
  final Random _rng = Random();
  int _ticks = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _ticker.addListener(_tick);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Immediate burst of fireworks at the very start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < 6; i++) {
        _launchSkyShot(size);
      }
    });
  }

  @override
  void dispose() {
    _ticker.removeListener(_tick);
    _ticker.dispose();
    _fadeCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Physics ──────────────────────────────────────────────────
  void _tick() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    _ticks++;

    // New sky shot every 28 ticks (keep ≤ 6 in flight)
    if (_ticks % 28 == 0) {
      final inFlight = _particles.where((p) => p.isSkyShot).length;
      if (inFlight < 6) _launchSkyShot(size);
    }

    // Continuous ground sparks at bottom edge every 2 ticks
    if (_ticks % 2 == 0) {
      _spawnGroundSpark(size);
    }

    final next = <_FWParticle>[];
    for (final p in _particles) {
      p.update();
      if (p.isSkyShot && p.reachedApex) {
        _burst(p.x, p.y, p.color, size);
      } else if (p.alpha > 0.01) {
        next.add(p);
      }
    }
    _particles
      ..clear()
      ..addAll(next);
    // Overlay repaints via RepaintBoundary + ticker listener
    if (mounted) setState(() {});
  }

  void _launchSkyShot(Size size) {
    final x = size.width * (0.1 + _rng.nextDouble() * 0.8);
    final targetY = size.height * (0.05 + _rng.nextDouble() * 0.40);
    _particles.add(_FWParticle.skyShot(
      x: x,
      startY: size.height + 10,
      targetY: targetY,
      color: _randomVibrantColor(),
      rng: _rng,
    ));
  }

  void _spawnGroundSpark(Size size) {
    // Random point along the bottom quarter of the screen
    final x = _rng.nextDouble() * size.width;
    final y = size.height * (0.75 + _rng.nextDouble() * 0.25);
    final angle = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 0.8;
    final speed = 3.0 + _rng.nextDouble() * 6.0;
    _particles.add(_FWParticle.spark(
      x: x,
      y: y,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      color: _rng.nextBool() ? Colors.amberAccent : Colors.white,
      rng: _rng,
    ));
  }

  void _burst(double x, double y, Color center, Size size) {
    final count = 60 + _rng.nextInt(30);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 1.0 + _rng.nextDouble() * 8.0;
      _particles.add(_FWParticle.explosion(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: _mixColor(center),
        rng: _rng,
      ));
    }
    // Add a ring of bright white sparks for the initial flash
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi;
      _particles.add(_FWParticle.explosion(
        x: x,
        y: y,
        vx: cos(angle) * 9,
        vy: sin(angle) * 9,
        color: Colors.white,
        rng: _rng,
        fastDecay: true,
      ));
    }
  }

  Color _randomVibrantColor() {
    const colors = [
      Color(0xFFFFD700), // gold
      Color(0xFFFF3D71), // pink-red
      Color(0xFF00E5FF), // cyan
      Color(0xFF69FF47), // lime green
      Color(0xFFE040FB), // purple
      Color(0xFFFF6D00), // deep orange
      Color(0xFFFFEA00), // yellow
      Color(0xFF40C4FF), // light blue
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  Color _mixColor(Color base) {
    final options = [base, Colors.white, Colors.amberAccent, _randomVibrantColor()];
    return options[_rng.nextInt(options.length)];
  }

  // ── Dismiss ──────────────────────────────────────────────────
  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    final ticketId = (widget.ticket['_id'] ?? '').toString();
    await StorageService.acknowledgeRank1Win(ticketId);
    _fadeCtrl.reverse().whenComplete(widget.onDismiss);
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final lottery = widget.ticket['lotteryId'] ?? {};
    final lotteryName = (lottery['name'] ?? 'Lottery').toString();
    final prizeWon = widget.ticket['prizeWon'] ?? 0;
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // ── 1. Dark background ─────────────────────────
              Container(color: Colors.black.withValues(alpha: 0.88)),

              // ── 2. Fireworks particle canvas ───────────────
              CustomPaint(
                size: size,
                painter: _FireworksPainter(particles: _particles),
              ),

              // ── 3. Centered winner text (NO card) ──────────
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Trophy emoji — large and prominent
                    const Text('🏆', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 16),

                    // Glowing WINNER text
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Text(
                        lang.isHindi ? 'विजेता!' : 'WINNER!',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: _glowAnim.value),
                              blurRadius: 30 * _glowAnim.value,
                            ),
                            Shadow(
                              color: const Color(0xFFFF6D00)
                                  .withValues(alpha: _glowAnim.value * 0.6),
                              blurRadius: 60 * _glowAnim.value,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Rank 1 badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                            width: 1.5),
                        color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                      ),
                      child: Text(
                        lang.isHindi ? '👑 रैंक 1' : '👑 RANK 1',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD700),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Lottery name
                    Text(
                      lotteryName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Prize amount — large glowing green
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Text(
                        '₹$prizeWon',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00E676),
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: _glowAnim.value * 0.8),
                              blurRadius: 25 * _glowAnim.value,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Tap to dismiss hint
                    Text(
                      lang.isHindi
                          ? 'जारी रखने के लिए टैप करें'
                          : 'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Particle model
// ─────────────────────────────────────────────────────────────
class _FWParticle {
  double x, y, vx, vy;
  Color color;
  double size, alpha, decay, gravity, drag;
  bool isSkyShot;
  double targetY;
  bool reachedApex = false;

  _FWParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.alpha,
    required this.decay,
    required this.gravity,
    required this.drag,
    this.isSkyShot = false,
    this.targetY = 0,
  });

  factory _FWParticle.skyShot({
    required double x,
    required double startY,
    required double targetY,
    required Color color,
    required Random rng,
  }) =>
      _FWParticle(
        x: x,
        y: startY,
        vx: (rng.nextDouble() - 0.5) * 2.0,
        vy: -(13 + rng.nextDouble() * 7),
        color: color,
        size: 4.5 + rng.nextDouble() * 2,
        alpha: 1,
        decay: 0,
        gravity: 0,
        drag: 0.992,
        isSkyShot: true,
        targetY: targetY,
      );

  factory _FWParticle.spark({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required Color color,
    required Random rng,
  }) =>
      _FWParticle(
        x: x, y: y, vx: vx, vy: vy,
        color: color,
        size: 2 + rng.nextDouble() * 2,
        alpha: 1,
        decay: 0.028 + rng.nextDouble() * 0.022,
        gravity: 0.20,
        drag: 0.93,
      );

  factory _FWParticle.explosion({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required Color color,
    required Random rng,
    bool fastDecay = false,
  }) =>
      _FWParticle(
        x: x, y: y, vx: vx, vy: vy,
        color: color,
        size: fastDecay ? 3 : 2.5 + rng.nextDouble() * 3.5,
        alpha: 1,
        decay: fastDecay ? 0.06 : 0.009 + rng.nextDouble() * 0.011,
        gravity: fastDecay ? 0.05 : 0.055,
        drag: fastDecay ? 0.92 : 0.970,
      );

  void update() {
    if (isSkyShot) {
      x += vx;
      y += vy;
      vx *= drag;
      vy *= 0.990;
      if (y <= targetY) reachedApex = true;
    } else {
      x += vx;
      y += vy;
      vy += gravity;
      vx *= drag;
      vy *= drag;
      alpha -= decay;
      if (alpha < 0) alpha = 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Custom painter
// ─────────────────────────────────────────────────────────────
class _FireworksPainter extends CustomPainter {
  final List<_FWParticle> particles;
  const _FireworksPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.alpha <= 0) continue;
      final a = p.alpha.clamp(0.0, 1.0);

      if (p.isSkyShot) {
        // Glowing trail (gradient rect going downward)
        final trailTop = Offset(p.x, p.y);
        final trailBottom = Offset(p.x, p.y + 28);
        paint.shader = LinearGradient(
          colors: [
            p.color.withValues(alpha: a * 0.9),
            p.color.withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(trailTop, trailBottom));
        canvas.drawRect(
          Rect.fromCenter(center: Offset(p.x, p.y + 14), width: 3, height: 28),
          paint,
        );
        paint.shader = null;

        // Bright head
        paint.color = Colors.white.withValues(alpha: a);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
        paint.maskFilter = null;
      } else {
        // Glowing spark
        paint.color = p.color.withValues(alpha: a);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
        paint.maskFilter = null;
        // Bright core
        paint.color = Colors.white.withValues(alpha: a * 0.6);
        canvas.drawCircle(Offset(p.x, p.y), p.size * 0.35, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => true;
}
