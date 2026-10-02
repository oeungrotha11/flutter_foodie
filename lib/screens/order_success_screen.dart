import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pos_product/screens/home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final double total;

  const OrderSuccessScreen({
    super.key,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                // =================================
                // SUCCESS ANIMATION
                // =================================

                SizedBox(
                  width: 180,
                  height: 180,

                  child: Lottie.asset(
                    'assets/lotties/success.json',
                    repeat: false,
                  ),
                ),

                const SizedBox(height: 20),

                // =================================
                // TITLE
                // =================================

                const Text(
                  'Order Successful!',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 10),

                // =================================
                // DESCRIPTION
                // =================================

                Text(
                  'Your order has been placed successfully.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 25),

                // =================================
                // ORDER NUMBER
                // =================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  child: Column(
                    children: [
                      Text(
                        'Order Number',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        '#ORD-00125',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Total: \$${total.toStringAsFixed(2)}',

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF5233B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // =================================
                // BACK TO HOME
                // =================================

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,

                        MaterialPageRoute(
                          builder: (_) =>
                              const HomeScreen(),
                        ),

                        (route) => false,
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF5233B),

                      foregroundColor: Colors.white,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}