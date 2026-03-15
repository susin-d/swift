import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/finance_service.dart';

class FinanceNotifier extends AsyncNotifier<FinanceSnapshot> {
  @override
  Future<FinanceSnapshot> build() async {
    return FinanceService.instance.fetchSnapshot();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => FinanceService.instance.fetchSnapshot());
  }
}

final financeProvider = AsyncNotifierProvider<FinanceNotifier, FinanceSnapshot>(
  FinanceNotifier.new,
);
