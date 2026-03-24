import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:vendor_app/features/menu/menu_management_screen.dart';

class _FakeMenuApiService extends ApiService {
  _FakeMenuApiService(this.menuResponse);

  final Map<String, dynamic> menuResponse;
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> patchCalls = [];

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
    postCalls.add({'path': path, 'data': data, 'cancelKey': cancelKey});
    return Response<dynamic>(
      data: {'ok': true},
      statusCode: 201,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<dynamic>> patch(String path, {data, String? cancelKey}) async {
    patchCalls.add({'path': path, 'data': data, 'cancelKey': cancelKey});
    return Response<dynamic>(
      data: {'ok': true},
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

Map<String, dynamic> _menuPayload({String? imageUrl}) {
  return {
    'categories': [
      {
        'id': 'cat-1',
        'vendor_id': 'vendor-1',
        'category_name': 'Burgers',
        'sort_order': 1,
        'menu_items': [
          {
            'id': 'item-1',
            'menu_id': 'cat-1',
            'name': 'Classic Burger',
            'description': 'Loaded burger',
            'price': 149,
            'is_available': true,
            'image_url': imageUrl,
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
        'category': 'Burgers',
        'category_name': 'Burgers',
        'category_id': 'cat-1',
        'category_sort_order': 1,
        'vendor_id': 'vendor-1',
      }
    ],
  };
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

void main() {
  testWidgets('add item dialog persists image_url from upload flow', (tester) async {
    final api = _FakeMenuApiService(_menuPayload());

    await _pumpMenuScreen(
      tester,
      api,
      imagePicker: (_) async => 'https://cdn.example.com/new-item.png',
    );

    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Item name'), 'Veg Supreme');
    await tester.enterText(find.widgetWithText(TextField, 'Description'), 'House special');
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '199');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(api.postCalls, isNotEmpty);
    expect(api.postCalls.last['path'], '/menus/items');
    expect((api.postCalls.last['data'] as Map<String, dynamic>)['image_url'], 'https://cdn.example.com/new-item.png');
  });

  testWidgets('edit item dialog persists updated image_url from upload flow', (tester) async {
    final api = _FakeMenuApiService(_menuPayload(imageUrl: 'https://cdn.example.com/original.png'));

    await _pumpMenuScreen(
      tester,
      api,
      imagePicker: (_) async => 'https://cdn.example.com/updated-item.png',
    );

    final editIcons = find.byIcon(Icons.edit_outlined);
    await tester.tap(editIcons.last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Upload').first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    await tester.pumpAndSettle();

    expect(api.patchCalls, isNotEmpty);
    expect(api.patchCalls.last['path'], '/menus/items/item-1');
    expect((api.patchCalls.last['data'] as Map<String, dynamic>)['image_url'], 'https://cdn.example.com/updated-item.png');
  });

  testWidgets('invalid thumbnail URL falls back to unsupported-image icon', (tester) async {
    final api = _FakeMenuApiService(_menuPayload(imageUrl: 'https://example.invalid/does-not-exist.png'));

    await _pumpMenuScreen(tester, api);
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(Icons.image_not_supported_outlined), findsWidgets);
  });
}
