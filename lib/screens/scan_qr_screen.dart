import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool scanned = false;
  bool torchOn = false;
  CameraFacing facing = CameraFacing.back;

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Scan QR",
          style: TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF263238)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: "Flash",
            icon: Icon(
              torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: const Color(0xFF263238),
            ),
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => torchOn = !torchOn);
            },
          ),
          IconButton(
            tooltip: "Flip camera",
            icon: const Icon(Icons.cameraswitch_rounded, color: Color(0xFF263238)),
            onPressed: () async {
              await _controller.switchCamera();
              setState(() {
                facing = facing == CameraFacing.back
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Stack(
        children: [
          // الكاميرا
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (scanned) return;

              final String? machineId = capture.barcodes.first.rawValue;

              if (machineId == null || machineId.trim().isEmpty) {
                _showMsg("Invalid QR code");
                return;
              }

              setState(() => scanned = true);

              final ok = await _linkMachineToUser(machineId.trim());

              if (!mounted) return;

              if (ok) {
                _showMsg("✅ Machine linked successfully");
                Navigator.pop(context); // رجوع للـ Home
              } else {
                // فشل الربط: رجّع scanned=false عشان تقدر تعيدي المحاولة
                setState(() => scanned = false);
              }
            },
          ),

          // Overlay (إطار المسح)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ),
          ),

          // فتحّة شفافة + إطار
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF00BCD4),
                  width: 3,
                ),
              ),
            ),
          ),

          // نص إرشادي تحت
          Positioned(
            left: 18,
            right: 18,
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0288D1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scanned
                          ? "Linking machine..."
                          : "Point the camera at the QR code on your washing machine.",
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (scanned)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00BCD4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ترجع true إذا الربط تم بنجاح، false إذا فشل
  Future<bool> _linkMachineToUser(String machineId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) _showMsg("You must login first");
      return false;
    }

    final docRef = FirebaseFirestore.instance
        .collection('washing_machines')
        .doc(machineId);

    final doc = await docRef.get();

    if (!doc.exists) {
      if (mounted) _showMsg("❌ Machine not found");
      return false;
    }

    final data = doc.data() as Map<String, dynamic>;
    final currentUserId = (data['user_id'] ?? '').toString();

    // إذا مربوط لحدا غيرك
    if (currentUserId.isNotEmpty && currentUserId != user.uid) {
      if (mounted) _showMsg("❌ This machine is already linked to another user");
      return false;
    }

    await docRef.update({
      'user_id': user.uid,
    });

    return true;
  }
}
