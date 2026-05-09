// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPracticeSessionCollection on Isar {
  IsarCollection<PracticeSession> get practiceSessions => this.collection();
}

const PracticeSessionSchema = CollectionSchema(
  name: r'PracticeSession',
  id: -7821173925238240962,
  properties: {
    r'achievedBpm': PropertySchema(
      id: 0,
      name: r'achievedBpm',
      type: IsarType.long,
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'durationSeconds': PropertySchema(
      id: 2,
      name: r'durationSeconds',
      type: IsarType.long,
    ),
    r'rating': PropertySchema(
      id: 3,
      name: r'rating',
      type: IsarType.long,
    ),
    r'rudimentId': PropertySchema(
      id: 4,
      name: r'rudimentId',
      type: IsarType.string,
    )
  },
  estimateSize: _practiceSessionEstimateSize,
  serialize: _practiceSessionSerialize,
  deserialize: _practiceSessionDeserialize,
  deserializeProp: _practiceSessionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _practiceSessionGetId,
  getLinks: _practiceSessionGetLinks,
  attach: _practiceSessionAttach,
  version: '3.1.0+1',
);

int _practiceSessionEstimateSize(
  PracticeSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.rudimentId.length * 3;
  return bytesCount;
}

void _practiceSessionSerialize(
  PracticeSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.achievedBpm);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeLong(offsets[2], object.durationSeconds);
  writer.writeLong(offsets[3], object.rating);
  writer.writeString(offsets[4], object.rudimentId);
}

PracticeSession _practiceSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PracticeSession();
  object.achievedBpm = reader.readLong(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.durationSeconds = reader.readLong(offsets[2]);
  object.id = id;
  object.rating = reader.readLong(offsets[3]);
  object.rudimentId = reader.readString(offsets[4]);
  return object;
}

P _practiceSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _practiceSessionGetId(PracticeSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _practiceSessionGetLinks(PracticeSession object) {
  return [];
}

void _practiceSessionAttach(
    IsarCollection<dynamic> col, Id id, PracticeSession object) {
  object.id = id;
}

extension PracticeSessionQueryWhereSort
    on QueryBuilder<PracticeSession, PracticeSession, QWhere> {
  QueryBuilder<PracticeSession, PracticeSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PracticeSessionQueryWhere
    on QueryBuilder<PracticeSession, PracticeSession, QWhereClause> {
  QueryBuilder<PracticeSession, PracticeSession, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterWhereClause>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterWhereClause> idBetween(
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
}

extension PracticeSessionQueryFilter
    on QueryBuilder<PracticeSession, PracticeSession, QFilterCondition> {
  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      achievedBpmEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'achievedBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      achievedBpmGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'achievedBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      achievedBpmLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'achievedBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      achievedBpmBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'achievedBpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      durationSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      ratingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rating',
        value: value,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      ratingGreaterThan(
    int value, {
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      ratingLessThan(
    int value, {
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      ratingBetween(
    int lower,
    int upper, {
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

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rudimentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rudimentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rudimentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rudimentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'rudimentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'rudimentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'rudimentId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'rudimentId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rudimentId',
        value: '',
      ));
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterFilterCondition>
      rudimentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'rudimentId',
        value: '',
      ));
    });
  }
}

extension PracticeSessionQueryObject
    on QueryBuilder<PracticeSession, PracticeSession, QFilterCondition> {}

extension PracticeSessionQueryLinks
    on QueryBuilder<PracticeSession, PracticeSession, QFilterCondition> {}

extension PracticeSessionQuerySortBy
    on QueryBuilder<PracticeSession, PracticeSession, QSortBy> {
  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByAchievedBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedBpm', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByAchievedBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedBpm', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy> sortByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByRudimentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rudimentId', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      sortByRudimentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rudimentId', Sort.desc);
    });
  }
}

extension PracticeSessionQuerySortThenBy
    on QueryBuilder<PracticeSession, PracticeSession, QSortThenBy> {
  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByAchievedBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedBpm', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByAchievedBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'achievedBpm', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationSeconds', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy> thenByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rating', Sort.desc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByRudimentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rudimentId', Sort.asc);
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QAfterSortBy>
      thenByRudimentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rudimentId', Sort.desc);
    });
  }
}

extension PracticeSessionQueryWhereDistinct
    on QueryBuilder<PracticeSession, PracticeSession, QDistinct> {
  QueryBuilder<PracticeSession, PracticeSession, QDistinct>
      distinctByAchievedBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'achievedBpm');
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QDistinct>
      distinctByDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationSeconds');
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QDistinct> distinctByRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rating');
    });
  }

  QueryBuilder<PracticeSession, PracticeSession, QDistinct>
      distinctByRudimentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rudimentId', caseSensitive: caseSensitive);
    });
  }
}

extension PracticeSessionQueryProperty
    on QueryBuilder<PracticeSession, PracticeSession, QQueryProperty> {
  QueryBuilder<PracticeSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PracticeSession, int, QQueryOperations> achievedBpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'achievedBpm');
    });
  }

  QueryBuilder<PracticeSession, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<PracticeSession, int, QQueryOperations>
      durationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationSeconds');
    });
  }

  QueryBuilder<PracticeSession, int, QQueryOperations> ratingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rating');
    });
  }

  QueryBuilder<PracticeSession, String, QQueryOperations> rudimentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rudimentId');
    });
  }
}
