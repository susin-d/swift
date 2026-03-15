import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vendor_item.dart';
import '../../data/services/vendors_service.dart';

class VendorBulkActionResult {
  const VendorBulkActionResult({required this.successCount, required this.errors});

  final int successCount;
  final Map<String, String> errors;
}

class VendorsNotifier extends AsyncNotifier<List<VendorItem>> {
  @override
  Future<List<VendorItem>> build() async {
    return VendorsService.instance.fetchVendors();
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => VendorsService.instance.fetchVendors());
  }

  Future<String?> approve(String vendorId) async {
    try {
      await VendorsService.instance.approveVendor(vendorId);
      await refreshList();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> reject(String vendorId, {required String reason}) async {
    try {
      await VendorsService.instance.rejectVendor(vendorId, reason: reason);
      await refreshList();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<VendorBulkActionResult> approveMany(List<String> vendorIds) {
    return _bulkAction(vendorIds, (id) => VendorsService.instance.approveVendor(id));
  }

  Future<VendorBulkActionResult> rejectMany(List<String> vendorIds, {required String reason}) {
    return _bulkAction(vendorIds, (id) => VendorsService.instance.rejectVendor(id, reason: reason));
  }

  Future<VendorBulkActionResult> _bulkAction(
    List<String> vendorIds,
    Future<void> Function(String vendorId) action,
  ) async {
    var successCount = 0;
    final errors = <String, String>{};

    for (final id in vendorIds) {
      try {
        await action(id);
        successCount += 1;
      } catch (e) {
        errors[id] = e.toString();
      }
    }

    await refreshList();
    return VendorBulkActionResult(successCount: successCount, errors: errors);
  }
}

final vendorsProvider = AsyncNotifierProvider<VendorsNotifier, List<VendorItem>>(
  VendorsNotifier.new,
);
