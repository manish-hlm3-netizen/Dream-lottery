import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  String? _nextRoute;
  Object? _nextRouteArgs;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkAuthAndPrepare();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse('https://cdn.dribbble.com/userupload/28360722/file/original-4aed894ee6a4a98d3fa93b9388929f64.mp4'),
      );
      
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.play();
      _videoController.setVolume(0.0); // Muted to avoid startling the user
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing splash video: $e');
    }
  }

  Future<void> _checkAuthAndPrepare() async {
    // Record start time to ensure the splash video plays for a satisfying duration
    final startTime = DateTime.now();

    try {
      final auth = context.read<AuthProvider>();
      
      // Perform the authentication check with a maximum 4s timeout to avoid freezes
      await auth.checkAuth().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('⏳ Splash Screen: Auth check timed out.');
        },
      );

      if (auth.isLoggedIn) {
        // Check if a Security PIN is configured
        String? savedPin;
        try {
          savedPin = await StorageService.getPin();
        } catch (e) {
          debugPrint('Error reading security PIN: $e');
        }

        if (savedPin != null && savedPin.isNotEmpty) {
          _nextRoute = '/security-pin';
          _nextRouteArgs = {'mode': 'unlock'};
        } else {
          _nextRoute = '/home';
        }
      } else {
        _nextRoute = '/login';
      }
    } catch (e) {
      debugPrint('🚨 Splash Screen: Exception during auth check: $e');
      _nextRoute = '/login';
    }

    // Enforce a minimum play time of 3.5 seconds for the video splash screen
    final elapsed = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(milliseconds: 3500) - elapsed;
    
    if (remainingDelay > Duration.zero) {
      await Future.delayed(remainingDelay);
    }

    _navigateToNext();
  }

  void _navigateToNext() {
    if (!mounted) return;
    if (_nextRoute != null) {
      Navigator.pushReplacementNamed(
        context, 
        _nextRoute!,
        arguments: _nextRouteArgs,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    if (_isVideoInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark color is highly premium as a backdrop
      body: Stack(
        children: [
          // Background Video Player
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // Full bleed video background
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            // Gradient fallback with loader while video buffers
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black,
                    Color(0xFF1E0D0D), // Ultra deep red tone
                    Colors.black,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
