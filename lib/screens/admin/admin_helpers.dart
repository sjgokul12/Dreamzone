import 'package:flutter/material.dart';

// ==================== API CONFIGURATION ====================

class AdminApi {
  // Make sure this URL is correct for your Render deployment
  static const String baseUrl = 'https://dzi-backend.onrender.com/api/admin';
  
  // If you're testing locally, use this instead:
  // static const String baseUrl = 'http://localhost:5000/api/admin';
  
  // Helper method to build URLs
  static String getUrl(String endpoint) {
    // Remove any leading slash from endpoint
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }
}

// ==================== STATUS HELPERS ====================

Color statusColor(String? s) {
  switch (s?.toLowerCase()) {
    case 'open': return const Color(0xFF3B82F6);
    case 'in_progress': return const Color(0xFFF59E0B);
    case 'pending': return const Color(0xFFF97316);
    case 'processing': return const Color(0xFF6366F1);
    case 'completed': return const Color(0xFF10B981);
    case 'resolved': return const Color(0xFF10B981);
    case 'approved': return const Color(0xFF10B981);
    case 'rejected': return const Color(0xFFEF4444);
    case 'contacted': return const Color(0xFF8B5CF6);
    case 'closed': return const Color(0xFF6B7280);
    default: return const Color(0xFF6B7280);
  }
}

Widget statusChip(String? s) {
  final c = statusColor(s);
  String raw = (s ?? 'Pending').replaceAll('_', ' ');
  String label = raw.isEmpty ? 'Pending' : raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.withValues(alpha: 0.25), width: 1),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: c,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );
}

// ─── Custom Wave Sparkline Painter ─────────────────────────────────────────
class WaveSparklinePainter extends CustomPainter {
  final Color color;
  const WaveSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.7);
    path.cubicTo(w * 0.2, h * 0.2, w * 0.35, h * 0.9, w * 0.55, h * 0.4);
    path.cubicTo(w * 0.75, h * 0.1, w * 0.85, h * 0.8, w, h * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget statCard(String value, String label, IconData icon, Color color) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: color.withValues(alpha: 0.15), width: 1.4),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // Background soft tint
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, color: color, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 4,
            height: 12,
            child: CustomPaint(
              painter: WaveSparklinePainter(color: color.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A237E),
      ),
    ),
  );
}

Widget emptyState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inbox,
            size: 35,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget loadingState() {
  return const Center(
    child: CircularProgressIndicator(color: Color(0xFF1A237E)),
  );
}

void showConfirmDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm, {
  String confirmText = 'Confirm',
  Color confirmColor = Colors.red,
}) {
  final isPhone = MediaQuery.of(context).size.width < 600;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1A237E),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 13),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
      actionsPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 8 : 16,
        vertical: 8,
      ),
    ),
  );
}

void showSnackBar(
  BuildContext context,
  String message, {
  bool success = true,
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: duration,
      margin: const EdgeInsets.all(8),
    ),
  );
}

String formatDate(String? dateStr) {
  if (dateStr == null) return 'N/A';
  try {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  } catch (e) {
    return dateStr;
  }
}

String timeAgo(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${diff.inDays ~/ 30} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  } catch (e) {
    return '';
  }
}