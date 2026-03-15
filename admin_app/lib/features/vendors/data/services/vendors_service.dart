import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/vendor_item.dart';

class VendorsService {
  VendorsService._();
  static final VendorsService instance = VendorsService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<VendorItem>> fetchVendors() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/vendors/pending');
      final vendorsJson = (response.data?['vendors'] as List?) ?? const [];

      return vendorsJson
          .map((e) => VendorItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load vendors',
      );
    }
  }

  Future<void> approveVendor(String vendorId) async {
    try {
      await _dio.patch('/admin/vendors/$vendorId/approve');
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to approve vendor',
      );
    }
  }

  Future<void> rejectVendor(String vendorId, {required String reason}) async {
    try {
      await _dio.patch('/admin/vendors/$vendorId/reject', data: {'reason': reason});
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to reject vendor',
      );
    }
  }
}
