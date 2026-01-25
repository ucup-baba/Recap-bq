import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../input_transaction/input_transaction_view.dart';
import '../output_transaction/output_transaction_view.dart';
import '../account/account_view.dart';
import 'dashboard_controller.dart';
import 'tabs/financial_tab.dart';

/// Dashboard View with 4 tabs
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 800;

    return Scaffold(
      body: isWideScreen
          ? _buildWebLayout(context)
          : _buildMobileLayout(context),
    );
  }

  /// Mobile layout with bottom navigation
  Widget _buildMobileLayout(BuildContext context) {
    return Obx(() {
      final isViewer = controller.isViewer;

      if (isViewer) {
        // Viewer only sees Financial and Akun tabs
        return Scaffold(
          body: IndexedStack(
            index: controller.currentTabIndex.value > 1
                ? 1
                : controller.currentTabIndex.value,
            children: const [FinancialTab(), AccountView()],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentTabIndex.value > 1
                ? 1
                : controller.currentTabIndex.value,
            onTap: (index) => controller.currentTabIndex.value = index,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Financial',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Akun',
              ),
            ],
          ),
        );
      }

      // Admin/SuperAdmin sees all 4 tabs
      return Scaffold(
        body: IndexedStack(
          index: controller.currentTabIndex.value,
          children: const [
            FinancialTab(),
            InputTransactionView(),
            OutputTransactionView(),
            AccountView(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.currentTabIndex.value,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Financial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Input',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_circle_outline),
              activeIcon: Icon(Icons.remove_circle),
              label: 'Output',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      );
    });
  }

  /// Web layout with side navigation
  Widget _buildWebLayout(BuildContext context) {
    return Obx(() {
      final isViewer = controller.isViewer;

      if (isViewer) {
        // Viewer only sees Financial and Akun navigation
        return Row(
          children: [
            NavigationRail(
              selectedIndex: controller.currentTabIndex.value > 1
                  ? 1
                  : controller.currentTabIndex.value,
              onDestinationSelected: (index) =>
                  controller.currentTabIndex.value = index,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardColor,
              leading: _buildNavRailLeading(),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Financial'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Akun'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: controller.currentTabIndex.value > 1
                    ? 1
                    : controller.currentTabIndex.value,
                children: const [FinancialTab(), AccountView()],
              ),
            ),
          ],
        );
      }

      // Admin/SuperAdmin sees all 4 navigation items
      return Row(
        children: [
          NavigationRail(
            selectedIndex: controller.currentTabIndex.value,
            onDestinationSelected: controller.changeTab,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).cardColor,
            leading: _buildNavRailLeading(),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Financial'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Input'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.remove_circle_outline),
                selectedIcon: Icon(Icons.remove_circle),
                label: Text('Output'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Akun'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: controller.currentTabIndex.value,
              children: const [
                FinancialTab(),
                InputTransactionView(),
                OutputTransactionView(),
                AccountView(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNavRailLeading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryLight.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SIQowwam',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
