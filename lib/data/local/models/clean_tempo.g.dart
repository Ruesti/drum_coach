// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_tempo.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCleanTempoCollection on Isar {
  IsarCollection<CleanTempo> get cleanTempos => this.collection();
}

const CleanTempoSchema = CollectionSchema(
  name: r'CleanTempo',
  id: 4547086166155614219,
  properties: {
    r'bpm': PropertySchema(
      id: 0,
      name: r'bpm',
      type: IsarType.long,
    ),
    r'exerciseKey': PropertySchema(
      id: 1,
      name: r'exerciseKey',
      type: IsarType.string,
    )
  },
  estimateSize: _cleanTempoEstimateSize,
  serialize: _cleanTempoSerialize,
  deserialize: _cleanTempoDeserialize,
  deserializeProp: _cleanTempoDeserializeProp,
  idName: r'id',
  indexes: {
    r'exerciseKey': IndexSchema(
      id: 5360475711065971657,
      name: r'exerciseKey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'exerciseKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cleanTempoGetId,
  getLinks: _cleanTempoGetLinks,
  attach: _cleanTempoAttach,
  version: '3.1.0+1',
);

int _cleanTempoEstimateSize(
  CleanTempo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseKey.length * 3;
  return bytesCount;
}

void _cleanTempoSerialize(
  CleanTempo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.bpm);
  writer.writeString(offsets[1], object.exerciseKey);
}

CleanTempo _cleanTempoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CleanTempo();
  object.bpm = reader.readLong(offsets[0]);
  object.exerciseKey = reader.readString(offsets[1]);
  object.id = id;
  return object;
}

P _cleanTempoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cleanTempoGetId(CleanTempo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cleanTempoGetLinks(CleanTempo object) {
  return [];
}

void _cleanTempoAttach(IsarCollection<dynamic> col, Id id, CleanTempo object) {
  object.id = id;
}

extension CleanTempoByIndex on IsarCollection<CleanTempo> {
  Future<CleanTempo?> getByExerciseKey(String exerciseKey) {
    return getByIndex(r'exerciseKey', [exerciseKey]);
  }

  CleanTempo? getByExerciseKeySync(String exerciseKey) {
    return getByIndexSync(r'exerciseKey', [exerciseKey]);
  }

  Future<bool> deleteByExerciseKey(String exerciseKey) {
    return deleteByIndex(r'exerciseKey', [exerciseKey]);
  }

  bool deleteByExerciseKeySync(String exerciseKey) {
    return deleteByIndexSync(r'exerciseKey', [exerciseKey]);
  }

  Future<List<CleanTempo?>> getAllByExerciseKey(
      List<String> exerciseKeyValues) {
    final values = exerciseKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'exerciseKey', values);
  }

  List<CleanTempo?> getAllByExerciseKeySync(List<String> exerciseKeyValues) {
    final values = exerciseKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'exerciseKey', values);
  }

  Future<int> deleteAllByExerciseKey(List<String> exerciseKeyValues) {
    final values = exerciseKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'exerciseKey', values);
  }

  int deleteAllByExerciseKeySync(List<String> exerciseKeyValues) {
    final values = exerciseKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'exerciseKey', values);
  }

  Future<Id> putByExerciseKey(CleanTempo object) {
    return putByIndex(r'exerciseKey', object);
  }

  Id putByExerciseKeySync(CleanTempo object, {bool saveLinks = true}) {
    return putByIndexSync(r'exerciseKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByExerciseKey(List<CleanTempo> objects) {
    return putAllByIndex(r'exerciseKey', objects);
  }

  List<Id> putAllByExerciseKeySync(List<CleanTempo> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'exerciseKey', objects, saveLinks: saveLinks);
  }
}

extension CleanTempoQueryWhereSort
    on QueryBuilder<CleanTempo, CleanTempo, QWhere> {
  QueryBuilder<CleanTempo, CleanTempo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CleanTempoQueryWhere
    on QueryBuilder<CleanTempo, CleanTempo, QWhereClause> {
  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> idBetween(
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> exerciseKeyEqualTo(
      String exerciseKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exerciseKey',
        value: [exerciseKey],
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterWhereClause> exerciseKeyNotEqualTo(
      String exerciseKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseKey',
              lower: [],
              upper: [exerciseKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseKey',
              lower: [exerciseKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseKey',
              lower: [exerciseKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseKey',
              lower: [],
              upper: [exerciseKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CleanTempoQueryFilter
    on QueryBuilder<CleanTempo, CleanTempo, QFilterCondition> {
  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> bpmEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bpm',
        value: value,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> bpmGreaterThan(
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> bpmLessThan(
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> bpmBetween(
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition>
      exerciseKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CleanTempo, CleanTempo, QAfterFilterCondition> idBetween(
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
}

extension CleanTempoQueryObject
    on QueryBuilder<CleanTempo, CleanTempo, QFilterCondition> {}

extension CleanTempoQueryLinks
    on QueryBuilder<CleanTempo, CleanTempo, QFilterCondition> {}

extension CleanTempoQuerySortBy
    on QueryBuilder<CleanTempo, CleanTempo, QSortBy> {
  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> sortByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.asc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> sortByBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.desc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> sortByExerciseKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseKey', Sort.asc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> sortByExerciseKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseKey', Sort.desc);
    });
  }
}

extension CleanTempoQuerySortThenBy
    on QueryBuilder<CleanTempo, CleanTempo, QSortThenBy> {
  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> thenByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.asc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> thenByBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.desc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> thenByExerciseKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseKey', Sort.asc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> thenByExerciseKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseKey', Sort.desc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension CleanTempoQueryWhereDistinct
    on QueryBuilder<CleanTempo, CleanTempo, QDistinct> {
  QueryBuilder<CleanTempo, CleanTempo, QDistinct> distinctByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bpm');
    });
  }

  QueryBuilder<CleanTempo, CleanTempo, QDistinct> distinctByExerciseKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseKey', caseSensitive: caseSensitive);
    });
  }
}

extension CleanTempoQueryProperty
    on QueryBuilder<CleanTempo, CleanTempo, QQueryProperty> {
  QueryBuilder<CleanTempo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CleanTempo, int, QQueryOperations> bpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bpm');
    });
  }

  QueryBuilder<CleanTempo, String, QQueryOperations> exerciseKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseKey');
    });
  }
}
