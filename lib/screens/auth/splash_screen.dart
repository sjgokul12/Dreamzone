import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

/// Full-screen responsive video Splash Screen.
/// Plays `assets/Welcome.mp4` full-screen and navigates to HomeScreen upon completion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  void _initializeVideo() {
    try {
      _controller = VideoPlayerController.asset('assets/Welcome.mp4');
      _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isVideoInitialized = true;
        });

        _controller!.setLooping(false);
        _controller!.setVolume(0.0);
        _controller!.play();

        _controller!.addListener(_checkVideoProgress);

        final duration = _controller!.value.duration;
        final safetyDuration = duration > const Duration(seconds: 1)
            ? duration + const Duration(milliseconds: 300)
            : const Duration(milliseconds: 3500);

        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(safetyDuration, _navigateToNextScreen);
      }).catchError((error) {
        debugPrint('[SplashScreen Video Error]: $error');
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(const Duration(milliseconds: 3000), _navigateToNextScreen);
      });
    } catch (e) {
      debugPrint('[SplashScreen Exception]: $e');
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(milliseconds: 3000), _navigateToNextScreen);
    }

    // Default safety timer so splash screen never gets stuck
    _fallbackTimer = Timer(const Duration(milliseconds: 4000), _navigateToNextScreen);
  }

  void _checkVideoProgress() {
    if (!mounted || _hasNavigated || _controller == null) return;
    if (_controller!.value.isInitialized) {
      final pos = _controller!.value.position;
      final dur = _controller!.value.duration;
      if (dur > const Duration(seconds: 1) && pos >= dur - const Duration(milliseconds: 200)) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    try {
      _controller?.pause();
      _controller?.removeListener(_checkVideoProgress);
    } catch (_) {}

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool isGuest = !auth.isLoggedIn;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => HomeScreen(isGuest: isGuest),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized || _controller == null) return;
    if (state == AppLifecycleState.resumed) {
      _controller!.play();
    } else if (state == AppLifecycleState.paused) {
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_checkVideoProgress);
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Instant branded placeholder layer (renders immediately at 0ms)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withAlpha(100),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.all_inclusive_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DZI INFINITY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Digital Services & Smart Payments',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Welcome Video Player Layer (Cross-fades in the moment it is ready)
          if (_isVideoInitialized && _controller != null && _controller!.value.isInitialized)
            AnimatedOpacity(
              opacity: _isVideoInitialized ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0
                        ? _controller!.value.size.width
                        : size.width,
                    height: _controller!.value.size.height > 0
                        ? _controller!.value.size.height
                        : size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
