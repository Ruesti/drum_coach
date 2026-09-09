// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSessionLogCollection on Isar {
  IsarCollection<SessionLog> get sessionLogs => this.collection();
}

const SessionLogSchema = CollectionSchema(
  name: r'SessionLog',
  id: -2594700486533071519,
  properties: {
    r'androidVersion': PropertySchema(
      id: 0,
      name: r'androidVersion',
      type: IsarType.string,
    ),
    r'audioSource': PropertySchema(
      id: 1,
      name: r'audioSource',
      type: IsarType.string,
    ),
    r'autoGain': PropertySchema(
      id: 2,
      name: r'autoGain',
      type: IsarType.bool,
    ),
    r'bpm': PropertySchema(
      id: 3,
      name: r'bpm',
      type: IsarType.long,
    ),
    r'clickNoteIndices': PropertySchema(
      id: 4,
      name: r'clickNoteIndices',
      type: IsarType.longList,
    ),
    r'clickTimesMs': PropertySchema(
      id: 5,
      name: r'clickTimesMs',
      type: IsarType.doubleList,
    ),
    r'deviceModel': PropertySchema(
      id: 6,
      name: r'deviceModel',
      type: IsarType.string,
    ),
    r'durationSeconds': PropertySchema(
      id: 7,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'echoCancel': PropertySchema(
      id: 8,
      name: r'echoCancel',
      type: IsarType.bool,
    ),
    r'events': PropertySchema(
      id: 9,
      name: r'events',
      type: IsarType.objectList,
      target: r'OnsetEvent',
    ),
    r'exerciseId': PropertySchema(
      id: 10,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'headphones': PropertySchema(
      id: 11,
      name: r'headphones',
      type: IsarType.string,
    ),
    r'latencyOffsetMs': PropertySchema(
      id: 12,
      name: r'latencyOffsetMs',
      type: IsarType.double,
    ),
    r'mode': PropertySchema(
      id: 13,
      name: r'mode',
      type: IsarType.string,
    ),
    r'noiseSuppress': PropertySchema(
      id: 14,
      name: r'noiseSuppress',
      type: IsarType.bool,
    ),
    r'rating': PropertySchema(
      id: 15,
      name: r'rating',
      type: IsarType.long,
    ),
    r'sampleRate': PropertySchema(
      id: 16,
      name: r'sampleRate',
      type: IsarType.long,
    ),
    r'sessionUid': PropertySchema(
      id: 17,
      name: r'sessionUid',
      type: IsarType.string,
    ),
    r'startedAt': PropertySchema(
      id: 18,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'unprocessedSupported': PropertySchema(
      id: 19,
      name: r'unprocessedSupported',
      type: IsarType.bool,
    )
  },
  estimateSize: _sessionLogEstimateSize,
  serialize: _sessionLogSerialize,
  deserialize: _sessionLogDeserialize,
  deserializeProp: _sessionLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'sessionUid': IndexSchema(
      id: 8928449750912807787,
      name: r'sessionUid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sessionUid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'OnsetEvent': OnsetEventSchema},
  getId: _sessionLogGetId,
  getLinks: _sessionLogGetLinks,
  attach: _sessionLogAttach,
  version: '3.1.0+1',
);

int _sessionLogEstimateSize(
  SessionLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.androidVersion.length * 3;
  bytesCount += 3 + object.audioSource.length * 3;
  bytesCount += 3 + object.clickNoteIndices.length * 8;
  bytesCount += 3 + object.clickTimesMs.length * 8;
  bytesCount += 3 + object.deviceModel.length * 3;
  bytesCount += 3 + object.events.length * 3;
  {
    final offsets = allOffsets[OnsetEvent]!;
    for (var i = 0; i < object.events.length; i++) {
      final value = object.events[i];
      bytesCount += OnsetEventSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.exerciseId.length * 3;
  bytesCount += 3 + object.headphones.length * 3;
  bytesCount += 3 + object.mode.length * 3;
  bytesCount += 3 + object.sessionUid.length * 3;
  return bytesCount;
}

void _sessionLogSerialize(
  SessionLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.androidVersion);
  writer.writeString(offsets[1], object.audioSource);
  writer.writeBool(offsets[2], object.autoGain);
  writer.writeLong(offsets[3], object.bpm);
  writer.writeLongList(offsets[4], object.clickNoteIndices);
  writer.writeDoubleList(offsets[5], object.clickTimesMs);
  writer.writeString(offsets[6], object.deviceModel);
  writer.writeLong(offsets[7], object.durationSeconds);
  writer.writeBool(offsets[8], object.echoCancel);
  writer.writeObjectList<OnsetEvent>(
    offsets[9],
    allOffsets,
    OnsetEventSchema.serialize,
    object.events,
  );
  writer.writeString(offsets[10], object.exerciseId);
  writer.writeString(offsets[11], object.headphones);
  writer.writeDouble(offsets[12], object.latencyOffsetMs);
  writer.writeString(offsets[13], object.mode);
  writer.writeBool(offsets[14], object.noiseSuppress);
  writer.writeLong(offsets[15], object.rating);
  writer.writeLong(offsets[16], object.sampleRate);
  writer.writeString(offsets[17], object.sessionUid);
  writer.writeDateTime(offsets[18], object.startedAt);
  writer.writeBool(offsets[19], object.unprocessedSupported);
}

SessionLog _sessionLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SessionLog();
  object.androidVersion = reader.readString(offsets[0]);
  object.audioSource = reader.readString(offsets[1]);
  object.autoGain = reader.readBool(offsets[2]);
  object.bpm = reader.readLong(offsets[3]);
  object.clickNoteIndices = reader.readLongList(offsets[4]) ?? [];
  object.clickTimesMs = reader.readDoubleList(offsets[5]) ?? [];
  object.deviceModel = reader.readString(offsets[6]);
  object.durationSeconds = reader.readLong(offsets[7]);
  object.echoCancel = reader.readBool(offsets[8]);
  object.events = reader.readObjectList<OnsetEvent>(
        offsets[9],
        OnsetEventSchema.deserialize,
        allOffsets,
        OnsetEvent(),
      ) ??
      [];
  object.exerciseId = reader.readString(offsets[10]);
  object.headphones = reader.readString(offsets[11]);
  object.id = id;
  object.latencyOffsetMs = reader.readDoubleOrNull(offsets[12]);
  object.mode = reader.readString(offsets[13]);
  object.noiseSuppress = reader.readBool(offsets[14]);
  object.rating = reader.readLongOrNull(offsets[15]);
  object.sampleRate = reader.readLong(offsets[16]);
  object.sessionUid = reader.readString(offsets[17]);
  object.startedAt = reader.readDateTime(offsets[18]);
  object.unprocessedSupported = reader.readBoolOrNull(offsets[19]);
  return object;
}

P _sessionLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLongList(offset) ?? []) as P;
    case 5:
      return (reader.readDoubleList(offset) ?? []) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readObjectList<OnsetEvent>(
            offset,
            OnsetEventSchema.deserialize,
            allOffsets,
            OnsetEvent(),
          ) ??
          []) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readLong(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readDateTime(offset)) as P;
    case 19:
      return (reader.readBoolOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sessionLogGetId(SessionLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sessionLogGetLinks(SessionLog object) {
  return [];
}

void _sessionLogAttach(IsarCollection<dynamic> col, Id id, SessionLog object) {
  object.id = id;
}

extension SessionLogByIndex on IsarCollection<SessionLog> {
  Future<SessionLog?> getBySessionUid(String sessionUid) {
    return getByIndex(r'sessionUid', [sessionUid]);
  }

  SessionLog? getBySessionUidSync(String sessionUid) {
    return getByIndexSync(r'sessionUid', [sessionUid]);
  }

  Future<bool> deleteBySessionUid(String sessionUid) {
    return deleteByIndex(r'sessionUid', [sessionUid]);
  }

  bool deleteBySessionUidSync(String sessionUid) {
    return deleteByIndexSync(r'sessionUid', [sessionUid]);
  }

  Future<List<SessionLog?>> getAllBySessionUid(List<String> sessionUidValues) {
    final values = sessionUidValues.map((e) => [e]).toList();
    return getAllByIndex(r'sessionUid', values);
  }

  List<SessionLog?> getAllBySessionUidSync(List<String> sessionUidValues) {
    final values = sessionUidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'sessionUid', values);
  }

  Future<int> deleteAllBySessionUid(List<String> sessionUidValues) {
    final values = sessionUidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'sessionUid', values);
  }

  int deleteAllBySessionUidSync(List<String> sessionUidValues) {
    final values = sessionUidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sessionUid', values);
  }

  Future<Id> putBySessionUid(SessionLog object) {
    return putByIndex(r'sessionUid', object);
  }

  Id putBySessionUidSync(SessionLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'sessionUid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySessionUid(List<SessionLog> objects) {
    return putAllByIndex(r'sessionUid', objects);
  }

  List<Id> putAllBySessionUidSync(List<SessionLog> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'sessionUid', objects, saveLinks: saveLinks);
  }
}

extension SessionLogQueryWhereSort
    on QueryBuilder<SessionLog, SessionLog, QWhere> {
  QueryBuilder<SessionLog, SessionLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SessionLogQueryWhere
    on QueryBuilder<SessionLog, SessionLog, QWhereClause> {
  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> sessionUidEqualTo(
      String sessionUid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sessionUid',
        value: [sessionUid],
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterWhereClause> sessionUidNotEqualTo(
      String sessionUid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionUid',
              lower: [],
              upper: [sessionUid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionUid',
              lower: [sessionUid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionUid',
              lower: [sessionUid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sessionUid',
              lower: [],
              upper: [sessionUid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SessionLogQueryFilter
    on QueryBuilder<SessionLog, SessionLog, QFilterCondition> {
  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'androidVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'androidVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'androidVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'androidVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'androidVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'androidVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'androidVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'androidVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'androidVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      androidVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'androidVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioSource',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      audioSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioSource',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> autoGainEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoGain',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> bpmEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bpm',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> bpmGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bpm',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> bpmLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bpm',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> bpmBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clickNoteIndices',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clickNoteIndices',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clickNoteIndices',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clickNoteIndices',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickNoteIndices',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickNoteIndices',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickNoteIndices',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickNoteIndices',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickNoteIndices',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickNoteIndicesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickNoteIndices',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clickTimesMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clickTimesMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clickTimesMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clickTimesMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickTimesMs',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickTimesMs',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickTimesMs',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickTimesMs',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickTimesMs',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      clickTimesMsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'clickTimesMs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceModel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceModel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceModel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceModel',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      deviceModelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceModel',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      durationSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      durationSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      durationSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> echoCancelEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'echoCancel',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      eventsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> eventsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      eventsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      eventsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      eventsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      eventsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'events',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> exerciseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> exerciseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> exerciseIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> headphonesEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headphones',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'headphones',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'headphones',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> headphonesBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'headphones',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'headphones',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'headphones',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'headphones',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> headphonesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'headphones',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'headphones',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      headphonesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'headphones',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      latencyOffsetMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latencyOffsetMs',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      latencyOffsetMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latencyOffsetMs',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      latencyOffsetMsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latencyOffsetMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      latencyOffsetMsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latencyOffsetMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      latencyOffsetMsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latencyOffsetMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      latencyOffsetMsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latencyOffsetMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mode',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      noiseSuppressEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noiseSuppress',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> ratingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rating',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      ratingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rating',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> ratingEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> ratingGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> ratingLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> ratingBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> sampleRateEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sampleRate',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sampleRateGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sampleRate',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sampleRateLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sampleRate',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> sampleRateBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sampleRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> sessionUidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sessionUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sessionUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> sessionUidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sessionUid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sessionUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sessionUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sessionUid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> sessionUidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sessionUid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sessionUid',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      sessionUidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sessionUid',
        value: '',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> startedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      startedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> startedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      unprocessedSupportedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'unprocessedSupported',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      unprocessedSupportedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'unprocessedSupported',
      ));
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition>
      unprocessedSupportedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unprocessedSupported',
        value: value,
      ));
    });
  }
}

extension SessionLogQueryObject
    on QueryBuilder<SessionLog, SessionLog, QFilterCondition> {
  QueryBuilder<SessionLog, SessionLog, QAfterFilterCondition> eventsElement(
      FilterQuery<OnsetEvent> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'events');
    });
  }
}

