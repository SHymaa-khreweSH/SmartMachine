import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // نفس ألوان Home
  static const bg = Color(0xFFF4F9FD);
  static const primary = Color(0xFF00BCD4);
  static const inactive = Color(0xFF94A3B8);

  bool notificationsOn = true;
  bool wifiConnected = true;

  String? _uid;

  // للجرس + badge (نختار ماكينة مناسبة)
  String? _preferredMachineId;

  int _unreadAlertsCount = 0; // لتخزين عدد الإشعارات غير المقروءة

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadUnreadAlerts(); // إضافة تحميل الإشعارات الغير مقروءة
  }

  void _openNotificationsOrWarn() {
    if (_preferredMachineId != null && _preferredMachineId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(machineId: _preferredMachineId!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No connected washing machine")),
      );
    }
  }

  // تحميل الإشعارات الغير مقروءة
  void _loadUnreadAlerts() {
    if (_uid == null) return;

    FirebaseFirestore.instance
        .collection('washing_machines')
        .where('user_id', isEqualTo: _uid)
        .snapshots()
        .listen((machinesSnapshot) {
      int totalUnread = 0;

      for (final machine in machinesSnapshot.docs) {
        FirebaseFirestore.instance
            .collection('washing_machines')
            .doc(machine.id)
            .collection('alerts')
            .where('isRead', isEqualTo: false)
            .snapshots()
            .listen((alertsSnapshot) {
          setState(() {
            _unreadAlertsCount = alertsSnapshot.docs.length;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),

      body: uid == null
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Preferences",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SettingCard(
                    icon: Icons.notifications_active_rounded,
                    title: "Notifications",
                    trailing: Switch(
                      value: notificationsOn,
                      activeColor: primary,
                      onChanged: (v) => setState(() => notificationsOn = v),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SettingCard(
                    icon: Icons.wifi_rounded,
                    title: "Wi-Fi Status",
                    trailing: Text(
                      wifiConnected ? "Connected" : "Disconnected",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: wifiConnected
                            ? const Color(0xFF16A34A)
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// ===================== SETTING CARD =====================
class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF2FAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0288D1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
