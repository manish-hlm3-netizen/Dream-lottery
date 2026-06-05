import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────
// Entry point: call this to show the winner experience
// ─────────────────────────────────────────────────────────────
void showRank1WinnerDialog(BuildContext context, Map<String, dynamic> ticket) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 450),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.80, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) => Rank1WinnerDialog(ticket: ticket),
  );
}

// ─────────────────────────────────────────────────────────────
// The dialog widget
// ─────────────────────────────────────────────────────────────
class Rank1WinnerDialog extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const Rank1WinnerDialog({super.key, required this.ticket});

  @override
  State<Rank1WinnerDialog> createState() => _Rank1WinnerDialogState();
}

class _Rank1WinnerDialogState extends State<Rank1WinnerDialog>
    with TickerProviderStateMixin {
  // Separate ticker for particle physics — never interferes with the card animation
  late final AnimationController _particleTicker;

  final List<_Particle> _particles = [];
  final Random _rng = Random();
  OverlayEntry? _overlayEntry;
  int _ticks = 0;

  // For the pulsing crown icon
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Particle ticker at ~60 fps
    _particleTicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
    _particleTicker.addListener(_tick);

    // Crown pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Insert fireworks overlay after first frame so we have a context
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertOverlay());
  }

  void _insertOverlay() {
    if (!mounted) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _particleTicker,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _FireworksPainter(particles: _particles),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _particleTicker.removeListener(_tick);
    _particleTicker.dispose();
    _pulseCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  // ── Physics tick ────────────────────────────────────────────
  void _tick() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    _ticks++;

    // Launch sky shots every 35 ticks (keep max 5 in flight)
    if (_ticks % 35 == 0) {
      final skyCount = _particles.where((p) => p.isSkyShot).length;
      if (skyCount < 5) _spawnSkyShot(size);
    }

    // Firecracker sparks from bottom corners every 4 ticks
    if (_ticks % 4 == 0) {
      _spawnSpark(size, fromLeft: true);
      _spawnSpark(size, fromLeft: false);
    }

    // Update particles; explode sky shots that reach their apex
    final next = <_Particle>[];
    for (final p in _particles) {
      p.update();
      if (p.isSkyShot && p.reachedApex) {
        _explode(p.x, p.y, p.color, size);
      } else if (p.alpha > 0.01 && p.x >= -20 && p.x <= size.width + 20) {
        next.add(p);
      }
    }
    _particles
      ..clear()
      ..addAll(next);
    // No setState — the OverlayEntry repaints through AnimatedBuilder
  }

  void _spawnSkyShot(Size size) {
    final x = size.width * (0.15 + _rng.nextDouble() * 0.7);
    final targetY = size.height * (0.08 + _rng.nextDouble() * 0.30);
    _particles.add(_Particle.skyShot(
      x: x,
      y: size.height + 10,
      targetY: targetY,
      color: _brightColor(),
      rng: _rng,
    ));
  }

  void _spawnSpark(Size size, {required bool fromLeft}) {
    final x = fromLeft ? _rng.nextDouble() * 40 : size.width - _rng.nextDouble() * 40;
    final y = size.height - 60 - _rng.nextDouble() * 60;
    _particles.add(_Particle.spark(
      x: x,
      y: y,
      vx: (fromLeft ? 1 : -1) * (3 + _rng.nextDouble() * 7),
      vy: -(6 + _rng.nextDouble() * 10),
      color: _rng.nextBool() ? Colors.amberAccent : Colors.white,
      rng: _rng,
    ));
  }

  void _explode(double x, double y, Color baseColor, Size size) {
    final count = 50 + _rng.nextInt(25);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 1.5 + _rng.nextDouble() * 6.5;
      _particles.add(_Particle.explosion(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: _explosionColor(baseColor),
        rng: _rng,
      ));
    }
  }

  Color _brightColor() {
    const palette = [
      Color(0xFFFFD700), // gold
      Color(0xFFFF6B35), // orange
      Color(0xFF00E5FF), // cyan
      Color(0xFFE040FB), // purple
      Color(0xFF69FF47), // green
      Color(0xFFFF4081), // pink
      Color(0xFFFFEA00), // yellow
    ];
    return palette[_rng.nextInt(palette.length)];
  }

  Color _explosionColor(Color base) {
    final mix = [base, Colors.white, Colors.amberAccent, _brightColor()];
    return mix[_rng.nextInt(mix.length)];
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final lottery = widget.ticket['lotteryId'] ?? {};
    final lotteryName = lottery['name'] ?? 'Lottery';
    final prizeWon = widget.ticket['prizeWon'] ?? 0;
    final ticketId = (widget.ticket['_id'] ?? '').toString();
    final shortId = ticketId.length > 8
        ? ticketId.substring(ticketId.length - 8).toUpperCase()
        : ticketId.toUpperCase();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: _WinnerCard(
              lang: lang,
              lotteryName: lotteryName,
              prizeWon: prizeWon,
              shortId: shortId,
              ticketId: ticketId,
              pulseAnim: _pulseAnim,
              onClose: () async {
                _removeOverlay();
                await StorageService.acknowledgeRank1Win(ticketId);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Extracted card so the build method is clean
// ─────────────────────────────────────────────────────────────
class _WinnerCard extends StatelessWidget {
  final LanguageProvider lang;
  final String lotteryName;
  final dynamic prizeWon;
  final String shortId;
  final String ticketId;
  final Animation<double> pulseAnim;
  final VoidCallback onClose;

  const _WinnerCard({
    required this.lang,
    required this.lotteryName,
    required this.prizeWon,
    required this.shortId,
    required this.ticketId,
    required this.pulseAnim,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isHindi = lang.isHindi;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFFE040FB).withValues(alpha: 0.2),
            blurRadius: 60,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header banner ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Pulsing crown + trophy
                ScaleTransition(
                  scale: pulseAnim,
                  child: const Text('🏆', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 8),
                Text(
                  isHindi ? '🎉 बधाई हो! 🎉' : '🎉 CONGRATULATIONS! 🎉',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A0A2E),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A2E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isHindi ? '👑 रैंक 1 विजेता 👑' : '👑 RANK 1 WINNER 👑',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A0A2E),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              children: [
                // Prize amount
                Text(
                  isHindi ? 'आपकी जीत' : 'You Won',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFF10B981), Color(0xFFFFD700)],
                  ).createShader(b),
                  child: Text(
                    '₹$prizeWon',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Lottery & ticket info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.casino_rounded,
                        label: isHindi ? 'लॉटरी' : 'Lottery',
                        value: lotteryName,
                        valueColor: const Color(0xFFFFD700),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.confirmation_number_outlined,
                        label: isHindi ? 'टिकट आईडी' : 'Ticket ID',
                        value: 'DL-$shortId',
                        valueColor: const Color(0xFF80CBC4),
                        mono: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Celebration message
                Text(
                  isHindi
                      ? 'आपकी जीत की राशि आपके विनिंग वॉलेट में जमा कर दी गई है।'
                      : 'Your prize has been credited to your Winning Wallet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF90A4AE),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Close button ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isHindi ? '🎊  शानदार!  🎊' : '🎊  Claim Your Victory!  🎊',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A0A2E),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small reusable info row inside the details card
// ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF90A4AE),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Particle model
// ─────────────────────────────────────────────────────────────
class _Particle {
  double x, y, vx, vy;
  Color color;
  double size, alpha, decay, gravity, drag;
  bool isSkyShot;
  double targetY;
  bool reachedApex = false;

  _Particle({
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

  factory _Particle.skyShot({
    required double x,
    required double y,
    required double targetY,
    required Color color,
    required Random rng,
  }) {
    return _Particle(
      x: x, y: y,
      vx: (rng.nextDouble() - 0.5) * 2.5,
      vy: -(12 + rng.nextDouble() * 6),
      color: color,
      size: 4 + rng.nextDouble() * 2,
      alpha: 1, decay: 0,
      gravity: 0, drag: 0.99,
      isSkyShot: true,
      targetY: targetY,
    );
  }

  factory _Particle.spark({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required Color color,
    required Random rng,
  }) {
    return _Particle(
      x: x, y: y, vx: vx, vy: vy,
      color: color,
      size: 2 + rng.nextDouble() * 2,
      alpha: 1,
      decay: 0.025 + rng.nextDouble() * 0.02,
      gravity: 0.18, drag: 0.94,
    );
  }

  factory _Particle.explosion({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required Color color,
    required Random rng,
  }) {
    return _Particle(
      x: x, y: y, vx: vx, vy: vy,
      color: color,
      size: 2.5 + rng.nextDouble() * 3,
      alpha: 1,
      decay: 0.010 + rng.nextDouble() * 0.012,
      gravity: 0.06, drag: 0.965,
    );
  }

  void update() {
    if (isSkyShot) {
      x += vx;
      y += vy;
      vx *= drag;
      vy *= 0.988; // gradual deceleration upward
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
// Custom painter — renders all particles on a full-screen canvas
// ─────────────────────────────────────────────────────────────
class _FireworksPainter extends CustomPainter {
  final List<_Particle> particles;
  const _FireworksPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.alpha <= 0) continue;
      paint.color = p.color.withValues(alpha: p.alpha.clamp(0, 1));

      if (p.isSkyShot) {
        // Draw glowing trail then bright head
        final trailRect = Rect.fromLTWH(p.x - 1.5, p.y, 3, 22);
        paint.shader = LinearGradient(
          colors: [
            p.color.withValues(alpha: 0),
            p.color.withValues(alpha: 0.8),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(trailRect);
        canvas.drawRect(trailRect, paint);
        paint.shader = null;
        paint.color = Colors.white.withValues(alpha: 0.95);
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      } else {
        // Circular spark with soft glow
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
        paint.maskFilter = null;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => true;
}
