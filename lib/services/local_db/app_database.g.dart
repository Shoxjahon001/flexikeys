// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AacEventsTable extends AacEvents
    with TableInfo<$AacEventsTable, AacEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AacEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sentenceSpokenMeta =
      const VerificationMeta('sentenceSpoken');
  @override
  late final GeneratedColumn<String> sentenceSpoken = GeneratedColumn<String>(
      'sentence_spoken', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tappedAtMeta =
      const VerificationMeta('tappedAt');
  @override
  late final GeneratedColumn<DateTime> tappedAt = GeneratedColumn<DateTime>(
      'tapped_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, cardId, category, sentenceSpoken, language, tappedAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aac_events';
  @override
  VerificationContext validateIntegrity(Insertable<AacEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sentence_spoken')) {
      context.handle(
          _sentenceSpokenMeta,
          sentenceSpoken.isAcceptableOrUnknown(
              data['sentence_spoken']!, _sentenceSpokenMeta));
    } else if (isInserting) {
      context.missing(_sentenceSpokenMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('tapped_at')) {
      context.handle(_tappedAtMeta,
          tappedAt.isAcceptableOrUnknown(data['tapped_at']!, _tappedAtMeta));
    } else if (isInserting) {
      context.missing(_tappedAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AacEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AacEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      sentenceSpoken: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sentence_spoken'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      tappedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}tapped_at'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $AacEventsTable createAlias(String alias) {
    return $AacEventsTable(attachedDatabase, alias);
  }
}

class AacEvent extends DataClass implements Insertable<AacEvent> {
  final int id;

  /// References an AacCardDef.id (starter vocabulary or custom card) — not
  /// a foreign key, since the vocabulary itself lives in bundled JSON, not
  /// this database.
  final String cardId;

  /// AacCategory.name — denormalized onto the event so historical events
  /// remain queryable/meaningful even if a card is later re-categorized.
  final String category;

  /// The exact sentence spoken at tap time (post-template-substitution for
  /// two-step/branch cards) — denormalized for the same reason as category.
  final String sentenceSpoken;

  /// 'en' | 'uz' | 'ru' — the language active when the card was tapped.
  final String language;
  final DateTime tappedAt;

  /// Set once the backend has accepted this event in a sync batch.
  final bool synced;
  const AacEvent(
      {required this.id,
      required this.cardId,
      required this.category,
      required this.sentenceSpoken,
      required this.language,
      required this.tappedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['category'] = Variable<String>(category);
    map['sentence_spoken'] = Variable<String>(sentenceSpoken);
    map['language'] = Variable<String>(language);
    map['tapped_at'] = Variable<DateTime>(tappedAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AacEventsCompanion toCompanion(bool nullToAbsent) {
    return AacEventsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      category: Value(category),
      sentenceSpoken: Value(sentenceSpoken),
      language: Value(language),
      tappedAt: Value(tappedAt),
      synced: Value(synced),
    );
  }

  factory AacEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AacEvent(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      category: serializer.fromJson<String>(json['category']),
      sentenceSpoken: serializer.fromJson<String>(json['sentenceSpoken']),
      language: serializer.fromJson<String>(json['language']),
      tappedAt: serializer.fromJson<DateTime>(json['tappedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'category': serializer.toJson<String>(category),
      'sentenceSpoken': serializer.toJson<String>(sentenceSpoken),
      'language': serializer.toJson<String>(language),
      'tappedAt': serializer.toJson<DateTime>(tappedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AacEvent copyWith(
          {int? id,
          String? cardId,
          String? category,
          String? sentenceSpoken,
          String? language,
          DateTime? tappedAt,
          bool? synced}) =>
      AacEvent(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        category: category ?? this.category,
        sentenceSpoken: sentenceSpoken ?? this.sentenceSpoken,
        language: language ?? this.language,
        tappedAt: tappedAt ?? this.tappedAt,
        synced: synced ?? this.synced,
      );
  AacEvent copyWithCompanion(AacEventsCompanion data) {
    return AacEvent(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      category: data.category.present ? data.category.value : this.category,
      sentenceSpoken: data.sentenceSpoken.present
          ? data.sentenceSpoken.value
          : this.sentenceSpoken,
      language: data.language.present ? data.language.value : this.language,
      tappedAt: data.tappedAt.present ? data.tappedAt.value : this.tappedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AacEvent(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('category: $category, ')
          ..write('sentenceSpoken: $sentenceSpoken, ')
          ..write('language: $language, ')
          ..write('tappedAt: $tappedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, cardId, category, sentenceSpoken, language, tappedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AacEvent &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.category == this.category &&
          other.sentenceSpoken == this.sentenceSpoken &&
          other.language == this.language &&
          other.tappedAt == this.tappedAt &&
          other.synced == this.synced);
}

class AacEventsCompanion extends UpdateCompanion<AacEvent> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<String> category;
  final Value<String> sentenceSpoken;
  final Value<String> language;
  final Value<DateTime> tappedAt;
  final Value<bool> synced;
  const AacEventsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.category = const Value.absent(),
    this.sentenceSpoken = const Value.absent(),
    this.language = const Value.absent(),
    this.tappedAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  AacEventsCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required String category,
    required String sentenceSpoken,
    required String language,
    required DateTime tappedAt,
    this.synced = const Value.absent(),
  })  : cardId = Value(cardId),
        category = Value(category),
        sentenceSpoken = Value(sentenceSpoken),
        language = Value(language),
        tappedAt = Value(tappedAt);
  static Insertable<AacEvent> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<String>? category,
    Expression<String>? sentenceSpoken,
    Expression<String>? language,
    Expression<DateTime>? tappedAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (category != null) 'category': category,
      if (sentenceSpoken != null) 'sentence_spoken': sentenceSpoken,
      if (language != null) 'language': language,
      if (tappedAt != null) 'tapped_at': tappedAt,
      if (synced != null) 'synced': synced,
    });
  }

  AacEventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? cardId,
      Value<String>? category,
      Value<String>? sentenceSpoken,
      Value<String>? language,
      Value<DateTime>? tappedAt,
      Value<bool>? synced}) {
    return AacEventsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      category: category ?? this.category,
      sentenceSpoken: sentenceSpoken ?? this.sentenceSpoken,
      language: language ?? this.language,
      tappedAt: tappedAt ?? this.tappedAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sentenceSpoken.present) {
      map['sentence_spoken'] = Variable<String>(sentenceSpoken.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (tappedAt.present) {
      map['tapped_at'] = Variable<DateTime>(tappedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AacEventsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('category: $category, ')
          ..write('sentenceSpoken: $sentenceSpoken, ')
          ..write('language: $language, ')
          ..write('tappedAt: $tappedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AacEventsTable aacEvents = $AacEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [aacEvents];
}

typedef $$AacEventsTableCreateCompanionBuilder = AacEventsCompanion Function({
  Value<int> id,
  required String cardId,
  required String category,
  required String sentenceSpoken,
  required String language,
  required DateTime tappedAt,
  Value<bool> synced,
});
typedef $$AacEventsTableUpdateCompanionBuilder = AacEventsCompanion Function({
  Value<int> id,
  Value<String> cardId,
  Value<String> category,
  Value<String> sentenceSpoken,
  Value<String> language,
  Value<DateTime> tappedAt,
  Value<bool> synced,
});

class $$AacEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AacEventsTable> {
  $$AacEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardId => $composableBuilder(
      column: $table.cardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sentenceSpoken => $composableBuilder(
      column: $table.sentenceSpoken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get tappedAt => $composableBuilder(
      column: $table.tappedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));
}

class $$AacEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AacEventsTable> {
  $$AacEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardId => $composableBuilder(
      column: $table.cardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sentenceSpoken => $composableBuilder(
      column: $table.sentenceSpoken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get tappedAt => $composableBuilder(
      column: $table.tappedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));
}

class $$AacEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AacEventsTable> {
  $$AacEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get sentenceSpoken => $composableBuilder(
      column: $table.sentenceSpoken, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<DateTime> get tappedAt =>
      $composableBuilder(column: $table.tappedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AacEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AacEventsTable,
    AacEvent,
    $$AacEventsTableFilterComposer,
    $$AacEventsTableOrderingComposer,
    $$AacEventsTableAnnotationComposer,
    $$AacEventsTableCreateCompanionBuilder,
    $$AacEventsTableUpdateCompanionBuilder,
    (AacEvent, BaseReferences<_$AppDatabase, $AacEventsTable, AacEvent>),
    AacEvent,
    PrefetchHooks Function()> {
  $$AacEventsTableTableManager(_$AppDatabase db, $AacEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AacEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AacEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AacEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> sentenceSpoken = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<DateTime> tappedAt = const Value.absent(),
            Value<bool> synced = const Value.absent(),
          }) =>
              AacEventsCompanion(
            id: id,
            cardId: cardId,
            category: category,
            sentenceSpoken: sentenceSpoken,
            language: language,
            tappedAt: tappedAt,
            synced: synced,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String cardId,
            required String category,
            required String sentenceSpoken,
            required String language,
            required DateTime tappedAt,
            Value<bool> synced = const Value.absent(),
          }) =>
              AacEventsCompanion.insert(
            id: id,
            cardId: cardId,
            category: category,
            sentenceSpoken: sentenceSpoken,
            language: language,
            tappedAt: tappedAt,
            synced: synced,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AacEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AacEventsTable,
    AacEvent,
    $$AacEventsTableFilterComposer,
    $$AacEventsTableOrderingComposer,
    $$AacEventsTableAnnotationComposer,
    $$AacEventsTableCreateCompanionBuilder,
    $$AacEventsTableUpdateCompanionBuilder,
    (AacEvent, BaseReferences<_$AppDatabase, $AacEventsTable, AacEvent>),
    AacEvent,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AacEventsTableTableManager get aacEvents =>
      $$AacEventsTableTableManager(_db, _db.aacEvents);
}
