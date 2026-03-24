import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(ref.watch(apiServiceProvider));
});

final financeEarningsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(financeServiceProvider).fetchEarnings();
});

final financePayoutsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(financeServiceProvider).fetchPayouts();
});

final financeTransactionsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(financeServiceProvider).fetchTransactions();
});

final financeTaxReportsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(financeServiceProvider).fetchTaxReports();
});

class FinanceService {
  FinanceService(this._api);

  final ApiService _api;

  Future<Map<String, dynamic>> fetchEarnings() async {
    final response = await _api.get('/vendor-ops/finance/earnings');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['earnings'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<List<dynamic>> fetchPayouts() async {
    final response = await _api.get('/vendor-ops/finance/payouts');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['payouts'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<List<dynamic>> fetchTransactions() async {
    final response = await _api.get('/vendor-ops/finance/transactions');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['transactions'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<Map<String, dynamic>> fetchTaxReports() async {
    final response = await _api.get('/vendor-ops/finance/tax-reports');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['tax_report'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
