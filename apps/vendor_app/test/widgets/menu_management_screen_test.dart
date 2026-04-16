import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:vendor_app/features/menu/menu_management_screen.dart';

class _FakeDio extends DioMixin implements Dio {
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> patchCalls = [];

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    dynamic onSendProgress,
    dynamic onReceiveProgress,
    Options? options,
  }) async {
    postCalls.add({'path': path, 'data': data});

    // Handle image upload endpoint
    if (path == '/vendor-ops/menu/upload-image') {
      final uploadData = data as Map<String, dynamic>;
      return Response<T>(
        data: {
          'url': 'https://project.supabase.co/storage/v1/object/public/menu-items/vendor/test-vendor/items/image.jpg',
          'path': 'vendor/test-vendor/items/image.jpg',
          'mimeType': uploadData['mimeType'],
          'sizeBytes': 5000,
        } as T,
        statusCode: 201,
        requestOptions: RequestOptions(path: path),
      );
    }

    // Handle menu item creation
    return Response<T>(
      data: {'ok': true} as T,
      statusCode: 201,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    dynamic onSendProgress,
    dynamic onReceiveProgress,
    Options? options,
  }) async {
    patchCalls.add({'path': path, 'data': data});
    return Response<T>(
      data: {'ok': true} as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class _FakeMenuApiService extends ApiService {
  _FakeMenuApiService(this.menuResponse, this.fakeDio);

  final Map<String, dynamic> menuResponse;
  final _FakeDio fakeDio;

  List<Map<String, dynamic>> get postCalls => fakeDio.postCalls;
  List<Map<String, dynamic>> get patchCalls => fakeDio.patchCalls;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? cancelKey,
  }) async {
    return Response<dynamic>(
      data: menuResponse,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<dynamic>> post(String path, {data, String? cancelKey}) async {
    return fakeDio.post(path, data: data);
  }

  @override
  Future<Response<dynamic>> patch(String path, {data, String? cancelKey}) async {
    return fakeDio.patch(path, data: data);
  }

  @override
  Dio get dio => fakeDio;
}

Future<void> _pumpMenuScreen(
  WidgetTester tester,
  _FakeMenuApiService api, {
  Future<String?> Function(BuildContext context)? imagePicker,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(api)],
      child: MaterialApp(
        home: MenuManagementScreen(imagePicker: imagePicker),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _menuPayload({String? imageUrl}) {
  return {
    'categories': [
      {
        'id': 'cat-1',
        'vendor_id': 'vendor-1',
        'category_name': 'Burgers',
        'sort_order': 1,
        'created_at': '2026-03-24T10:00:00.000Z',
        'updated_at': '2026-03-24T10:30:00.000Z',
        'menu_items': [
          {
            'id': 'item-1',
            'menu_id': 'cat-1',
            'name': 'Classic Burger',
            'description': 'Loaded burger',
            'price': 149,
            'is_available': true,
            'image_url': imageUrl,
            'created_at': '2026-03-24T10:00:00.000Z',
            'updated_at': '2026-03-24T10:15:00.000Z',
          }
        ],
      }
    ],
    'items': [
      {
        'id': 'item-1',
        'menu_id': 'cat-1',
        'name': 'Classic Burger',
        'description': 'Loaded burger',
        'price': 149,
        'is_available': true,
        'image_url': imageUrl,
        'created_at': '2026-03-24T10:00:00.000Z',
        'updated_at': '2026-03-24T10:15:00.000Z',
        'category': 'Burgers',
        'category_name': 'Burgers',
        'category_id': 'cat-1',
        'category_sort_order': 1,
        'vendor_id': 'vendor-1',
      }
    ],
  };
}

void main() {
  testWidgets('add item dialog uploads image to backend and persists returned URL', (tester) async {
    final fakeDio = _FakeDio();
    final api = _FakeMenuApiService(_menuPayload(), fakeDio);

    // imagePicker returns data URL which gets uploaded to backend
    await _pumpMenuScreen(
      tester,
      api,
      imagePicker: (_) async => 'data:image/jpeg;base64,${base64Encode(List.filled(1000, 0))}',
    );

    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Item name'), 'Veg Supreme');
    await tester.enterText(find.widgetWithText(TextField, 'Description'), 'House special');
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '199');

    // Tap Upload button - triggers backend upload
    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify upload endpoint was called
    final uploadCall = api.postCalls.firstWhere(
      (call) => call['path'] == '/vendor-ops/menu/upload-image',
      orElse: () => {},
    );
    expect(uploadCall, isNotEmpty);
    expect((uploadCall['data'] as Map)['mimeType'], 'image/jpeg');

    // Save the item
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // Verify the item creation includes the URL from backend response
    final createCall = api.postCalls.firstWhere(
      (call) => call['path'] == '/menus/items',
      orElse: () => {},
    );
    expect(createCall, isNotEmpty);
    expect((createCall['data'] as Map)['image_url'],
        'https://project.supabase.co/storage/v1/object/public/menu-items/vendor/test-vendor/items/image.jpg');
  });

  testWidgets('edit item dialog uploads updated image to backend', (tester) async {
    final fakeDio = _FakeDio();
    final api = _FakeMenuApiService(_menuPayload(imageUrl: 'https://example.com/original.png'), fakeDio);

    await _pumpMenuScreen(
      tester,
      api,
      imagePicker: (_) async => 'data:image/png;base64,${base64Encode(List.filled(2000, 0))}',
    );

    final editIcons = find.byIcon(Icons.edit_outlined);
    await tester.tap(editIcons.last);
    await tester.pumpAndSettle();

    // Tap Upload button - triggers backend upload
    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify upload endpoint was called
    final uploadCall = api.postCalls.firstWhere(
      (call) => call['path'] == '/vendor-ops/menu/upload-image',
      orElse: () => {},
    );
    expect(uploadCall, isNotEmpty);
    expect((uploadCall['data'] as Map)['mimeType'], 'image/png');

    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    await tester.pumpAndSettle();

    // Verify the item update includes the new URL from backend
    final updateCall = api.patchCalls.firstWhere(
      (call) => call['path'] == '/menus/items/item-1',
      orElse: () => {},
    );
    expect(updateCall, isNotEmpty);
    expect((updateCall['data'] as Map)['image_url'],
        'https://project.supabase.co/storage/v1/object/public/menu-items/vendor/test-vendor/items/image.jpg');
  });

  testWidgets('invalid thumbnail URL falls back to unsupported-image icon', (tester) async {
    final fakeDio = _FakeDio();
    final api = _FakeMenuApiService(_menuPayload(imageUrl: 'https://example.invalid/does-not-exist.png'), fakeDio);

    await _pumpMenuScreen(tester, api);
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(Icons.image_not_supported_outlined), findsWidgets);
  });

  testWidgets('category card displays created_at and updated_at timestamps', (tester) async {
    final fakeDio = _FakeDio();
    final api = _FakeMenuApiService(_menuPayload(), fakeDio);
    await _pumpMenuScreen(tester, api);

    // Find text containing the timestamps in category header
    expect(find.textContaining('Updated'), findsWidgets);
  });
}
