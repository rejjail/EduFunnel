import 'package:flutter_test/flutter_test.dart';
import 'package:web_ppdb/main.dart';

void main() {
  testWidgets('PPDB app dapat ditampilkan', (WidgetTester tester) async {
    await tester.pumpWidget(const PPDBApp());

    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(find.text('LOGIN SEKARANG'), findsOneWidget);
  });
}
