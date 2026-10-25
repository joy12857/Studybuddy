import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:study_buddy/main.dart';

void main() {
  setUpAll(() async {
    // Setup mock values for SharedPreferences before initializing Supabase
    SharedPreferences.setMockInitialValues({});
    
    // Initialize Supabase for test environment
    await Supabase.initialize(
      url: 'https://klfxswdtprujmapxfqjg.supabase.co',
      publishableKey: 'sb_publishable_6bwXXqJc0N-z-cS7l0_lKA_aT2wwwIf',
    );
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the MaterialApp is present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
