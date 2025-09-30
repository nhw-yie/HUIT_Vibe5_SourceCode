import 'package:flutter/material.dart';
import 'package:status_air/features/map/presentation/pages/page_map.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 170, 245, 255), // xanh đậm
              Color.fromARGB(255, 214, 236, 255), // xanh dương
              Color.fromARGB(255, 255, 255, 255), // xanh ngọc
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF42A5F5),
                    Color(0xFF4DD0E1),
                    Color(0xFF81D4FA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: const Text(
                "Người dùng",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              accountEmail: const Text(
                "user@example.com",
                style: TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 36, color: Colors.blue[600]),
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    text: "Trang chủ",
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.map,
                    text: "Bản đồ",
                    onTap: () {
                      Navigator.pop(context); // đóng drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeMap(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    text: "Cài đặt",
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 99, 99, 99)),
      title: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.white.withOpacity(0.05), // nền trong suốt nhẹ
      hoverColor: Colors.white.withOpacity(0.15), // khi rê chuột (web/desktop)
    );
  }
}
