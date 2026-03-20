import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promo_model.dart';
import '../services/promo_service.dart';

final promoServiceProvider = Provider((ref) => PromoService());

final activePromosProvider = FutureProvider<List<PromoModel>>((ref) async {
  return ref.watch(promoServiceProvider).getActivePromos();
});
