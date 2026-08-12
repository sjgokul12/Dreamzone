import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _controller = VideoPlayerController.asset('assets/Welcome.mp4');
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isVideoInitialized) {
        _controller.play();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_isVideoInitialized) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. Full Screen Background Video
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: _isVideoInitialized
                  ? SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    )
                  : Container(color: const Color(0xFF121212)),
            ),
          ),

          // 2. Dark Gradient Overlay for readability
          AnimatedOpacity(
            opacity: _isVideoInitialized ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    const Color(0xFF121212).withValues(alpha: 0.8),
                    const Color(0xFF121212),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Bottom Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isVideoInitialized ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Small header with icon
                      Row(
                        children: [
                          const Icon(
                            Icons.all_inclusive_rounded,
                            color: Color(0xFFFF3366),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DZI Infinity',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main Title
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(
                              text: 'Welcome to\n',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'DZI Infinity',
                              style: TextStyle(color: Color(0xFFFF3366)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Step into a world where all your digital services, travels, and more come alive in one place.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[300],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Custom Animated Swipe Button
                      // Tap Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 500),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3366),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFFF3366).withValues(alpha: 0.5),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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

class SwipeableButton extends StatefulWidget {
  final VoidCallback onSwipeComplete;

  const SwipeableButton({super.key, required this.onSwipeComplete});

  @override
  State<SwipeableButton> createState() => _SwipeableButtonState();
}

class _SwipeableButtonState extends State<SwipeableButton> with TickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double buttonWidth = 64.0;
        final double maxDrag = maxWidth - buttonWidth;

        return GestureDetector(
          onTap: () {
            if (!_isCompleted) {
              setState(() {
                _isCompleted = true;
                _dragPosition = maxDrag;
              });
              widget.onSwipeComplete();
            }
          },
          onHorizontalDragUpdate: (details) {
            if (_isCompleted) return;
            setState(() {
              _dragPosition += details.primaryDelta!;
              if (_dragPosition < 0) {
                _dragPosition = 0;
              } else if (_dragPosition >= maxDrag) {
                _dragPosition = maxDrag;
                _isCompleted = true;
                widget.onSwipeComplete();
              }
            });
          },
          onHorizontalDragEnd: (details) {
            if (!_isCompleted) {
              setState(() {
                _dragPosition = 0.0;
              });
            }
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Stack(
              children: [
                // Text and animated chevrons
                Row(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 24.0),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                // Draggable button
                Positioned(
                  left: _dragPosition,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3366), Color(0xFFFF5E83)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
