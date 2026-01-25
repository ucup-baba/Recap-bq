import 'package:flutter/material.dart';

class CategoryStatsMockupPage extends StatelessWidget {
  const CategoryStatsMockupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Statistik Kategori',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Filter Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Year Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688), // Teal color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '2026',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Month Selectors (1-12)
                  ...List.generate(12, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Total Expense Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Dark grey card
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: const [
                  Text(
                    'Total Pengeluaran 2026',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Rp 2.000',
                    style: TextStyle(
                      color: Color(0xFFFF5252), // Reddish text
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Categories Title
            const Text(
              'Kategori',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Categories Grid
            Wrap(
              spacing: 16,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _buildCategoryItem(
                  'Fasilitas',
                  Icons.business,
                  const Color(0xFF9C27B0), // Purple
                  'Rp 0',
                ),
                _buildCategoryItem(
                  'Pendidikan',
                  Icons.school,
                  const Color(0xFF2196F3), // Blue
                  'Rp 0',
                ),
                _buildCategoryItem(
                  'Rumah Tangga',
                  Icons.home,
                  const Color(0xFF4CAF50), // Green
                  'Rp 0',
                ),
                _buildCategoryItem(
                  'Transportasi',
                  Icons.directions_car,
                  const Color(0xFFFF9800), // Orange
                  'Rp 0',
                ),
                _buildCategoryItem(
                  'Lainnya',
                  Icons.more_horiz,
                  const Color(0xFF607D8B), // Grey
                  'Rp 0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String label,
    IconData icon,
    Color color,
    String amount,
  ) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1.5),
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}
