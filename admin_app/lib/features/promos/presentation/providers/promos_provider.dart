import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/promo.dart';
import '../../data/services/promo_service.dart';

class PromosNotifier extends AsyncNotifier<List<Promo>> {
  @override
  Future<List<Promo>> build() async {
    return PromoService.instance.fetchPromos();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => PromoService.instance.fetchPromos());
  }

  Future<String?> createPromo({
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
      await PromoService.instance.createPromo(
        code: code,
        discountType: discountType,
        discountValue: discountValue,
        minOrderAmount: minOrderAmount,
        maxDiscountAmount: maxDiscountAmount,
        startsAt: startsAt,
        endsAt: endsAt,
        isActive: isActive,
        usageLimit: usageLimit,
        description: description,
      );
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> toggleActive(Promo promo, bool active) async {
    try {
      await PromoService.instance.updatePromo(promo.id, {'is_active': active});
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final promosProvider = AsyncNotifierProvider<PromosNotifier, List<Promo>>(
  PromosNotifier.new,
);
