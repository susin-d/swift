import '../models/promo_model.dart';
import 'api_service.dart';

class PromoValidationResult {
  final String code;
  final double discountAmount;
  final double finalAmount;
  final String? description;

  PromoValidationResult({
    required this.code,
    required this.discountAmount,
    required this.finalAmount,
    this.description,
  });

  factory PromoValidationResult.fromJson(Map<String, dynamic> json) {
    return PromoValidationResult(
      code: json['code']?.toString() ?? '',
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      finalAmount: (json['final_amount'] ?? 0).toDouble(),
      description: json['description']?.toString(),
    );
  }
}

class PromoService {
  final ApiService _api = ApiService();

  Future<List<PromoModel>> getActivePromos() async {
    final response = await _api.get('/promos/active');
    final data = response.data as List? ?? [];
    return data.map((json) => PromoModel.fromJson(json)).toList();
  }

  Future<PromoValidationResult> validatePromo(String code, double orderTotal) async {
    final response = await _api.post('/promos/validate', data: {
      'code': code,
      'order_total': orderTotal,
    });
    return PromoValidationResult.fromJson(response.data as Map<String, dynamic>);
  }
}
