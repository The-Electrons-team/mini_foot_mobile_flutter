import 'package:flutter_test/flutter_test.dart';
import 'package:minifoot/startup_config.dart';

void main() {
  group('buildWebFirebaseOptions', () {
    test('retourne null si les variables requises sont absentes', () {
      final options = buildWebFirebaseOptions(
        apiKey: null,
        authDomain: null,
        projectId: 'demo-project',
        storageBucket: 'demo.appspot.com',
        messagingSenderId: '123456',
        appId: 'demo-app-id',
      );

      expect(options, isNull);
    });

    test('construit les options si toutes les variables requises existent', () {
      final options = buildWebFirebaseOptions(
        apiKey: 'api-key',
        authDomain: 'demo.firebaseapp.com',
        projectId: 'demo-project',
        storageBucket: 'demo.appspot.com',
        messagingSenderId: '123456',
        appId: 'demo-app-id',
        measurementId: 'G-123456',
      );

      expect(options, isNotNull);
      expect(options!.apiKey, 'api-key');
      expect(options.projectId, 'demo-project');
      expect(options.measurementId, 'G-123456');
    });
  });
}
