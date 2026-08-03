// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rudiment_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRudimentProgressCollection on Isar {
  IsarCollection<RudimentProgress> get rudimentProgress => this.collection();
}

const RudimentProgressSchema = CollectionSchema(
  name: r'RudimentProgress',
  id: 7043267250668754740,
  properties: {
    r'bestBpm': PropertySchema(
      id: 0,
      name: r'bestBpm',
      type: IsarType.long,
    ),
    r'currentBpm': PropertySchema(
      id: 1,
      name: r'currentBpm',
      type: IsarType.long,
    ),
    r'exerciseId': PropertySchema(
      id: 2,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'lastPracticed': PropertySchema(
      id: 3,
      name: r'lastPracticed',
      type: IsarType.dateTime,
    ),
    r'mastery': PropertySchema(
      id: 4,
      name: r'mastery',
      type: IsarType.string,
      enumMap: _RudimentProgressmasteryEnumValueMap,
    ),
    r'nextReviewDate': PropertySchema(
      id: 5,
      name: r'nextReviewDate',
      type: IsarType.dateTime,
    ),
    r'srInterval': PropertySchema(
      id: 6,
      name: r'srInterval',
      type: IsarType.long,
    ),
    r'srRepetitions': PropertySchema(
      id: 7,
      name: r'srRepetitions',
      type: IsarType.long,
    )
  },
  estimateSize: _rudimentProgressEstimateSize,
  serialize: _rudimentProgressSerialize,
  deserialize: _rudimentProgressDeserialize,
  deserializeProp: _rudimentProgressDeserializeProp,
  idName: r'id',
  indexes: {
    r'exerciseId': IndexSchema(
      id: -5431545612219001672,
      name: r'exerciseId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'exerciseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _rudimentProgressGetId,
  getLinks: _rudimentProgressGetLinks,
  attach: _rudimentProgressAttach,
  version: '3.1.0+1',
);

int _rudimentProgressEstimateSize(
  RudimentProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseId.length * 3;
  bytesCount += 3 + object.mastery.name.length * 3;
  return bytesCount;
}

void _rudimentProgressSerialize(
  RudimentProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.bestBpm);
  writer.writeLong(offsets[1], object.currentBpm);
  writer.writeString(offsets[2], object.exerciseId);
  writer.writeDateTime(offsets[3], object.lastPracticed);
  writer.writeString(offsets[4], object.mastery.name);
  writer.writeDateTime(offsets[5], object.nextReviewDate);
  writer.writeLong(offsets[6], object.srInterval);
  writer.writeLong(offsets[7], object.srRepetitions);
}

RudimentProgress _rudimentProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RudimentProgress();
  object.bestBpm = reader.readLong(offsets[0]);
  object.currentBpm = reader.readLong(offsets[1]);
  object.exerciseId = reader.readString(offsets[2]);
  object.id = id;
  object.lastPracticed = reader.readDateTime(offsets[3]);
  object.mastery = _RudimentProgressmasteryValueEnumMap[
          reader.readStringOrNull(offsets[4])] ??
      MasteryLevel.beginner;
  object.nextReviewDate = reader.readDateTime(offsets[5]);
  object.srInterval = reader.readLong(offsets[6]);
  object.srRepetitions = reader.readLong(offsets[7]);
  return object;
}

P _rudimentProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (_RudimentProgressmasteryValueEnumMap[
              reader.readStringOrNull(offset)] ??
          MasteryLevel.beginner) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RudimentProgressmasteryEnumValueMap = {
  r'beginner': r'beginner',
  r'developing': r'developing',
  r'competent': r'competent',
  r'proficient': r'proficient',
  r'mastered': r'mastered',
};
const _RudimentProgressmasteryValueEnumMap = {
  r'beginner': MasteryLevel.beginner,
  r'developing': MasteryLevel.developing,
  r'competent': MasteryLevel.competent,
  r'proficient': MasteryLevel.proficient,
  r'mastered': MasteryLevel.mastered,
};

Id _rudimentProgressGetId(RudimentProgress object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _rudimentProgressGetLinks(RudimentProgress object) {
  return [];
}

void _rudimentProgressAttach(
    IsarCollection<dynamic> col, Id id, RudimentProgress object) {
  object.id = id;
}

extension RudimentProgressByIndex on IsarCollection<RudimentProgress> {
  Future<RudimentProgress?> getByExerciseId(String exerciseId) {
    return getByIndex(r'exerciseId', [exerciseId]);
  }

  RudimentProgress? getByExerciseIdSync(String exerciseId) {
    return getByIndexSync(r'exerciseId', [exerciseId]);
  }

  Future<bool> deleteByExerciseId(String exerciseId) {
    return deleteByIndex(r'exerciseId', [exerciseId]);
  }

  bool deleteByExerciseIdSync(String exerciseId) {
    return deleteByIndexSync(r'exerciseId', [exerciseId]);
  }

  Future<List<RudimentProgress?>> getAllByExerciseId(
      List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'exerciseId', values);
  }

  List<RudimentProgress?> getAllByExerciseIdSync(
      List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'exerciseId', values);
  }

  Future<int> deleteAllByExerciseId(List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'exerciseId', values);
  }

  int deleteAllByExerciseIdSync(List<String> exerciseIdValues) {
    final values = exerciseIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'exerciseId', values);
  }

  Future<Id> putByExerciseId(RudimentProgress object) {
    return putByIndex(r'exerciseId', object);
  }

  Id putByExerciseIdSync(RudimentProgress object, {bool saveLinks = true}) {
    return putByIndexSync(r'exerciseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByExerciseId(List<RudimentProgress> objects) {
    return putAllByIndex(r'exerciseId', objects);
  }

  List<Id> putAllByExerciseIdSync(List<RudimentProgress> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'exerciseId', objects, saveLinks: saveLinks);
  }
}

