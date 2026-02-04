import 'package:flutter/material.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4FC3F7), // Ice Blue
              Color(0xFF0288D1), // Deep Blue
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.08),

                    // ✅ أيقونة بدل الصورة
                    Icon(
                      Icons.local_laundry_service_rounded,
                      size: 140,
                      color: Colors.white.withOpacity(0.9),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Smart Washing\nMachine",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Control your washer easily and get alerts instantly",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // الكارد السفلي
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 26,
                        horizontal: 22,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Welcome!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Get Started",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isRtl
                                      ? Icons.arrow_back
                                      : Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
