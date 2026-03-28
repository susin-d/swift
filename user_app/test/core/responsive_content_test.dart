void main() {
  // Placeholder main to prevent test runner errors.
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/widgets/responsive_content.dart';

void main() {
  testWidgets('ResponsiveContent constrains child width on large screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveContent(maxWidth: 720, child: SizedBox(height: 10)),
        ),
      ),
    );

    final sizedBox = tester.getSize(find.byType(SizedBox).first);
    expect(sizedBox.width, lessThanOrEqualTo(720));
  });
}
