import 'package:armazem/core/database/change_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseChangeTracker', () {
    test('marca alterações pendentes e limpa após o backup', () {
      final tracker = DatabaseChangeTracker();

      expect(tracker.hasPendingBackup, isFalse);

      tracker.markChanged();
      expect(tracker.hasPendingBackup, isTrue);

      tracker.clearPendingBackup();
      expect(tracker.hasPendingBackup, isFalse);
    });
  });
}
