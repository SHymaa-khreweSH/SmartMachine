import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'program_select_screen.dart';
import 'temp_select_screen.dart';
import 'speed_select_screen.dart';
import 'notifications_screen.dart';

class MachineDetailsScreen extends StatefulWidget {
  final String machineId;

  const MachineDetailsScreen({
    super.key,
    required this.machineId,
  });

  @override
  State<MachineDetailsScreen> createState() => _MachineDetailsScreenState();
}

class _MachineDetailsScreenState extends State<MachineDetailsScreen> {
  Timer? _ticker;
  int _localRemainingSec = 0;
  String _status = "stopped";

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('washing_machines').doc(widget.machineId);

  CollectionReference<Map<String, dynamic>> get _currentWashCol =>
      _doc.collection('currentWash');

  // ===================== SAFE CAST =====================
  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  // ===================== CURRENT WASH (LATEST CW-###) =====================
  int _cwNumber(String id) {
    final match = RegExp(r'(\d+)$').firstMatch(id);
    if (match == null) return -1;
    return int.tryParse(match.group(1)!) ?? -1;
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _pickLatestCwDoc(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return null;

    docs.sort((a, b) {
      final na = _cwNumber(a.id);
      final nb = _cwNumber(b.id);
      if (na == -1 || nb == -1) return a.id.compareTo(b.id);
      return na.compareTo(nb);
    });

    return docs.last;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getLatestCurrentWashRef() async {
    final snap = await _currentWashCol.get();
    final latest = _pickLatestCwDoc(snap.docs);
    return latest?.reference;
  }

  Future<void> _updateLatestCurrentWash(Map<String, dynamic> patch) async {
    final cwRef = await _getLatestCurrentWashRef();
    if (cwRef == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No current wash session found (currentWash is empty)")),
        );
      }
      return;
    }
    await cwRef.update(patch);
  }

