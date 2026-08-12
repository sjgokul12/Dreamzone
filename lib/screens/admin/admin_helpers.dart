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
  switch (s) {
    case 'open': return Colors.blue;
    case 'in_progress': return Colors.orange;
    case 'pending': return Colors.orange;
    case 'processing': return Colors.blue;
    case 'completed': return Colors.green;
    case 'resolved': return Colors.green;
    case 'approved': return Colors.green;
    case 'rejected': return Colors.red;
    case 'contacted': return Colors.purple;
    case 'closed': return Colors.grey;
    default: return Colors.grey;
  }
}

Widget statusChip(String? s) {
  final c = statusColor(s);
  String label = (s ?? '').replaceAll('_', ' ').toUpperCase();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withAlpha(30),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: c,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  );
}

Widget statCard(String value, String label, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(30),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(40), color.withAlpha(15)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
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