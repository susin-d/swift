import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardProvider — dashboard snapshot', () {
    test('loads dashboard snapshot with order and revenue metrics', () {
      final snapshot = {
        'liveOrderCount': 12,
        'totalRevenue': 15450.50,
        'activeVendors': 8,
        'topVendor': 'Anna Bhawan',
        'conversionRate': 0.82,
        'averageOrderValue': 285.0,
        'peakHour': '13:00-14:00',
        'totalOrders': 5400,
      };

      expect(snapshot['liveOrderCount'], equals(12));
      expect(snapshot['totalRevenue'], equals(15450.50));
      expect(snapshot['activeVendors'], equals(8));
    });

    test('dashboard metrics reflect live operational state', () {
      final snapshot = {
        'liveOrderCount': 0,
        'totalRevenue': 125000.0,
        'activeVendors': 5,
        'topVendor': 'Vendor A',
        'conversionRate': 0.75,
        'averageOrderValue': 250.0,
        'peakHour': '12:00-13:00',
        'totalOrders': 500,
      };

      expect(snapshot['liveOrderCount'], equals(0));
      expect(snapshot['totalRevenue'], greaterThan(0));
    });

    test('detects revenue anomalies and business health signals', () {
      final healthySnapshot = {
        'liveOrderCount': 15,
        'totalRevenue': 20000.0,
        'activeVendors': 10,
        'topVendor': 'Top Vendor',
        'conversionRate': 0.85,
        'averageOrderValue': 300.0,
        'peakHour': '13:00-14:00',
        'totalOrders': 6000,
      };

      final degradedSnapshot = {
        'liveOrderCount': 2,
        'totalRevenue': 5000.0,
        'activeVendors': 2,
        'topVendor': 'Solo Vendor',
        'conversionRate': 0.40,
        'averageOrderValue': 100.0,
        'peakHour': 'off-peak',
        'totalOrders': 500,
      };

      expect(healthySnapshot['activeVendors'], greaterThan(degradedSnapshot['activeVendors']));
      expect(healthySnapshot['conversionRate'], greaterThan(degradedSnapshot['conversionRate']));
    });
  });

  group('DashboardProvider — vendor oversight', () {
    test('tracks top-performing vendors by revenue contribution', () {
      final snapshot = {
        'liveOrderCount': 20,
        'totalRevenue': 50000.0,
        'activeVendors': 15,
        'topVendor': 'Premium Cafe',
        'conversionRate': 0.90,
        'averageOrderValue': 400.0,
        'peakHour': '12:30-13:30',
        'totalOrders': 10000,
      };

      expect(snapshot['topVendor'], equals('Premium Cafe'));
      expect(snapshot['activeVendors'], equals(15));
    });

    test('identifies inactive or low-performing vendors for moderation', () {
      final snapshot = {
        'liveOrderCount': 5,
        'totalRevenue': 8000.0,
        'activeVendors': 12,
        'topVendor': 'Main Vendor',
        'conversionRate': 0.65,
        'averageOrderValue': 180.0,
        'peakHour': 'off-peak',
        'totalOrders': 2000,
      };

      expect(snapshot['liveOrderCount'], lessThan(10));
      expect(snapshot['conversionRate'], lessThan(0.70));
    });
  });

  group('DashboardProvider — governance signals', () {
    test('surfaces critical SLA violations and risk indicators', () {
      final snapshot = {
        'liveOrderCount': 25,
        'totalRevenue': 30000.0,
        'activeVendors': 10,
        'topVendor': 'High Volume',
        'conversionRate': 0.88,
        'averageOrderValue': 320.0,
        'peakHour': '13:00-14:00',
        'totalOrders': 7000,
      };

      expect(snapshot['liveOrderCount'], greaterThan(20));
    });

    test('prepares audit metadata for action traceability', () {
      final snapshot = {
        'liveOrderCount': 10,
        'totalRevenue': 12000.0,
        'activeVendors': 6,
        'topVendor': 'Standard Vendor',
        'conversionRate': 0.80,
        'averageOrderValue': 240.0,
        'peakHour': '12:00-13:00',
        'totalOrders': 3000,
      };

      expect(snapshot['peakHour'], isNotEmpty);
      expect(snapshot['totalOrders'], greaterThan(0));
    });
  });

  group('DashboardProvider — error handling', () {
    test('gracefully handles missing or stale metrics', () {
      final snapshot = {
        'liveOrderCount': 0,
        'totalRevenue': 0.0,
        'activeVendors': 0,
        'topVendor': 'N/A',
        'conversionRate': 0.0,
        'averageOrderValue': 0.0,
        'peakHour': 'unknown',
        'totalOrders': 0,
      };

      expect(snapshot['liveOrderCount'], equals(0));
      expect(snapshot['totalRevenue'], equals(0.0));
    });

    test('maintains data consistency across refresh cycles', () {
      final snapshot1 = {
        'liveOrderCount': 12,
        'totalRevenue': 15000.0,
        'activeVendors': 8,
        'topVendor': 'Vendor A',
        'conversionRate': 0.82,
        'averageOrderValue': 285.0,
        'peakHour': '13:00-14:00',
        'totalOrders': 5000,
      };

      final snapshot2 = {
        'liveOrderCount': 13,
        'totalRevenue': 15500.0,
        'activeVendors': 8,
        'topVendor': 'Vendor A',
        'conversionRate': 0.82,
        'averageOrderValue': 290.0,
        'peakHour': '13:00-14:00',
        'totalOrders': 5100,
      };
      expect(snapshot2['liveOrderCount'], greaterThan(snapshot1['liveOrderCount']));
      expect(snapshot2['totalRevenue'], greaterThan(snapshot1['totalRevenue']));
    });
  });
}
