import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';

class Rank1WinnerDialog extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const Rank1WinnerDialog({
    super.key,
    required this.ticket,
  });

  @override
  State<Rank1WinnerDialog> createState() => _Rank1WinnerDialogState();
}

class _Rank1WinnerDialogState extends State<Rank1WinnerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FireworkParticle> _particles = [];
  final Random _random = Random();
  late double _screenWidth;
  late double _screenHeight;
  bool _initialized = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS update interval
    )..repeat();

    _controller.addListener(_updatePhysics);
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePhysics);
    _controller.dispose();
    super.dispose();
  }

  void _initScreenSize(BuildContext context) {
    if (_initialized) return;
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _initialized = true;

    // Spawn initial sky shots
    _spawnSkyShot();
    _spawnSkyShot();
  }

  void _spawnSkyShot() {
    if (!_initialized) return;
    final startX = _screenWidth * (0.2 + _random.nextDouble() * 0.6);
    final targetY = _screenHeight * (0.15 + _random.nextDouble() * 0.35);
    final speedY = -(_screenHeight * 0.012 + _random.nextDouble() * _screenHeight * 0.008);

    _particles.add(
      FireworkParticle(
        x: startX,
        y: _screenHeight,
        vx: (_random.nextDouble() - 0.5) * 3,
        vy: speedY,
        color: _getRandomBrightColor(),
        size: 4.0 + _random.nextDouble() * 2.0,
        alpha: 1.0,
        decay: 0.005,
        isSkyShot: true,
        targetY: targetY,
      ),
    );
  }

  void _spawnFirecrackerSparks() {
    if (!_initialized) return;
    // Launch crackling sparks from bottom corners upwards/inwards
    final fromLeft = _random.nextBool();
    final startX = fromLeft ? 10.0 : _screenWidth - 10.0;
    final startY = _screenHeight - 80;
    final vx = (fromLeft ? 1.0 : -1.0) * (5.0 + _random.nextDouble() * 8.0);
    final vy = -(8.0 + _random.nextDouble() * 12.0);

    _particles.add(
      FireworkParticle(
        x: startX,
        y: startY,
        vx: vx,
        vy: vy,
        // High-frequency bright colors or white for sparks
        color: _random.nextBool() ? Colors.white : Colors.amberAccent,
        size: 2.0 + _random.nextDouble() * 2.0,
        alpha: 1.0,
        decay: 0.02 + _random.nextDouble() * 0.03, // fade quickly
        gravity: 0.15,
        drag: 0.95,
      ),
    );
  }

  void _explode(double x, double y, Color centerColor) {
    final particleCount = 45 + _random.nextInt(20);
    final colors = [
      centerColor,
      Colors.amber,
      Colors.orangeAccent,
      Colors.amberAccent,
      Colors.yellowAccent,
      _getRandomBrightColor(),
    ];

    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 1.0 + _random.nextDouble() * 6.0;
      final color = colors[_random.nextInt(colors.length)];

      _particles.add(
        FireworkParticle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          color: color,
          size: 2.0 + _random.nextDouble() * 3.0,
          alpha: 1.0,
          decay: 0.012 + _random.nextDouble() * 0.012,
          gravity: 0.07,
          drag: 0.96,
        ),
      );
    }
  }

  Color _getRandomBrightColor() {
    final List<Color> brightColors = [
      Colors.amberAccent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.yellowAccent,
    ];
    return brightColors[_random.nextInt(brightColors.length)];
  }

  void _updatePhysics() {
    if (!mounted || !_initialized) return;

    _ticks++;

    // Spawning sky shots periodically
    if (_ticks % 40 == 0 && _particles.where((p) => p.isSkyShot).length < 4) {
      _spawnSkyShot();
    }

    // Spawning firecracker sparks at corners
    if (_ticks % 3 == 0) {
      _spawnFirecrackerSparks();
      _spawnFirecrackerSparks();
    }

    List<FireworkParticle> nextParticles = [];

    for (var p in _particles) {
      p.update();
      if (p.isSkyShot && p.hasExploded) {
        _explode(p.x, p.y, p.color);
      } else if (p.alpha > 0.01) {
        nextParticles.add(p);
      }
    }

    setState(() {
      _particles.clear();
      _particles.addAll(nextParticles);
    });
  }

  @override
  Widget build(BuildContext context) {
    _initScreenSize(context);
    final lang = Provider.of<LanguageProvider>(context);
    
    final lottery = widget.ticket['lotteryId'] ?? {};
    final lotteryName = lottery['name'] ?? 'Dream Lottery';
    final prizeWon = widget.ticket['prizeWon'] ?? 0;
    final ticketId = widget.ticket['_id'] ?? '';
    final shortTicketId = ticketId.length > 8 
        ? ticketId.substring(ticketId.length - 8).toUpperCase() 
        : ticketId.toUpperCase();

    final title = lang.isHindi ? "विजेता! 👑" : "WINNER! 👑";
    final congratsText = lang.isHindi 
        ? "बधाई हो! आपने रैंक 1 हासिल किया है।" 
        : "Congratulations! You have achieved Rank 1.";
    final lotteryInfo = lang.isHindi 
        ? "लॉटरी: $lotteryName"
        : "Lottery: $lotteryName";
    final ticketLabel = lang.isHindi
        ? "टिकट आईडी: DL-$shortTicketId"
        : "Ticket ID: DL-$shortTicketId";
    final btnText = lang.isHindi ? "अद्भुत!" : "Awesome!";

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          // 1. Semi-transparent black background backdrop blur
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.65),
            ),
          ),

          // 2. Custom Painter for Fireworks
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: FireworksPainter(particles: _particles),
              ),
            ),
          ),

          // 3. Central Dialog Box (Luxury High Contrast Dark Design)
          Center(
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
                ),
                child: Container(
                  width: _screenWidth * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.92), // Slate 900
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.6),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.25),
                        blurRadius: 35,
                        spreadRadius: 5,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Golden Trophy/Winner Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // WINNER Title
                      ShaderMask(
                        shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Congratulations Text
                      Text(
                        congratsText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ticket Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              lotteryInfo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.amberAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ticketLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white60,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Winning Amount Display
                      Text(
                        lang.isHindi ? "जीती गई राशि:" : "Prize Amount:",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white38,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$prizeWon',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981), // Emerald Green
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Color(0x3310B981),
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      GestureDetector(
                        onTap: () async {
                          // Acknowledge the win locally
                          await StorageService.acknowledgeRank1Win(ticketId);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              btnText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// Particle class for physics updates
class FireworkParticle {
  double x, y;
  double vx, vy;
  Color color;
  double size;
  double alpha;
  double decay;
  bool isSkyShot;
  double? targetY;
  bool hasExploded = false;
  double gravity;
  double drag;

  FireworkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.alpha,
    required this.decay,
    this.isSkyShot = false,
    this.targetY,
    this.gravity = 0.08,
    this.drag = 0.98,
  });

  void update() {
    if (isSkyShot) {
      x += vx;
      y += vy;
      // decelerate upwards slightly as they reach peak
      vy *= 0.985;
      vx *= 0.985;
      if (targetY != null && y <= targetY!) {
        hasExploded = true;
      }
    } else {
      // standard explosion or crackler spark
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

// Painter to draw the particles on canvas
class FireworksPainter extends CustomPainter {
  final List<FireworkParticle> particles;

  const FireworksPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paintObj = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paintObj.color = p.color.withOpacity(p.alpha);
      
      if (p.isSkyShot) {
        // Draw trailing rocket
        final trailPaint = Paint()
          ..shader = LinearGradient(
            colors: [p.color.withOpacity(0.0), p.color],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ).createShader(Rect.fromLTWH(p.x - 2, p.y, 4, 25))
          ..style = PaintingStyle.fill;

        canvas.drawRect(Rect.fromLTWH(p.x - 1.5, p.y, 3, 20), trailPaint);
        // Head spark
        canvas.drawCircle(Offset(p.x, p.y), p.size, paintObj);
      } else {
        // Exploded sparks
        canvas.drawCircle(Offset(p.x, p.y), p.size, paintObj);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FireworksPainter oldDelegate) => true;
}
