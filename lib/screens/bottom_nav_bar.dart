import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadCount; // إضافة العدد هنا

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.unreadCount, // إضافة العدد هنا
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 64 + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(Icons.home_rounded, "Home", currentIndex == 0,
                  () => onTap(0)),
              _AlertNavIcon(
                count: unreadCount, // إضافة العدد هنا
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 36), // مكان الـ FAB
              _NavIcon(Icons.settings_rounded, "Settings",
                  currentIndex == 2, () => onTap(2)),
              _NavIcon(Icons.person_rounded, "Profile",
                  currentIndex == 3, () {}), // Profile, لا تغيير هنا
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon(this.icon, this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00BCD4) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertNavIcon extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AlertNavIcon({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.notifications_rounded, color: Color(0xFF94A3B8), size: 24),
                SizedBox(height: 2),
                Text(
                  "Alerts",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    height: 1.0,
                  ),
                ),
              ],
            ),
            // 🔴 Badge
            if (count > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
