import 'package:flutter_test/flutter_test.dart';
import 'package:voz_animal/main.dart';

void main() {
  testWidgets('App renders splash', (tester) async {
    await tester.pumpWidget(const VozAnimalApp());
    expect(find.text('Voz Animal'), findsOneWidget);
  });
}
