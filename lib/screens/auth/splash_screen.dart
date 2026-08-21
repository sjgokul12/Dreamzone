import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

/// Full-screen responsive video Splash Screen.
/// Plays `assets/Welcome.mp4` with no text or buttons,
/// and automatically transitions to the Home Screen upon completion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
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
    _controller = VideoPlayerController.asset('assets/Welcome.mp4');
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isVideoInitialized = true;
      });

      _controller.setLooping(false);
      _controller.setVolume(0.0);
      _controller.play();

      // Listen for video completion
      _controller.addListener(_checkVideoProgress);

      // Dynamic fallback timer based on video duration
      final duration = _controller.value.duration;
      final safetyDuration = duration > Duration.zero
          ? duration + const Duration(milliseconds: 300)
          : const Duration(seconds: 4);

      _fallbackTimer = Timer(safetyDuration, _navigateToNextScreen);
    }).catchError((error) {
      debugPrint('[SplashScreen Video Error]: $error');
      // If video fails to load, navigate after short splash delay
      _fallbackTimer = Timer(const Duration(seconds: 2), _navigateToNextScreen);
    });

    // Hard fallback in case initialize hangs
    _fallbackTimer = Timer(const Duration(seconds: 6), _navigateToNextScreen);
  }

  void _checkVideoProgress() {
    if (!mounted || _hasNavigated) return;
    if (_controller.value.isInitialized) {
      final pos = _controller.value.position;
      final dur = _controller.value.duration;
      if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 150)) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool isGuest = !auth.isLoggedIn;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => HomeScreen(isGuest: isGuest),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _controller.play();
    } else if (state == AppLifecycleState.paused) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _controller.removeListener(_checkVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: _isVideoInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width > 0
                      ? _controller.value.size.width
                      : size.width,
                  height: _controller.value.size.height > 0
                      ? _controller.value.size.height
                      : size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
