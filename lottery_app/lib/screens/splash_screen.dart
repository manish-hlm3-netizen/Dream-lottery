import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
      final appDir = await getApplicationSupportDirectory();
      final localVideoPath = '${appDir.path}/splash_video.mp4';
      final localFile = File(localVideoPath);

      if (await localFile.exists()) {
        debugPrint('📺 Splash Screen: Loading video from local cache...');
        _videoController = VideoPlayerController.file(localFile);
      } else {
        debugPrint('📺 Splash Screen: Cache miss. Loading video from network...');
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse('https://cdn.dribbble.com/userupload/28360722/file/original-4aed894ee6a4a98d3fa93b9388929f64.mp4'),
        );
        // Start background download for next time
        _downloadVideoToCache(localVideoPath);
      }
      
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

  Future<void> _downloadVideoToCache(String targetPath) async {
    try {
      final dio = Dio();
      await dio.download(
        'https://cdn.dribbble.com/userupload/28360722/file/original-4aed894ee6a4a98d3fa93b9388929f64.mp4',
        targetPath,
      );
      debugPrint('📺 Splash Screen: Video downloaded and cached successfully.');
    } catch (e) {
      debugPrint('📺 Splash Screen: Failed to cache video: $e');
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
    double downloadProgress = 0.0;
    String downloadPercentage = '0%';
    bool isDownloading = false;
    String statusText = '';

    showDialog(
      context: context,
      barrierDismissible: false, // Force update!
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> startDownload() async {
            // Check and request "install unknown apps" permission on Android
            if (Platform.isAndroid) {
              final status = await Permission.requestInstallPackages.status;
              if (!status.isGranted) {
                setDialogState(() {
                  statusText = 'Requesting installation permission...';
                });
                final requestStatus = await Permission.requestInstallPackages.request();
                if (!requestStatus.isGranted) {
                  setDialogState(() {
                    isDownloading = false;
                    statusText = 'Failed to install: Permission denied: android.permission.REQUEST_INSTALL_PACKAGES';
                  });
                  return;
                }
              }
            }

            setDialogState(() {
              isDownloading = true;
              downloadProgress = 0.0;
              downloadPercentage = '0%';
              statusText = 'Starting download...';
            });

            try {
              final dio = Dio();
              
              Directory? updateDir;
              if (Platform.isAndroid) {
                // Use app-specific external cache/files dir on Android to prevent Xiaomi/Oppo/Vivo private folder security errors
                try {
                  final extDirs = await getExternalCacheDirectories();
                  if (extDirs != null && extDirs.isNotEmpty) {
                    updateDir = extDirs.first;
                  } else {
                    updateDir = await getExternalStorageDirectory();
                  }
                } catch (err) {
                  debugPrint('Failed to get external directories: $err');
                }
              }
              updateDir ??= await getTemporaryDirectory();
              final apkPath = '${updateDir.path}/dream-lottery-update.apk';

              // Delete old update file if it exists to avoid conflicts
              final file = File(apkPath);
              if (await file.exists()) {
                await file.delete();
              }

              statusText = 'Downloading...';
              await dio.download(
                downloadUrl.isNotEmpty ? downloadUrl : 'https://lottery-api-vgk0.onrender.com/api/app/download',
                apkPath,
                onReceiveProgress: (received, total) {
                  if (total != -1) {
                    setDialogState(() {
                      downloadProgress = received / total;
                      downloadPercentage = '${(downloadProgress * 100).toInt()}%';
                    });
                  }
                },
              );

              setDialogState(() {
                statusText = 'Opening installer...';
              });

              // Launch native package installer
              final result = await OpenFile.open(apkPath);
              debugPrint('Install result message: ${result.message}');

              if (result.type != ResultType.done) {
                setDialogState(() {
                  isDownloading = false;
                  statusText = 'Install failed locally. Opening browser download...';
                });
                
                // Fallback to browser download if local installation fails
                final uri = Uri.parse(downloadUrl.isNotEmpty ? downloadUrl : 'https://lottery-api-vgk0.onrender.com/api/app/download');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            } catch (e) {
              debugPrint('Error during update download/install: $e');
              setDialogState(() {
                isDownloading = false;
                statusText = 'Install failed. Opening browser download...';
              });
              
              // Fallback to browser download on error
              final uri = Uri.parse(downloadUrl.isNotEmpty ? downloadUrl : 'https://lottery-api-vgk0.onrender.com/api/app/download');
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (launchError) {
                debugPrint('Failed to launch browser: $launchError');
              }
            }
          }

          return PopScope(
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
                  if (isDownloading) ...[
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              downloadPercentage,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: downloadProgress,
                            minHeight: 8,
                            backgroundColor: AppTheme.borderColor,
                            color: AppTheme.primaryColor, // Red horizontal bar
                          ),
                        ),
                      ],
                    ),
                  ] else if (statusText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading)
                  ElevatedButton(
                    onPressed: startDownload,
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
          );
        },
      ),
    );
  }
}
