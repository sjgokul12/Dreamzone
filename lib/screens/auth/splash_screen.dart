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

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool isGuest = !auth.isLoggedIn;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => HomeScreen(isGuest: isGuest),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Clean solid black backdrop
          const ColoredBox(color: Colors.black),

          // Welcome Video Player Layer (Plays full-screen)
          if (_isVideoInitialized && _controller != null && _controller!.value.isInitialized)
            SizedBox(
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
        ],
      ),
    );
  }
}
