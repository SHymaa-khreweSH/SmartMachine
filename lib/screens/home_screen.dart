import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'details_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'scan_qr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadAlertsCount = 0;

  String userName = "Loading...";
  String? _uid;

  
  String? _preferredMachineId;

 
  int _navIndex = 0;

  @override
void initState() {
  super.initState();
  _uid = FirebaseAuth.instance.currentUser?.uid;
  _loadUserName();
  _listenToUnreadAlerts(); 
}

  Future<void> _loadUserName() async {
    try {
      if (_uid == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(_uid)
          .get();

      if (!mounted) return;
      setState(() {
        userName = snapshot.data()?['name'] ?? 'User';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => userName = "User");
    }
  }

  void _listenToUnreadAlerts() {
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


  Future<void> _removeMachine(String docId) async {
    await FirebaseFirestore.instance
        .collection('washing_machines')
        .doc(docId)
        .update({'user_id': ''});
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

  void _onNavTap(int index) {
    setState(() => _navIndex = index);

    
    if (index == 0) return;

    if (index == 1) {
      _openNotificationsOrWarn();
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),

      bottomNavigationBar: Builder(
  builder: (context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
       
        height: 70 + bottomInset,
        child: Padding(
          
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                label: "Home",
                isActive: _navIndex == 0,
                onTap: () => _onNavTap(0),
              ),
              SizedBox(width: 25),
              _AlertNavIcon(
                count: _unreadAlertsCount,
                onTap: () => _onNavTap(1),
                  ),
                  SizedBox(width: 30),

            _NavIcon(
                icon: Icons.qr_code_scanner,
                label: "Scan QR",  
                isActive: false,    
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanQrScreen()),
                  );
                },
              ), 
            const SizedBox(width: 36), 
              _NavIcon(
                icon: Icons.person_rounded,
                label: "Profile",
                isActive: false,
                onTap: () => _onNavTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  },
),



      body: uid == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('washing_machines')
                  .where('user_id', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
                  );
                }

                // Empty / No data
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                 
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _HeaderSliver(
                        userName: userName,
                        connectedCount: 0,
                        runningCount: 0,
                        onProfileTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                          child: _EmptyMachinesCard(
                            onScan: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ScanQrScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }

                
                
                final runningDoc = docs.cast<QueryDocumentSnapshot?>().firstWhere(
                      (d) =>
                          (d?.data() as Map<String, dynamic>?)?['status'] ==
                          'running',
                      orElse: () => null,
                    );
                _preferredMachineId = (runningDoc ?? docs.first).id;

              
                int runningCount = 0;
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  if (data['status'] == 'running') runningCount++;
                }

                return RefreshIndicator(
                  color: const Color(0xFF00BCD4),
                  onRefresh: () async {
                    
                    await _loadUserName();
                  },
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _HeaderSliver(
                        userName: userName,
                        connectedCount: docs.length,
                        runningCount: runningCount,
                        onProfileTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),

                     
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Paired Machines",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ScanQrScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: const Text("Add"),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF0288D1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ✅ Grid فخم بدل Wrap
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;

                              final model =
                                  (data['model'] ?? 'Washing Machine')
                                      .toString();
                              final status =
                                  (data['status'] ?? 'idle').toString();

                              return _MachineCard(
                                name: model,
                                status: status,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MachineDetailsScreen(
                                        machineId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Remove machine"),
                                      content: const Text(
                                        "Do you want to remove this washing machine from your account?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await _removeMachine(doc.id);
                                          },
                                          child: const Text(
                                            "Remove",
                                            style:
                                                TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: docs.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.78, 
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// ======================= HEADER SLIVER =======================
class _HeaderSliver extends StatelessWidget {
  final String userName;
  final int connectedCount;
  final int runningCount;
  final VoidCallback onProfileTap;

  const _HeaderSliver({
    required this.userName,
    required this.connectedCount,
    required this.runningCount,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  const Icon(Icons.waves_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Smart Washing",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  
                ],
              ),

              const SizedBox(height: 14),

              // Welcome text
              const Text(
                "Welcome back,",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              // Stats row
              Row(
                children: [
                  _StatPill(
                    icon: Icons.link_rounded,
                    label: "Paired",
                    value: connectedCount.toString(),
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    icon: Icons.play_circle_fill_rounded,
                    label: "Running",
                    value: runningCount.toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================= EMPTY STATE =======================
class _EmptyMachinesCard extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyMachinesCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_laundry_service_rounded,
              size: 64, color: Color(0xFF4FC3F7)),
          const SizedBox(height: 14),
          const Text(
            "No machines yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Scan the QR code on your washing machine to add it.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.35),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text(
              "Scan QR",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// ======================= MACHINE CARD =======================
class _MachineCard extends StatelessWidget {
  final String name;
  final String status;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MachineCard({
    required this.name,
    required this.status,
    required this.onTap,
    required this.onLongPress,
  });

  bool get isRunning => status.toLowerCase() == 'running';
  bool get isIdle => status.toLowerCase() == 'idle';

  String get statusText {
    if (isRunning) return "Running";
    if (isIdle) return "Idle";
    return status.isEmpty ? "Unknown" : status;
  }

  IconData get statusIcon {
    if (isRunning) return Icons.play_circle_fill_rounded;
    if (isIdle) return Icons.pause_circle_filled_rounded;
    return Icons.info_rounded;
  }

  Color get statusColor {
    if (isRunning) return const Color(0xFF16A34A);
    if (isIdle) return const Color(0xFF0288D1);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row (icon + status pill)
Row(
  children: [
    Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.local_laundry_service_rounded,
        color: Color(0xFF0288D1),
      ),
    ),

    const SizedBox(width: 10),

    
    Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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


            const SizedBox(height: 14),

            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),

            const Spacer(),

            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  "View details",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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

/// ======================= NAV ICON =======================
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF00BCD4) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(icon, color: color, size: 24),
    const SizedBox(height: 2),          
    Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,  
      style: TextStyle(
        color: color,
        fontSize: 10,                   
        fontWeight: FontWeight.w700,
        height: 1.0,                    
      ),
    ),
  ],
),

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
    final color = const Color(0xFF94A3B8);

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

