import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topik_go/app/app.dart';

void main() {
  testWidgets('navigates from splash to AI notice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: TopikGoApp()));

    expect(find.text('TOPIK GO'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('AI 생성 콘텐츠 알림'), findsOneWidget);
  });
}
