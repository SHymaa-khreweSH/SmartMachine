import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'scan_qr_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Loading...";
  String email = "";

  bool showChangePassBox = false;
  bool changingPass = false;
  String? passError;

  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  int _navIndex = 3; 
  String? _preferredMachineId;

  int _unreadAlertsCount = 0; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferredMachine();
    _listenToUnreadAlerts(); 
  }

  @override
  void dispose() {
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    email = user.email ?? "";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;
    setState(() {
      userName = doc.data()?['name'] ?? 'User';
    });
  }

  Future<void> _loadPreferredMachine() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('washing_machines')
        .where('user_id', isEqualTo: user.uid)
        .get();

    if (snap.docs.isEmpty) return;

    final running = snap.docs.firstWhere(
      (d) => d['status'] == 'running',
      orElse: () => snap.docs.first,
    );

    _preferredMachineId = running.id;
  }

  // ================= CHANGE PASSWORD =================
  Future<void> _changePassword() async {
    setState(() {
      changingPass = true;
      passError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final oldPass = oldPassCtrl.text.trim();
      final newPass = newPassCtrl.text.trim();
      final confirm = confirmPassCtrl.text.trim();

      if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
        throw Exception("Please fill all fields");
      }
      if (newPass.length < 6) {
        throw Exception("Password must be at least 6 characters");
      }
      if (newPass != confirm) {
        throw Exception("Passwords do not match");
      }

      final email = user.email;
      if (email == null) throw Exception("No email found");

      final cred =
          EmailAuthProvider.credential(email: email, password: oldPass);

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);

      oldPassCtrl.clear();
      newPassCtrl.clear();
      confirmPassCtrl.clear();

      setState(() {
        showChangePassBox = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully ✅")),
        );
      }
    } catch (e) {
      setState(() {
        passError = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() => changingPass = false);
      }
    }
  }

  // ======================== Listen to unread alerts ========================
  void _listenToUnreadAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('washing_machines')
        .where('user_id', isEqualTo: user.uid)
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

  void _onNavTap(int index) {
    setState(() => _navIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 1) {
      if (_preferredMachineId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No connected washing machine")),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NotificationsScreen(machineId: _preferredMachineId!),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),

      // ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            const Icon(
              Icons.person_rounded,
              size: 90,
              color: Color(0xFF4FC3F7),
            ),
            const SizedBox(height: 12),

            Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 28),

            // ===== CHANGE PASSWORD =====
            _ProfileButton(
              label: showChangePassBox ? "Cancel" : "Change Password",
              icon: Icons.lock_outline,
              onTap: () {
                setState(() {
                  showChangePassBox = !showChangePassBox;
                  passError = null;
                });
              },
            ),

            if (showChangePassBox) _buildChangePasswordBox(),

            const SizedBox(height: 24),

            // ===== LOGOUT =====
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CHANGE PASSWORD BOX =================
  Widget _buildChangePasswordBox() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _passField(oldPassCtrl, "Old password"),
          _passField(newPassCtrl, "New password"),
          _passField(confirmPassCtrl, "Confirm new password"),

          if (passError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                passError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: changingPass ? null : _changePassword,
              child: changingPass
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF2F6F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263238),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
