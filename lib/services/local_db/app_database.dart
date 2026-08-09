library app_database;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart'; // bundles the native sqlite3 lib on Android/iOS

part 'app_database.g.dart';

/// Append-only local log of every "My Voice" (AAC) card tap.
///
/// This is high-volume by design — every tap, not just level completions —
/// which is exactly the failure mode the existing `TelemetryService`
/// (SharedPreferences JSON-blob queue) already documents as a gap for itself
/// (see `lib/services/telemetry/telemetry_service.dart`, "STUB #5"). AAC
/// events live in a real embedded database instead: no full-queue rewrite
/// per event, no unbounded-growth risk on prolonged offline, and real
/// queries available for later features (e.g. "which cards were tapped most
/// this week") without loading everything into memory first.
///
/// Lower-volume AAC state (custom card definitions, progression level) stays
/// on the existing SharedPreferences typed-JSON pattern (see
/// `AacCustomCardStore`) — this table is deliberately scoped to the one
/// thing that actually needs it.
class AacEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// References an AacCardDef.id (starter vocabulary or custom card) — not
  /// a foreign key, since the vocabulary itself lives in bundled JSON, not
  /// this database.
  TextColumn get cardId => text()();

  /// AacCategory.name — denormalized onto the event so historical events
  /// remain queryable/meaningful even if a card is later re-categorized.
  TextColumn get category => text()();

  /// The exact sentence spoken at tap time (post-template-substitution for
  /// two-step/branch cards) — denormalized for the same reason as category.
  TextColumn get sentenceSpoken => text()();

  /// 'en' | 'uz' | 'ru' — the language active when the card was tapped.
  TextColumn get language => text()();

  DateTimeColumn get tappedAt => dateTime()();

  /// Set once the backend has accepted this event in a sync batch.
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [AacEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  /// For widget/unit tests — pass an in-memory `NativeDatabase.memory()`.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'flexikeys.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
