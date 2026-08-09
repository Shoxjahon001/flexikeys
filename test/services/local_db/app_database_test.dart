import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/services/local_db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AacEvents table', () {
    test('inserted event defaults synced to false', () async {
      final id = await db.into(db.aacEvents).insert(
            AacEventsCompanion.insert(
              cardId: 'ne_water',
              category: 'needs',
              sentenceSpoken: 'I want water.',
              language: 'en',
              tappedAt: DateTime(2026, 1, 1, 10),
            ),
          );
      final row = await (db.select(db.aacEvents)..where((t) => t.id.equals(id))).getSingle();
      expect(row.synced, isFalse);
      expect(row.cardId, 'ne_water');
    });

    test('id auto-increments across inserts', () async {
      final id1 = await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'a',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2026),
          ));
      final id2 = await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'b',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2026),
          ));
      expect(id2, greaterThan(id1));
    });

    test('querying unsynced events excludes synced ones', () async {
      final unsyncedId = await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'unsynced',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2026),
          ));
      await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'synced',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2026),
            synced: const Value(true),
          ));

      final pending = await (db.select(db.aacEvents)..where((t) => t.synced.equals(false))).get();
      expect(pending, hasLength(1));
      expect(pending.single.id, unsyncedId);
    });

    test('marking events synced by id updates only those rows', () async {
      final id1 = await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'a',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2026),
          ));
      await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'b',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2026),
          ));

      await (db.update(db.aacEvents)..where((t) => t.id.equals(id1)))
          .write(const AacEventsCompanion(synced: Value(true)));

      final pending = await (db.select(db.aacEvents)..where((t) => t.synced.equals(false))).get();
      expect(pending, hasLength(1));
      expect(pending.single.cardId, 'b');
    });

    test('pruning deletes only synced rows older than the cutoff', () async {
      final oldSyncedId = await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'old_synced',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2020),
            synced: const Value(true),
          ));
      final oldUnsyncedId = await db.into(db.aacEvents).insert(AacEventsCompanion.insert(
            cardId: 'old_unsynced',
            category: 'needs',
            sentenceSpoken: 's',
            language: 'en',
            tappedAt: DateTime(2020),
          ));

      final cutoff = DateTime(2025);
      await (db.delete(db.aacEvents)
            ..where((t) => t.synced.equals(true) & t.tappedAt.isSmallerThanValue(cutoff)))
          .go();

      final remainingIds = (await db.select(db.aacEvents).get()).map((r) => r.id).toSet();
      expect(remainingIds, isNot(contains(oldSyncedId)));
      expect(remainingIds, contains(oldUnsyncedId)); // never prune unsynced events
    });
  });
}
