import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AndroidManifest debe tener INTERNET permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    expect(manifest.existsSync(), isTrue);
    final content = manifest.readAsStringSync();
    expect(
      content,
      contains('<uses-permission android:name="android.permission.INTERNET"/>'),
    );
  });
}