extension SessionLogQueryLinks
    on QueryBuilder<SessionLog, SessionLog, QFilterCondition> {}

extension SessionLogQuerySortBy
    on QueryBuilder<SessionLog, SessionLog, QSortBy> {
  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByAndroidVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'androidVersion', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      sortByAndroidVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'androidVersion', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByAudioSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioSource', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByAudioSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioSource', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByAutoGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoGain', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByAutoGainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoGain', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByDeviceModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceModel', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByDeviceModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceModel', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByEchoCancel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'echoCancel', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByEchoCancelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'echoCancel', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByHeadphones() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headphones', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByHeadphonesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headphones', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByLatencyOffsetMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latencyOffsetMs', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      sortByLatencyOffsetMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latencyOffsetMs', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByNoiseSuppress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseSuppress', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByNoiseSuppressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseSuppress', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortBySampleRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sampleRate', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortBySampleRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sampleRate', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortBySessionUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionUid', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortBySessionUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionUid', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      sortByUnprocessedSupported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unprocessedSupported', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      sortByUnprocessedSupportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unprocessedSupported', Sort.desc);
    });
  }
}

extension SessionLogQuerySortThenBy
    on QueryBuilder<SessionLog, SessionLog, QSortThenBy> {
  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByAndroidVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'androidVersion', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      thenByAndroidVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'androidVersion', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByAudioSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioSource', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByAudioSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioSource', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByAutoGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoGain', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByAutoGainDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoGain', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByDeviceModel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceModel', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByDeviceModelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceModel', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByEchoCancel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'echoCancel', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByEchoCancelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'echoCancel', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByHeadphones() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headphones', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByHeadphonesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headphones', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByLatencyOffsetMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latencyOffsetMs', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      thenByLatencyOffsetMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latencyOffsetMs', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByNoiseSuppress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseSuppress', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByNoiseSuppressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseSuppress', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenBySampleRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sampleRate', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenBySampleRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sampleRate', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenBySessionUid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionUid', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenBySessionUidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sessionUid', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy> thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      thenByUnprocessedSupported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unprocessedSupported', Sort.asc);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QAfterSortBy>
      thenByUnprocessedSupportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unprocessedSupported', Sort.desc);
    });
  }
}

