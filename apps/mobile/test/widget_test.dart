import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastrohost_mobile/main.dart';

void main() {
  testWidgets('GastroHost smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GastroHostApp()));
    expect(find.text('GASTROHOST'), findsOneWidget);
  });
}
