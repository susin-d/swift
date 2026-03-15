import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_snapshot.dart';
import '../../data/services/dashboard_service.dart';

final dashboardSnapshotProvider = FutureProvider.autoDispose<DashboardSnapshot>((ref) async {
  return DashboardService.instance.fetchSnapshot();
});