extension SessionLogQueryWhereDistinct
    on QueryBuilder<SessionLog, SessionLog, QDistinct> {
  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByAndroidVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'androidVersion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByAudioSource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioSource', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByAutoGain() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoGain');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bpm');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByClickNoteIndices() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clickNoteIndices');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByClickTimesMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clickTimesMs');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByDeviceModel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceModel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByEchoCancel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'echoCancel');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByExerciseId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByHeadphones(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'headphones', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByLatencyOffsetMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latencyOffsetMs');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByMode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByNoiseSuppress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noiseSuppress');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctBySampleRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sampleRate');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctBySessionUid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sessionUid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct> distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<SessionLog, SessionLog, QDistinct>
      distinctByUnprocessedSupported() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unprocessedSupported');
    });
  }
}

extension SessionLogQueryProperty
    on QueryBuilder<SessionLog, SessionLog, QQueryProperty> {
  QueryBuilder<SessionLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> androidVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'androidVersion');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> audioSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioSource');
    });
  }

  QueryBuilder<SessionLog, bool, QQueryOperations> autoGainProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoGain');
    });
  }

  QueryBuilder<SessionLog, int, QQueryOperations> bpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bpm');
    });
  }

  QueryBuilder<SessionLog, List<int>, QQueryOperations>
      clickNoteIndicesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clickNoteIndices');
    });
  }

  QueryBuilder<SessionLog, List<double>, QQueryOperations>
      clickTimesMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clickTimesMs');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> deviceModelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceModel');
    });
  }

  QueryBuilder<SessionLog, int, QQueryOperations> durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<SessionLog, bool, QQueryOperations> echoCancelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'echoCancel');
    });
  }

  QueryBuilder<SessionLog, List<OnsetEvent>, QQueryOperations>
      eventsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'events');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> exerciseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseId');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> headphonesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'headphones');
    });
  }

  QueryBuilder<SessionLog, double?, QQueryOperations>
      latencyOffsetMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latencyOffsetMs');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<SessionLog, bool, QQueryOperations> noiseSuppressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noiseSuppress');
    });
  }

  QueryBuilder<SessionLog, int?, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<SessionLog, int, QQueryOperations> sampleRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sampleRate');
    });
  }

  QueryBuilder<SessionLog, String, QQueryOperations> sessionUidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sessionUid');
    });
  }

  QueryBuilder<SessionLog, DateTime, QQueryOperations> startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<SessionLog, bool?, QQueryOperations>
      unprocessedSupportedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unprocessedSupported');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const OnsetEventSchema = Schema(
  name: r'OnsetEvent',
  id: 690981220464080000,
  properties: {
    r'deviationMs': PropertySchema(
      id: 0,
      name: r'deviationMs',
      type: IsarType.double,
    ),
    r'hand': PropertySchema(
      id: 1,
      name: r'hand',
      type: IsarType.string,
    ),
    r'notePosition': PropertySchema(
      id: 2,
      name: r'notePosition',
      type: IsarType.long,
    ),
    r'peakLevel': PropertySchema(
      id: 3,
      name: r'peakLevel',
      type: IsarType.double,
    ),
    r'timeMs': PropertySchema(
      id: 4,
      name: r'timeMs',
      type: IsarType.double,
    )
  },
  estimateSize: _onsetEventEstimateSize,
  serialize: _onsetEventSerialize,
  deserialize: _onsetEventDeserialize,
  deserializeProp: _onsetEventDeserializeProp,
);

