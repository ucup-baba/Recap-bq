import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../input_transaction/input_transaction_controller.dart';
import '../output_transaction/output_transaction_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<InputTransactionController>(() => InputTransactionController());
    Get.lazyPut<OutputTransactionController>(
      () => OutputTransactionController(),
    );
  }
}
