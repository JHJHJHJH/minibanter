import 'package:flutter_test/flutter_test.dart';
import 'package:minibanter_compositor_example/main.dart';

void main() {
  testWidgets('renders the native compositor configuration', (tester) async {
    await tester.pumpWidget(const CompositorExampleApp());

    expect(find.textContaining('Native compositor contract:'), findsOneWidget);
  });
}
