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

  Future<VendorBulkActionResult> approveMany(List<String> vendorIds) async {
    try {
      final result = await VendorsService.instance.approveManyVendors(vendorIds);
      await refreshList();
      return VendorBulkActionResult(
        successCount: (result['successCount'] as num?)?.toInt() ?? 0,
        errors: Map<String, String>.from(result['errors'] as Map? ?? {}),
      );
    } catch (e) {
      return VendorBulkActionResult(
        successCount: 0,
        errors: {'all': e.toString()},
      );
    }
  }

  Future<VendorBulkActionResult> rejectMany(List<String> vendorIds, {required String reason}) async {
    try {
      final result = await VendorsService.instance.rejectManyVendors(vendorIds, reason: reason);
      await refreshList();
      return VendorBulkActionResult(
        successCount: (result['successCount'] as num?)?.toInt() ?? 0,
        errors: Map<String, String>.from(result['errors'] as Map? ?? {}),
      );
    } catch (e) {
      return VendorBulkActionResult(
        successCount: 0,
        errors: {'all': e.toString()},
      );
    }
  }
}

final vendorsProvider = AsyncNotifierProvider<VendorsNotifier, List<VendorItem>>(
  VendorsNotifier.new,
);