int _onsetEventEstimateSize(
  OnsetEvent object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.hand;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _onsetEventSerialize(
  OnsetEvent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.deviationMs);
  writer.writeString(offsets[1], object.hand);
  writer.writeLong(offsets[2], object.notePosition);
  writer.writeDouble(offsets[3], object.peakLevel);
  writer.writeDouble(offsets[4], object.timeMs);
}

OnsetEvent _onsetEventDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OnsetEvent();
  object.deviationMs = reader.readDoubleOrNull(offsets[0]);
  object.hand = reader.readStringOrNull(offsets[1]);
  object.notePosition = reader.readLongOrNull(offsets[2]);
  object.peakLevel = reader.readDouble(offsets[3]);
  object.timeMs = reader.readDouble(offsets[4]);
  return object;
}

P _onsetEventDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension OnsetEventQueryFilter
    on QueryBuilder<OnsetEvent, OnsetEvent, QFilterCondition> {
  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      deviationMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deviationMs',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      deviationMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deviationMs',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      deviationMsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviationMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      deviationMsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviationMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      deviationMsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviationMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      deviationMsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviationMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hand',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hand',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hand',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hand',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hand',
        value: '',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> handIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hand',
        value: '',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      notePositionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notePosition',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      notePositionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notePosition',
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      notePositionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notePosition',
        value: value,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      notePositionGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notePosition',
        value: value,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      notePositionLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notePosition',
        value: value,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      notePositionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notePosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> peakLevelEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peakLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition>
      peakLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'peakLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> peakLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'peakLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> peakLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'peakLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> timeMsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> timeMsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> timeMsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeMs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OnsetEvent, OnsetEvent, QAfterFilterCondition> timeMsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension OnsetEventQueryObject
    on QueryBuilder<OnsetEvent, OnsetEvent, QFilterCondition> {}