extension RudimentProgressQueryWhereSort
    on QueryBuilder<RudimentProgress, RudimentProgress, QWhere> {
  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RudimentProgressQueryWhere
    on QueryBuilder<RudimentProgress, RudimentProgress, QWhereClause> {
  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause> idBetween(
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause>
      exerciseIdEqualTo(String exerciseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exerciseId',
        value: [exerciseId],
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterWhereClause>
      exerciseIdNotEqualTo(String exerciseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [],
              upper: [exerciseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [exerciseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [exerciseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseId',
              lower: [],
              upper: [exerciseId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension RudimentProgressQueryFilter
    on QueryBuilder<RudimentProgress, RudimentProgress, QFilterCondition> {
  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      bestBpmEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bestBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      bestBpmGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bestBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      bestBpmLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bestBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      bestBpmBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bestBpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      currentBpmEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      currentBpmGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      currentBpmLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      currentBpmBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentBpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      exerciseIdEqualTo(
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      exerciseIdBetween(
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      exerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      lastPracticedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastPracticed',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      lastPracticedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastPracticed',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      lastPracticedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastPracticed',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      lastPracticedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastPracticed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryEqualTo(
    MasteryLevel value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mastery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryGreaterThan(
    MasteryLevel value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mastery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryLessThan(
    MasteryLevel value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mastery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryBetween(
    MasteryLevel lower,
    MasteryLevel upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mastery',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mastery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mastery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mastery',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mastery',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mastery',
        value: '',
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      masteryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mastery',
        value: '',
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      nextReviewDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      nextReviewDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      nextReviewDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextReviewDate',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      nextReviewDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextReviewDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srIntervalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'srInterval',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srIntervalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'srInterval',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srIntervalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'srInterval',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srIntervalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'srInterval',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srRepetitionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'srRepetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srRepetitionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'srRepetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srRepetitionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'srRepetitions',
        value: value,
      ));
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterFilterCondition>
      srRepetitionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'srRepetitions',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RudimentProgressQueryObject
    on QueryBuilder<RudimentProgress, RudimentProgress, QFilterCondition> {}

extension RudimentProgressQueryLinks
    on QueryBuilder<RudimentProgress, RudimentProgress, QFilterCondition> {}

extension RudimentProgressQuerySortBy
    on QueryBuilder<RudimentProgress, RudimentProgress, QSortBy> {
  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByBestBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestBpm', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByBestBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestBpm', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByCurrentBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBpm', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByCurrentBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBpm', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByLastPracticed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticed', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByLastPracticedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticed', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByMastery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mastery', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByMasteryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mastery', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortBySrInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srInterval', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortBySrIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srInterval', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortBySrRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srRepetitions', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      sortBySrRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srRepetitions', Sort.desc);
    });
  }
}

extension RudimentProgressQuerySortThenBy
    on QueryBuilder<RudimentProgress, RudimentProgress, QSortThenBy> {
  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByBestBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestBpm', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByBestBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestBpm', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByCurrentBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBpm', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByCurrentBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBpm', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByExerciseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByExerciseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseId', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByLastPracticed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticed', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByLastPracticedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastPracticed', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByMastery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mastery', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByMasteryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mastery', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenByNextReviewDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextReviewDate', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenBySrInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srInterval', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenBySrIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srInterval', Sort.desc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenBySrRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srRepetitions', Sort.asc);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QAfterSortBy>
      thenBySrRepetitionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srRepetitions', Sort.desc);
    });
  }
}

extension RudimentProgressQueryWhereDistinct
    on QueryBuilder<RudimentProgress, RudimentProgress, QDistinct> {
  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctByBestBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bestBpm');
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctByCurrentBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentBpm');
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctByExerciseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctByLastPracticed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastPracticed');
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct> distinctByMastery(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mastery', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctByNextReviewDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextReviewDate');
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctBySrInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'srInterval');
    });
  }

  QueryBuilder<RudimentProgress, RudimentProgress, QDistinct>
      distinctBySrRepetitions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'srRepetitions');
    });
  }
}

extension RudimentProgressQueryProperty
    on QueryBuilder<RudimentProgress, RudimentProgress, QQueryProperty> {
  QueryBuilder<RudimentProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RudimentProgress, int, QQueryOperations> bestBpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bestBpm');
    });
  }

  QueryBuilder<RudimentProgress, int, QQueryOperations> currentBpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentBpm');
    });
  }

  QueryBuilder<RudimentProgress, String, QQueryOperations>
      exerciseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseId');
    });
  }

  QueryBuilder<RudimentProgress, DateTime, QQueryOperations>
      lastPracticedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastPracticed');
    });
  }

  QueryBuilder<RudimentProgress, MasteryLevel, QQueryOperations>
      masteryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mastery');
    });
  }

  QueryBuilder<RudimentProgress, DateTime, QQueryOperations>
      nextReviewDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextReviewDate');
    });
  }

  QueryBuilder<RudimentProgress, int, QQueryOperations> srIntervalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'srInterval');
    });
  }

  QueryBuilder<RudimentProgress, int, QQueryOperations>
      srRepetitionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'srRepetitions');
    });
  }
}
