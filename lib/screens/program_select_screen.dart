import 'package:flutter/material.dart';

class ProgramResult {
  final String name;
  final int sec;
  ProgramResult(this.name, this.sec);
}

class ProgramSelectScreen extends StatefulWidget {
  final String currentProgram;
  const ProgramSelectScreen({super.key, required this.currentProgram});

  @override
  State<ProgramSelectScreen> createState() => _ProgramSelectScreenState();
}

class _ProgramSelectScreenState extends State<ProgramSelectScreen> {
  static const bgColor = Color(0xFFF4F9FD);
  static const topColor = Color(0xFF0288D1);
  static const cardColor = Colors.white;
  static const accent = Color(0xFF00BCD4);

  final programs = <ProgramResult>[
    ProgramResult("Cotton", 1800),
    ProgramResult("Quick", 900),
    ProgramResult("Delicate", 1200),
    ProgramResult("Heavy", 2400),
    ProgramResult("Rinse", 600),
  ];

  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.currentProgram;
  }

  String _min(int sec) => "${sec ~/ 60} min";

  IconData _iconForProgram(String name) {
    switch (name.toLowerCase()) {
      case 'cotton':
        return Icons.local_laundry_service_rounded;
      case 'quick':
        return Icons.flash_on_rounded;
      case 'delicate':
        return Icons.spa_rounded;
      case 'heavy':
        return Icons.fitness_center_rounded;
      case 'rinse':
        return Icons.water_drop_rounded;
      default:
        return Icons.local_laundry_service;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Select Program",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Current program
            Text(
              "Current program: ${widget.currentProgram}",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: programs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = programs[i];
                  final isSelected = selected == p.name;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => selected = p.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? accent : Colors.transparent,
                          width: 2,
                        ),
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
                            child: Icon(
                              _iconForProgram(p.name),
                              color: topColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Estimated time: ${_min(p.sec)}",
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: accent, size: 26)
                          else
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: selected == null
                    ? null
                    : () {
                        final chosen = programs.firstWhere(
                          (p) => p.name == selected,
                          orElse: () => programs[0],
                        );
                        Navigator.pop(context, chosen);
                      },
                child: const Text(
                  "Save Program",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
