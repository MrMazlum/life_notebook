import 'package:flutter_test/flutter_test.dart';
import 'package:not_defterim/main.dart'; // Projenin ana dosyasını çağırıyoruz

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // MyApp yerine artık LifeNotebookApp var, onu başlatıyoruz
    await tester.pumpWidget(const LifeNotebookApp());
  });
}