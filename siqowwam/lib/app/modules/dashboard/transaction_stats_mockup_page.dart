import 'package:flutter/material.dart';

class TransactionStatsMockupPage extends StatelessWidget {
  const TransactionStatsMockupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Very dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Statistik Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            alignment: Alignment.center,
            child: const Text(
              '2026',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Month Selector
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                _buildMonthItem(
                  'Jan',
                  isSelected: true,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF448AFF),
                      Color(0xFF7C4DFF),
                    ], // Blue-Purple
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                _buildMonthItem('Feb'),
                _buildMonthItem('Mar'),
                _buildMonthItem('Apr'),
                _buildMonthItem('May'),
                _buildMonthItem('Jun'),
                _buildMonthItem('Jul'),
                _buildMonthItem('Aug'),
                _buildMonthItem('Sep'),
                _buildMonthItem('Oct'),
                _buildMonthItem('Nov'),
                _buildMonthItem('Dec'),
              ],
            ),
            const SizedBox(height: 32),

            // Tab Filter (All / In / Out)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'All',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'In',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF3E2723,
                        ).withOpacity(0.8), // Dark red background
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFFFF5252).withOpacity(0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Out',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Total Expense Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: const [
                  Text(
                    'Total Expense',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '--Rp 2.000',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1 Transaksi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthItem(
    String label, {
    bool isSelected = false,
    Gradient? gradient,
  }) {
    return Container(
      width: 60,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? null : const Color(0xFF1E1E1E),
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