  // ===================== TIMER =====================
  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_status != "running") return;

      if (_localRemainingSec > 0) {
        setState(() => _localRemainingSec--);

        // نخزن remainingSec عشان لو طلع/رجع ما يضيع
        await _doc.update({'remainingSec': _localRemainingSec});
      } else {
        _ticker?.cancel();

        await _doc.update({
          'status': 'stopped',
          'remainingSec': 0,
        });

        if (mounted) {
          setState(() => _status = "stopped");
        }
      }
    });
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // ===================== START/PAUSE =====================
  Future<void> _toggleStartPause({
    required int suggestedSec,
    required int machineRemainingSec,
  }) async {
    // إذا بدنا نبدأ والوقت صفر -> نهيّئه من washTime
    if (_status != "running" && machineRemainingSec <= 0 && suggestedSec > 0) {
      await _doc.update({
        'remainingSec': suggestedSec,
        'status': 'running',
      });
      return;
    }

    // toggle طبيعي
    await _doc.update({
      'status': _status == "running" ? "stopped" : "running",
    });
  }

  // ===================== OVERRIDES (UPDATE CW مباشرة) =====================
  // ملاحظة: أي تعديل من المستخدم بنحدثه على آخر CW فقط
  // وبنوقف الغسالة ونصفر remainingSec عشان تكون البداية clean
  Future<void> _overrideProgram(String name, int sec) async {
    final washTimeMin = (sec / 60).ceil();

    await _updateLatestCurrentWash({
      'washProgarm': name,
      'washTime': washTimeMin,
    });

    await _doc.update({
      'status': 'stopped',
      'remainingSec': 0,
    });
  }

  Future<void> _overrideTemp(int temp) async {
    await _updateLatestCurrentWash({
      'washTempreture': temp,
    });

    await _doc.update({
      'status': 'stopped',
      'remainingSec': 0,
    });
  }

  Future<void> _overrideSpeed(int speed) async {
    await _updateLatestCurrentWash({
      'washSpeed': speed,
    });

    await _doc.update({
      'status': 'stopped',
      'remainingSec': 0,
    });
  }

  Color _statusColor(String status) {
    return status.toLowerCase() == "running"
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);
  }

  String _statusText(String status) {
    return status.toLowerCase() == "running" ? "Running" : "Stopped";
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4F9FD);
    const primary = Color(0xFF00BCD4);

    return Scaffold(
      backgroundColor: bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _doc.snapshots(),
        builder: (context, machineSnap) {
          if (!machineSnap.hasData) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }

          final mdata = machineSnap.data!.data() ?? {};
          final model = (mdata['model'] ?? 'Machine').toString();

          final status = (mdata['status'] ?? 'stopped').toString();
          final machineRemainingSec = _toInt(mdata['remainingSec']);

          _status = status;

          // Sync local remaining from Firestore when it changes
          if (_localRemainingSec != machineRemainingSec) {
            _localRemainingSec = machineRemainingSec;
            if (_status == "running") {
              _startTicker();
            } else {
              _ticker?.cancel();
            }
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _currentWashCol.snapshots(),
            builder: (context, cwSnap) {
              // default values
              String program = '--';
              int speed = 0;
              int temp = 0;
              int washTimeMin = 0;

              if (cwSnap.hasData) {
                final latest = _pickLatestCwDoc(cwSnap.data!.docs);
                if (latest != null) {
                  final wd = latest.data();
                  // ✅ الأسماء حسب الداتا عندك
                  program = (wd['washProgarm'] ?? '--').toString();
                  speed = _toInt(wd['washSpeed']);
                  temp = _toInt(wd['washTempreture']);
                  washTimeMin = _toInt(wd['washTime']); // بالدقائق
                }
              }

              final suggestedSec = washTimeMin * 60;

              // ✅ الدائرة: إذا الجهاز مش شغال وremainingSec=0، اعرض washTime
              final int displayTimeSec =
                  (_status == "running" || machineRemainingSec > 0)
                      ? _localRemainingSec
                      : suggestedSec;

              final progress = (suggestedSec > 0 && displayTimeSec > 0)
                  ? (1.0 - (displayTimeSec / suggestedSec)).clamp(0.0, 1.0)
                  : 0.0;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 350,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('washing_machines')
      .doc(widget.machineId)
      .collection('alerts')
      .where('isRead', isEqualTo: false)
      .snapshots(),
  builder: (context, snapshot) {
    final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    NotificationsScreen(machineId: widget.machineId),
              ),
            );
          },
        ),

        // 🔴 BADGE
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? "99+" : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  },
),

                      const SizedBox(width: 6),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 26),
                                const Text(
                                  "Machine Details",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  model,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status.toLowerCase() == "running"
                                                ? Icons.play_circle_fill_rounded
                                                : Icons.stop_circle_rounded,
                                            size: 16,
                                            color: _statusColor(status),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _statusText(status),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                Row(
                                  children: [
                                    SizedBox(
                                      width: 92,
                                      height: 92,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: progress == 0 ? null : progress,
                                            strokeWidth: 7,
                                            backgroundColor: Colors.white.withOpacity(0.22),
                                            valueColor: const AlwaysStoppedAnimation(primary),
                                          ),
                                          Text(
                                            _formatTime(displayTimeSec),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white.withOpacity(0.22)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Will run with",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "$program • ${temp}°C • ${speed} rpm",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 42,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primary,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                icon: Icon(
                                                  _status == "running"
                                                      ? Icons.pause_rounded
                                                      : Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                ),
                                                label: Text(
                                                  _status == "running" ? "Pause" : "Start",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed: () => _toggleStartPause(
                                                  suggestedSec: suggestedSec,
                                                  machineRemainingSec: machineRemainingSec,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: const Text(
                        "Current Wash Details",
                        style: TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: _Card(
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                icon: Icons.category_rounded,
                                label: "Program",
                                value: program,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                icon: Icons.speed_rounded,
                                label: "Speed",
                                value: "${speed} rpm",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                icon: Icons.thermostat_rounded,
                                label: "Temp",
                                value: "${temp} °C",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                      child: const Text(
                        "Customize Your Wash",
                        style: TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                      child: Column(
                        children: [
                          _OptionTileModern(
                            icon: Icons.category_rounded,
                            left: "Program",
                            right: program,
                            onTap: () async {
                              final result = await Navigator.push<ProgramResult>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProgramSelectScreen(currentProgram: program),
                                ),
                              );
                              if (result != null) {
                                await _overrideProgram(result.name, result.sec);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _OptionTileModern(
                            icon: Icons.thermostat_rounded,
                            left: "Temperature",
                            right: "${temp} °C",
                            onTap: () async {
                              final value = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TempSelectScreen(currentTemp: temp),
                                ),
                              );
                              if (value != null) {
                                await _overrideTemp(value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _OptionTileModern(
                            icon: Icons.speed_rounded,
                            left: "Speed",
                            right: "${speed} rpm",
                            onTap: () async {
                              final value = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SpeedSelectScreen(currentSpeed: speed),
                                ),
                              );
                              if (value != null) {
                                await _overrideSpeed(value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ===================== UI COMPONENTS =====================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0288D1)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTileModern extends StatelessWidget {
  final IconData icon;
  final String left;
  final String right;
  final VoidCallback onTap;

  const _OptionTileModern({
    required this.icon,
    required this.left,
    required this.right,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                left,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF263238),
                ),
              ),
            ),
            Flexible(
              child: Text(
                right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
