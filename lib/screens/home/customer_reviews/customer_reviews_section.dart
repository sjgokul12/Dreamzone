import 'package:flutter/material.dart';

/// Standalone Customer Reviews component with interactive carousel,
/// 3D Star banner, rating summary stats, and animated dot indicators.
class CustomerReviewsSection extends StatefulWidget {
  const CustomerReviewsSection({super.key});

  @override
  State<CustomerReviewsSection> createState() => _CustomerReviewsSectionState();
}

class _CustomerReviewsSectionState extends State<CustomerReviewsSection> {
  final PageController _reviewController = PageController(viewportFraction: 0.88);
  int _currentReview = 0;

  final List<Map<String, dynamic>> _reviewsList = const [
    {
      'name': 'Priya Mehta',
      'role': 'Freelancer',
      'review': 'Amazing experience! Super fast service and easy to use. The support team is very helpful and resolved my issue immediately.',
      'asset': 'assets/Priya.png',
      'stars': 5,
    },
    {
      'name': 'Amit Patel',
      'role': 'Business Owner',
      'review': 'Secure, efficient, and reliable! Applying for government and PAN services has never been this simple and hassle-free.',
      'asset': 'assets/Amit.png',
      'stars': 5,
    },
    {
      'name': 'Sneha Sharma',
      'role': 'Consultant',
      'review': 'Most reliable platform for all my business documentation and tax needs. Highly recommend to everyone nationwide!',
      'asset': 'assets/Sneha.png',
      'stars': 5,
    },
    {
      'name': 'Deepa Nair',
      'role': 'Entrepreneur',
      'review': 'ITR and Fastag filing was effortless. The customer support guided me step by step with great patience and care.',
      'asset': 'assets/Deepa.png',
      'stars': 5,
    },
    {
      'name': 'Vikram Rao',
      'role': 'Developer',
      'review': 'Incredible speed and genuine support. Received my digital soft copy within minutes! Best application ever.',
      'asset': 'assets/Vikram.png',
      'stars': 5,
    },
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Left Heading & Subtitle, Right 3D Star speech bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF161A3A),
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Real feedback from real people\nwho love our services',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Big 3D Star Illustration (Star.png)
              Image.asset(
                'assets/Star.png',
                width: 145,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 65,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 3 Rating Cards Bar (4.8/5, 12K+, 98%)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildRatingStatItem(
                  icon: Icons.star_rounded,
                  value: '4.8/5',
                  label: 'Average Rating',
                ),
                Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),
                _buildRatingStatItem(
                  icon: Icons.groups_rounded,
                  value: '12K+',
                  label: 'Happy Customers',
                ),
                Container(width: 1, height: 42, color: const Color(0xFFF1F5F9)),
                _buildRatingStatItem(
                  icon: Icons.chat_bubble_rounded,
                  value: '98%',
                  label: 'Positive Reviews',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Customer Review Cards Slider
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _reviewController,
                  itemCount: _reviewsList.length,
                  onPageChanged: (idx) => setState(() => _currentReview = idx),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final t = _reviewsList[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE9D5FF).withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Quote badge on left, 5 stars on right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '“',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7C3AED),
                                    height: 0.9,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  t['stars'] as int,
                                  (i) => const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Review Text
                          Expanded(
                            child: Text(
                              t['review'] as String,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E1B4B),
                                height: 1.45,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bottom Row: Large Avatar, Name + Verified Badge, Role, and big quote mark
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE2E8F0),
                                child: ClipOval(
                                  child: Image.asset(
                                    t['asset'] as String,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.person,
                                      color: Color(0xFF7C3AED),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          t['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF161A3A),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.verified,
                                          color: Color(0xFF7C3AED),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t['role'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                '”',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0x307C3AED),
                                  height: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Floating Left Navigation Arrow Button
              Positioned(
                left: 0,
                child: GestureDetector(
                  onTap: () {
                    if (_currentReview > 0) {
                      _reviewController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF7C3AED),
                      size: 26,
                    ),
                  ),
                ),
              ),

              // Floating Right Navigation Arrow Button
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    if (_currentReview < _reviewsList.length - 1) {
                      _reviewController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF7C3AED),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_reviewsList.length, (index) {
              final isSelected = _currentReview == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: isSelected ? 22 : 7,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFDDD6FE),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// Alias for flexible import usage
typedef CustomerReviewsScreen = CustomerReviewsSection;
