import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_hub/app.dart';

/// Values must match [MockFirebaseApp] from `firebase_core_platform_interface`
/// (used by [setupFirebaseCoreMocks]). Using real [DefaultFirebaseOptions]
/// triggers [duplicate-app] because the mock registers `apiKey: '123'`.
const _kTestFirebaseOptions = FirebaseOptions(
  apiKey: '123',
  appId: '123',
  messagingSenderId: '123',
  projectId: '123',
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp(options: _kTestFirebaseOptions);
  });

  testWidgets('HostelHubApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HostelHubApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);

    // Splash uses a 2.5s delayed navigation; flush it so no timer is left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
