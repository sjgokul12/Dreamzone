import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Map<String, dynamic> adminUser;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.adminUser,
    required this.onItemSelected,
    required this.onLogout,
  });

  final List<Map<String, dynamic>> _menuItems = const [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'index': 0},
    {'title': 'Users', 'icon': Icons.people, 'index': 1},
    {'title': 'Applications', 'icon': Icons.receipt_long, 'index': 2},
    {'title': 'Services', 'icon': Icons.miscellaneous_services, 'index': 3},
    {'title': 'Announcements', 'icon': Icons.campaign, 'index': 4},
    {'title': 'Careers', 'icon': Icons.work, 'index': 5},
    {'title': 'Help Center', 'icon': Icons.support_agent, 'index': 6},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Phone: Bottom navigation bar style
    if (screenWidth < 600) {
      return Container(
        width: double.infinity,
        color: const Color(0xFF1A237E),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(children: [
              CircleAvatar(radius: 14, backgroundColor: Colors.white24, child: Text((adminUser['name'] ?? 'A')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              const SizedBox(width: 8),
              Expanded(child: Text(adminUser['name'] ?? 'Admin', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
              IconButton(icon: const Icon(Icons.logout, color: Colors.white70, size: 18), onPressed: onLogout, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _menuItems.length,
              itemBuilder: (ctx, i) {
                final item = _menuItems[i];
                final isSelected = selectedIndex == item['index'];
                return GestureDetector(
                  onTap: () => onItemSelected(item['index'] as int),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: isSelected ? Colors.white.withAlpha(25) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(item['icon'] as IconData, color: isSelected ? Colors.white : Colors.white54, size: 18),
                      const SizedBox(height: 2),
                      Text(item['title'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 9, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );
    }

    // Tablet: NavigationRail
    if (screenWidth < 900) {
      return Container(
        width: 70,
        color: const Color(0xFF1A237E),
        child: Column(children: [
          const SizedBox(height: 12),
          CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Text((adminUser['name'] ?? 'A')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _menuItems.map((item) {
                final isSelected = selectedIndex == item['index'];
                return GestureDetector(
                  onTap: () => onItemSelected(item['index'] as int),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: isSelected ? Colors.white.withAlpha(25) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(item['icon'] as IconData, color: isSelected ? Colors.white : Colors.white54, size: 20),
                      const SizedBox(height: 3),
                      Text((item['title'] as String).substring(0, 3), style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 8, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white54, size: 18), onPressed: onLogout),
          const SizedBox(height: 8),
        ]),
      );
    }

    // Desktop: Full sidebar
    return Container(
      width: 240,
      color: const Color(0xFF1A237E),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))),
          child: Column(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28)),
            const SizedBox(height: 12),
            const Text('DZI Admin Panel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(adminUser['name'] ?? 'Administrator', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.green.withAlpha(40), borderRadius: BorderRadius.circular(10)), child: const Text('Online', style: TextStyle(color: Colors.greenAccent, fontSize: 9))),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: _menuItems.map((item) {
              final isSelected = selectedIndex == item['index'];
              return Container(
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(color: isSelected ? Colors.white.withAlpha(25) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: isSelected ? Colors.white.withAlpha(30) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(item['icon'] as IconData, color: isSelected ? Colors.white : Colors.white54, size: 20)),
                  title: Text(item['title'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                  trailing: isSelected ? Container(width: 3, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))) : null,
                  onTap: () => onItemSelected(item['index'] as int),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
              title: const Text('Logout', style: TextStyle(color: Colors.white70, fontSize: 13)),
              onTap: onLogout,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ]),
    );
  }
}