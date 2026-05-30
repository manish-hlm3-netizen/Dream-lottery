import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
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
  bool _isLaunchingUpdate = false;

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

    final ApiService api = ApiService();

    // 1. Fetch remote version and verify if client needs to update
    try {
      final res = await api.getAppVersion().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('⏳ Splash Screen: Version check timed out.');
          return {'success': false};
        },
      );
      
      if (res['success'] == true) {
        final remoteVersion = res['data']['appVersion'] as String;
        final downloadUrl = res['data']['appDownloadUrl'] as String;
        
        if (remoteVersion != ApiConfig.appVersion) {
          // Force update! Display update dialog and stop startup flow.
          if (mounted) {
            _showUpdateDialog(remoteVersion, downloadUrl);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
    }

    if (!mounted) return;

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
      backgroundColor: Colors.white, // Clean white background as requested
      body: Stack(
        children: [
          // Background Video Player (Centred with Correct Aspect Ratio)
          if (_isVideoInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            // Clean white fallback with loader while video buffers
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

          // Dream Lottery Brand Overlay
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Dream Lottery',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white, // Base white required for ShaderMask gradient to overlay
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Color(0x1F000000), // Subtle light shadow for depth
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your luck starts here',
                  style: TextStyle(
                    color: AppTheme.textSecondary, // Highly readable Slate Gray on white theme
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(String version, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force update!
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: false, // Disable back button
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.system_update_alt, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text(
                  'Update Available!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version (v$version) of Dream Lottery is available.',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please update the app to continue playing lottery and avoid secure login errors.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                if (_isLaunchingUpdate) ...[
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Opening download link...',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              if (!_isLaunchingUpdate)
                ElevatedButton(
                  onPressed: () async {
                    setDialogState(() {
                      _isLaunchingUpdate = true;
                    });
                    
                    await _launchDownloadUrl(downloadUrl);
                    
                    // Reset spinner after a short safety delay to allow retries if launch fails
                    if (mounted) {
                      Future.delayed(const Duration(seconds: 5), () {
                        if (mounted) {
                          setDialogState(() {
                            _isLaunchingUpdate = false;
                          });
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchDownloadUrl(String url) async {
    // If downloadUrl is empty, fallback to default API server endpoint
    final targetUrl = url.isNotEmpty 
        ? url 
        : 'https://lottery-api-vgk0.onrender.com/api/app/download';
        
    final Uri uri = Uri.parse(targetUrl);
    try {
      // Bypassing canLaunchUrl and invoking launchUrl directly is the official recommended 
      // standard by the Flutter team on Android 11+ to solve visibility restrictions completely.
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch update URL: $targetUrl');
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
  }
}
