import 'package:flutter/material.dart';

class TempSelectScreen extends StatefulWidget {
  final int currentTemp;
  const TempSelectScreen({super.key, required this.currentTemp});

  @override
  State<TempSelectScreen> createState() => _TempSelectScreenState();
}

class _TempSelectScreenState extends State<TempSelectScreen> {
  static const bgColor = Color(0xFFF4F9FD);
  static const topColor = Color(0xFF0288D1);
  static const accent = Color(0xFF00BCD4);

  final temps = [20, 30, 40, 60, 90];
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = temps.contains(widget.currentTemp) ? widget.currentTemp : 40;
  }

  String _labelForTemp(int t) {
    if (t <= 30) return "Cold / Gentle";
    if (t <= 40) return "Recommended";
    if (t <= 60) return "Hot";
    return "Very Hot";
  }

  IconData _iconForTemp(int t) {
    if (t <= 30) return Icons.ac_unit_rounded;
    if (t <= 40) return Icons.thermostat_rounded;
    if (t <= 60) return Icons.local_fire_department_rounded;
    return Icons.whatshot_rounded;
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
          "Water Temperature",
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
            // 🔹 current temp
            Text(
              "Current temperature: ${widget.currentTemp}°C",
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
                    child: Icon(_iconForTemp(selected), color: topColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$selected°C",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labelForTemp(selected),
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
                itemCount: temps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final t = temps[i];
                  final isSelected = t == selected;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => selected = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            "$t°C",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: accent, size: 26)
                          else
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
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
                  "Save Temperature",
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
