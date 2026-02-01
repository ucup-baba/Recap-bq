import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'financial_tab_controller.dart';

/// Financial Tab View for Super Admin
/// Shows balance, fund requests, and expense recording
class FinancialTabView extends GetView<FinancialTabController> {
  const FinancialTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<FinancialTabController>()) {
      Get.put(FinancialTabController());
    }

    final currencyFormat = NumberFormat('#,###', 'id_ID');

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header with gradient - Show for Fund Request (1) and Expense (2)
          Obx(() => (controller.selectedSubTab.value == 1 || controller.selectedSubTab.value == 2)
              ? _buildHeader(context, currencyFormat)
              : const SizedBox.shrink()),
          // Sub-tabs
          _buildSubTabs(context),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              switch (controller.selectedSubTab.value) {
                case 1:
                  return _buildFundRequestTab(context, currencyFormat);
                case 2:
                  return _buildExpenseTab(context, currencyFormat);
                case 3:
                  return _buildPersonalTab(context, currencyFormat);
                default:
                  return _buildOverviewTab(context, currencyFormat);
              }
            }),
          ),
        ],
      ),
    );
  }

  /// Build header with balance info
  Widget _buildHeader(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [const Color(0xFF26A69A), const Color(0xFF00897B)]
              : [Colors.teal.shade500, Colors.teal.shade700],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIQowwam',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Financial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Refresh button
                GestureDetector(
                  onTap: () => controller.refreshData(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Balance card
            Obx(
              () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Anda',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${currencyFormat.format(controller.currentBalance.toInt())}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.roleName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sub-tabs
  Widget _buildSubTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Obx(
        () => Row(
          children: [
            _buildSubTabButton(context, 0, 'Overview', Icons.dashboard),
            const SizedBox(width: 8),
            _buildSubTabButton(context, 1, 'Pengajuan', Icons.request_page),
            const SizedBox(width: 8),
            _buildSubTabButton(
              context,
              2,
              'Pengeluaran',
              Icons.remove_circle_outline,
            ),
            const SizedBox(width: 8),
            _buildSubTabButton(
              context,
              3,
              'Me',
              Icons.person_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.selectedSubTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedSubTab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDark ? Colors.teal.shade700 : Colors.teal.shade500)
                : (context.isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : context.subtextColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : context.subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Overview tab - shows combined assets and split details
  Widget _buildOverviewTab(BuildContext context, NumberFormat currencyFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOTAL ASET CARD (Separate - Top)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDark 
                    ? [const Color(0xFF00695C), const Color(0xFF1565C0)] 
                    : [Colors.teal.shade700, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(PhosphorIcons.wallet(PhosphorIconsStyle.fill), size: 20, color: Colors.teal),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wallet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                  'Rp ${currencyFormat.format(controller.walletBalance)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 2. SPLIT CARDS ROW (SiQowwam & Pribadi - Separate)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SIQOWWAM CARD (Green/Teal Theme)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade600, Colors.teal.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(PhosphorIcons.shieldCheckered(PhosphorIconsStyle.fill), size: 18, color: Colors.teal),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SIQOWWAM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() => Text(
                        'Rp ${currencyFormat.format(controller.currentBalance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      const SizedBox(height: 16),
                      
                      // Pengajuan Dana Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengajuan Dana',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: controller.quickFundAmountController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        _ThousandsSeparatorFormatter(),
                                      ],
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan jumlah...',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () { 
                                    if (controller.quickFundAmountController.text.isNotEmpty) {
                                      controller.submitQuickFundRequest(controller.quickFundAmountController.text);
                                      FocusScope.of(context).unfocus();
                                    }
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.tealAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.send_rounded, color: Colors.teal, size: 18),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.white.withOpacity(0.7), size: 14),
                                const SizedBox(width: 6),
                                Obx(() {
                                  final hasPending = controller.fundRequests.any((r) => r['status'] == 'pending');
                                  return Text(
                                    hasPending ? 'Pending' : 'Tidak Ada Pending',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // PRIBADI CARD (Blue Theme)
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectedSubTab.value = 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'PRIBADI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Text(
                          'Rp ${currencyFormat.format(controller.personalBalance.value)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                        const SizedBox(height: 16),
                        
                        // Cash Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.payments_outlined, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cash (Honor + Biz)',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Obx(() => Text(
                                      'Rp ${currencyFormat.format(controller.personalCashIncome)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // E-Money Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'E-Money',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Obx(() => Text(
                                      'Rp ${currencyFormat.format(controller.personalEmoneyIncome)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
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
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Transactions Section
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
          ),

          Obx(() {
            final personalTx = controller.personalTransactions;
            if (personalTx.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: context.subtextColor.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('Belum ada transaksi', style: TextStyle(color: context.subtextColor)),
                    ],
                  ),
                ),
              );
            }
            
            return Column(
              children: personalTx.take(5).map((tx) {
                return _buildPersonalTransactionCard(context, tx, currencyFormat);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  /// Fund request tab
  Widget _buildFundRequestTab(
    BuildContext context,
    NumberFormat currencyFormat,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.request_page, color: Colors.teal.shade600),
                    const SizedBox(width: 10),
                    Text(
                      'Ajukan Dana',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Amount field
                TextField(
                  controller: controller.fundAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                // Description field
                TextField(
                  controller: controller.fundDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),
                // Submit button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.hasPendingRequest
                          ? null
                          : () => controller.submitFundRequest(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        controller.hasPendingRequest
                            ? 'Menunggu Persetujuan...'
                            : 'Ajukan Dana',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // My requests history
          Text(
            'Riwayat Pengajuan Saya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final requests = controller.fundRequests;
            if (requests.isEmpty) {
              return _buildEmptyState(
                context,
                'Belum ada pengajuan',
                Icons.request_page,
              );
            }

            return Column(
              children: requests
                  .map(
                    (req) => _buildMyRequestCard(context, req, currencyFormat),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  /// Expense tab with horizontal category icons
  Widget _buildExpenseTab(BuildContext context, NumberFormat currencyFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.remove_circle, color: Colors.red.shade600),
                    const SizedBox(width: 10),
                    Text(
                      'Catat Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category selector as horizontal icons
                Center(
                  child: Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final categories = controller.availableCategories.keys
                      .toList();
                  // Sort: put 'Lainnya' last
                  categories.sort((a, b) {
                    if (a == 'Lainnya') return 1;
                    if (b == 'Lainnya') return -1;
                    return a.compareTo(b);
                  });

                  return Center(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: categories.map((category) {
                        final isSelected =
                            controller.selectedCategory.value == category;
                        final catColor = _getCategoryColor(category);
                        final icon = _getCategoryIcon(category);

                        return GestureDetector(
                          onTap: () {
                            controller.selectedCategory.value = category;
                            controller.selectedSubcategory.value = null;
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor
                                      : context.isDark
                                      ? catColor.withOpacity(0.25)
                                      : catColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? catColor
                                        : catColor.withOpacity(0.5),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: catColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    color: isSelected
                                        ? Colors.white
                                        : context.isDark
                                        ? Color.lerp(
                                            catColor,
                                            Colors.white,
                                            0.4,
                                          )!
                                        : catColor,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? catColor
                                      : context.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Subcategory chips
                Obx(() {
                  final category = controller.selectedCategory.value;
                  if (category == null) return const SizedBox.shrink();

                  final subcategories =
                      controller.availableCategories[category] ?? [];
                  final catColor = _getCategoryColor(category);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Sub-kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: subcategories.map((sub) {
                            final isSelected =
                                controller.selectedSubcategory.value == sub;
                            return GestureDetector(
                              onTap: () {
                                controller.selectedSubcategory.value =
                                    isSelected ? null : sub;
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? catColor
                                        : (context.isDark
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade400),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  sub,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : context.subtextColor,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),

                // Amount field
                TextField(
                  controller: controller.expenseAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                // Description field
                TextField(
                  controller: controller.expenseDescriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.createExpense(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Catat Pengeluaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pendidikan':
        return Icons.school;
      case 'Transportasi':
        return Icons.directions_car;
      case 'Fasilitas':
        return Icons.business;
      case 'Rumah Tangga':
        return Icons.home;
      case 'Lainnya':
      default:
        return Icons.more_horiz;
    }
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pendidikan':
        return Colors.blue;
      case 'Transportasi':
        return Colors.orange;
      case 'Fasilitas':
        return Colors.purple;
      case 'Rumah Tangga':
        return Colors.green;
      case 'Lainnya':
      default:
        return Colors.grey;
    }
  }

  // --- Personal Finance UI ---

  Widget _buildPersonalTab(BuildContext context, NumberFormat currencyFormat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Balance Card
          _buildPersonalBalanceCard(context, currencyFormat),
          const SizedBox(height: 16),
          
          // Personal Transaction Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade600),
                    const SizedBox(width: 10),
                    Text(
                      'Keuangan Pribadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Type Selector (In / Out / Invest)
                Obx(() => Row(
                  children: [
                    _buildPersonalTypeButton(context, FinancialTabController.typeIncome, 'Income', Icons.arrow_downward, Colors.green),
                    const SizedBox(width: 8),
                    _buildPersonalTypeButton(context, FinancialTabController.typeExpense, 'Expense', Icons.arrow_upward, Colors.red),
                    const SizedBox(width: 8),
                    _buildPersonalTypeButton(context, FinancialTabController.typeInvestment, 'Invest', PhosphorIcons.trendUp(), Colors.blue),
                  ],
                )),
                const SizedBox(height: 20),

                // Category Selector
                Obx(() {
                  final type = controller.selectedPersonalType.value;
                  final categories = FinancialTabController.personalCategories[type] ?? [];
                  
                  return Column(
                    children: [
                      Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: categories.map((category) {
                          final isSelected = controller.selectedPersonalCategory.value == category;
                          final icon = _getPersonalCategoryIcon(category);
                          final color = _getPersonalTypeColor(type);

                          return GestureDetector(
                            onTap: () {
                              controller.selectedPersonalCategory.value = category;
                              controller.selectedPersonalSubcategory.value = null; // Reset subcategory
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected ? color : color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? color : color.withOpacity(0.5),
                                      width: isSelected ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      icon,
                                      color: isSelected ? Colors.white : color,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? color : context.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                      
                      // Subcategories
                      if (controller.selectedPersonalCategory.value != null && 
                          FinancialTabController.personalSubcategories.containsKey(controller.selectedPersonalCategory.value)) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Sub-kategori',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: FinancialTabController.personalSubcategories[controller.selectedPersonalCategory.value]!.map((sub) {
                            final isSelected = controller.selectedPersonalSubcategory.value == sub;
                            final color = _getPersonalTypeColor(type);
                            
                            return GestureDetector(
                              onTap: () => controller.selectedPersonalSubcategory.value = sub,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? color : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? color : color.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  sub,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : context.textColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 20),

                // Fund Source Selector (Only for Expense & Invest)
                Obx(() {
                  final type = controller.selectedPersonalType.value;
                  if (type == FinancialTabController.typeIncome) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Sumber Dana',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.selectedFundSource.value = 'Cash',
                              child: Obx(() {
                                final isSelected = controller.selectedFundSource.value == 'Cash';
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        PhosphorIcons.money(isSelected ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
                                        color: isSelected ? Colors.blue : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cash',
                                        style: TextStyle(
                                          color: isSelected ? Colors.blue : context.subtextColor,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.selectedFundSource.value = 'E-Money',
                              child: Obx(() {
                                final isSelected = controller.selectedFundSource.value == 'E-Money';
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        PhosphorIcons.creditCard(isSelected ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
                                        color: isSelected ? Colors.blue : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'E-Money',
                                        style: TextStyle(
                                          color: isSelected ? Colors.blue : context.subtextColor,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }),

                // Amount Field
                TextField(
                  controller: controller.personalAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description Field
                TextField(
                  controller: controller.personalDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: context.isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.createPersonalTransaction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // History Section
          Text(
            'Riwayat Transaksi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          Obx(() {
            final txList = controller.personalTransactions;
            if (txList.isEmpty) {
              return _buildEmptyState(
                context,
                'Belum ada riwayat',
                Icons.history,
              );
            }

            return Column(
              children: txList.map((tx) => _buildPersonalTransactionCard(context, tx, currencyFormat)).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalTypeButton(
    BuildContext context, 
    String type, 
    String label, 
    IconData icon,
    Color color,
  ) {
    final isSelected = controller.selectedPersonalType.value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.selectedPersonalType.value = type;
          controller.selectedPersonalCategory.value = null; // Reset category on type switch
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(isSelected ? 1 : 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalBalanceCard(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDark 
              ? [const Color(0xFF1E88E5), const Color(0xFF1565C0)] 
              : [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Pribadi',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            'Rp ${currencyFormat.format(controller.personalBalance.value)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPersonalTransactionCard(
    BuildContext context,
    Map<String, dynamic> tx,
    NumberFormat currencyFormat,
  ) {
    final type = tx['type'];
    final isIncome = type == FinancialTabController.typeIncome;
    final isInvestment = type == FinancialTabController.typeInvestment;
    
    // Determine color and icon based on type
    Color color;
    IconData iconData;
    
    if (isIncome) {
      color = Colors.green;
      iconData = Icons.arrow_downward;
    } else if (isInvestment) {
      color = Colors.blue;
      iconData = PhosphorIcons.trendUp();
    } else {
      color = Colors.red;
      iconData = Icons.arrow_upward;
    }

    final date = (tx['date'] as Timestamp).toDate();
    final amount = (tx['amount'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPersonalCategoryIcon(tx['category']),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['subcategory'] != null 
                      ? '${tx['category']} - ${tx['subcategory']}' 
                      : (tx['category'] ?? 'Umum'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.subtextColor,
                  ),
                ),
                if (tx['description'] != null && tx['description'].toString().isNotEmpty)
                   Text(
                    tx['description'],
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: context.subtextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? "+" : "-"} Rp ${currencyFormat.format(amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPersonalTypeColor(String type) {
    switch (type) {
      case FinancialTabController.typeIncome:
        return Colors.green;
      case FinancialTabController.typeInvestment:
        return Colors.blue;
      case FinancialTabController.typeExpense:
      default:
        return Colors.red;
    }
  }

  IconData _getPersonalCategoryIcon(String category) {
    switch (category) {
      // Income
      case 'Honor': return PhosphorIcons.briefcase();
      case 'Emoney': return PhosphorIcons.wallet();
      case 'Business': return Icons.store; // Fallback if PhosphorIcons.storefront missing
      
      // Expense
      case 'Transport': return PhosphorIcons.car();
      case 'Mandi': return PhosphorIcons.bathtub();
      case 'Jajan': return PhosphorIcons.hamburger();
      case 'Pakaian': return PhosphorIcons.coatHanger();
      case 'Pulsa': return PhosphorIcons.deviceMobile();
      case 'Elektronik': return PhosphorIcons.desktop();
      case 'Others': return Icons.more_horiz; // Fallback if PhosphorIcons.dotsThreeCircle missing
      
      // Investment
      case 'Book': return PhosphorIcons.book();
      case 'Masjid': return PhosphorIcons.mosque();
      case 'Monthly': return PhosphorIcons.calendar();
      case 'Share': return PhosphorIcons.shareNetwork();
      
      default: return PhosphorIcons.tag();
    }
  }

  /// Empty state widget
  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: context.isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: context.subtextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  /// Build pending request card (for approval)
  Widget _buildPendingRequestCard(
    BuildContext context,
    Map<String, dynamic> request,
    NumberFormat currencyFormat,
  ) {
    final amount = (request['amount'] ?? 0).toDouble();
    final userName = request['userName'] ?? 'User';
    final description = request['description'] ?? '';
    final createdAt = (request['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                          'id_ID',
                        ).format(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.subtextColor,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'Rp ${currencyFormat.format(amount.toInt())}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: context.subtextColor),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, request['id']),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.approveRequest(request['id']),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show reject dialog
  void _showRejectDialog(BuildContext context, String requestId) {
    final noteController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectRequest(requestId, note: noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Build my request card
  Widget _buildMyRequestCard(
    BuildContext context,
    Map<String, dynamic> request,
    NumberFormat currencyFormat,
  ) {
    final amount = (request['amount'] ?? 0).toDouble();
    final description = request['description'] ?? '';
    final status = request['status'] ?? 'pending';
    final createdAt = (request['createdAt'] as Timestamp?)?.toDate();

    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Disetujui';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rp ${currencyFormat.format(amount.toInt())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.textColor,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: context.subtextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(createdAt),
                    style: TextStyle(fontSize: 11, color: context.subtextColor),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build transaction card
  Widget _buildTransactionCard(
    BuildContext context,
    Map<String, dynamic> tx,
    NumberFormat currencyFormat,
  ) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final type = tx['type'] ?? 'expense';
    final category = tx['category'] ?? 'Lainnya';
    final description = tx['description'] ?? '';
    final createdAt = (tx['createdAt'] as Timestamp?)?.toDate();

    final isIncome = type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textColor,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: context.subtextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(createdAt),
                    style: TextStyle(fontSize: 11, color: context.subtextColor),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} Rp ${currencyFormat.format(amount.toInt())}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }


}

/// Thousands separator formatter
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###', 'id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
