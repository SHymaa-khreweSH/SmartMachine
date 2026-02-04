import 'package:flutter/material.dart';

class SpeedSelectScreen extends StatefulWidget {
  final int currentSpeed;
  const SpeedSelectScreen({super.key, required this.currentSpeed});

  @override
  State<SpeedSelectScreen> createState() => _SpeedSelectScreenState();
}

class _SpeedSelectScreenState extends State<SpeedSelectScreen> {
  static const bgColor = Color(0xFFF4F9FD);
  static const topColor = Color(0xFF0288D1);
  static const accent = Color(0xFF00BCD4);

  final speeds = [600, 800, 1000, 1200, 1400];
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = speeds.contains(widget.currentSpeed)
        ? widget.currentSpeed
        : 1200;
  }

  String _labelForSpeed(int s) {
    if (s <= 800) return "Gentle";
    if (s <= 1200) return "Normal";
    return "Strong";
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
          "Spin Speed",
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
            // 🔹 current speed
            Text(
              "Current speed: ${widget.currentSpeed} rpm",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 selected card
            Container(
              width: double.infinity,
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
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FAFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.speed_rounded, color: topColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$selected rpm",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labelForSpeed(selected),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.separated(
                itemCount: speeds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = speeds[i];
                  final isSelected = s == selected;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => selected = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                          Text(
                            "$s rpm",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const Spacer(),
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

            // 🔹 save
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context, selected),
                child: const Text(
                  "Save Speed",
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
