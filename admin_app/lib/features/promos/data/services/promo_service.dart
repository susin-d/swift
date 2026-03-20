import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/promo.dart';

class PromoService {
  PromoService._();
  static final PromoService instance = PromoService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<Promo>> fetchPromos() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/promos');
      final data = response.data ?? [];
      return data.map((e) => Promo.fromJson((e as Map).cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load promotions',
      );
    }
  }

  Future<Promo> createPromo({
    required String code,
    required String discountType,
    required double discountValue,
    double minOrderAmount = 0,
    double? maxDiscountAmount,
    DateTime? startsAt,
    DateTime? endsAt,
    bool isActive = true,
    int? usageLimit,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/admin/promos', data: {
        'code': code,
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount_amount': maxDiscountAmount,
        'starts_at': startsAt?.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'is_active': isActive,
        'usage_limit': usageLimit,
      });
      return Promo.fromJson((response.data ?? const <String, dynamic>{}).cast<String, dynamic>());
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to create promo',
      );
    }
  }

  Future<Promo> updatePromo(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('/admin/promos/$id', data: updates);
      return Promo.fromJson((response.data ?? const <String, dynamic>{}).cast<String, dynamic>());
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to update promo',
      );
    }
  }
}
