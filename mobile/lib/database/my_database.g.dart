// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_database.dart';

// ignore_for_file: type=lint
class $DistrictTableTable extends DistrictTable
    with TableInfo<$DistrictTableTable, District> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistrictTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _districtIdMeta =
      const VerificationMeta('districtId');
  @override
  late final GeneratedColumn<int> districtId = GeneratedColumn<int>(
      'district_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _districtNameMeta =
      const VerificationMeta('districtName');
  @override
  late final GeneratedColumn<String> districtName = GeneratedColumn<String>(
      'district_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _divisionIdFkMeta =
      const VerificationMeta('divisionIdFk');
  @override
  late final GeneratedColumn<int> divisionIdFk = GeneratedColumn<int>(
      'division_id_fk', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _provinceIdFkMeta =
      const VerificationMeta('provinceIdFk');
  @override
  late final GeneratedColumn<int> provinceIdFk = GeneratedColumn<int>(
      'province_id_fk', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [districtId, districtName, divisionIdFk, provinceIdFk];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'district_table';
  @override
  VerificationContext validateIntegrity(Insertable<District> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('district_id')) {
      context.handle(
          _districtIdMeta,
          districtId.isAcceptableOrUnknown(
              data['district_id']!, _districtIdMeta));
    } else if (isInserting) {
      context.missing(_districtIdMeta);
    }
    if (data.containsKey('district_name')) {
      context.handle(
          _districtNameMeta,
          districtName.isAcceptableOrUnknown(
              data['district_name']!, _districtNameMeta));
    } else if (isInserting) {
      context.missing(_districtNameMeta);
    }
    if (data.containsKey('division_id_fk')) {
      context.handle(
          _divisionIdFkMeta,
          divisionIdFk.isAcceptableOrUnknown(
              data['division_id_fk']!, _divisionIdFkMeta));
    } else if (isInserting) {
      context.missing(_divisionIdFkMeta);
    }
    if (data.containsKey('province_id_fk')) {
      context.handle(
          _provinceIdFkMeta,
          provinceIdFk.isAcceptableOrUnknown(
              data['province_id_fk']!, _provinceIdFkMeta));
    } else if (isInserting) {
      context.missing(_provinceIdFkMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  District map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return District.fromDb(
      districtId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}district_id'])!,
      districtName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}district_name'])!,
      divisionIdFk: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}division_id_fk'])!,
      provinceIdFk: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}province_id_fk'])!,
    );
  }

  @override
  $DistrictTableTable createAlias(String alias) {
    return $DistrictTableTable(attachedDatabase, alias);
  }
}

class DistrictTableCompanion extends UpdateCompanion<District> {
  final Value<int> districtId;
  final Value<String> districtName;
  final Value<int> divisionIdFk;
  final Value<int> provinceIdFk;
  final Value<int> rowid;
  const DistrictTableCompanion({
    this.districtId = const Value.absent(),
    this.districtName = const Value.absent(),
    this.divisionIdFk = const Value.absent(),
    this.provinceIdFk = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistrictTableCompanion.insert({
    required int districtId,
    required String districtName,
    required int divisionIdFk,
    required int provinceIdFk,
    this.rowid = const Value.absent(),
  })  : districtId = Value(districtId),
        districtName = Value(districtName),
        divisionIdFk = Value(divisionIdFk),
        provinceIdFk = Value(provinceIdFk);
  static Insertable<District> custom({
    Expression<int>? districtId,
    Expression<String>? districtName,
    Expression<int>? divisionIdFk,
    Expression<int>? provinceIdFk,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (districtId != null) 'district_id': districtId,
      if (districtName != null) 'district_name': districtName,
      if (divisionIdFk != null) 'division_id_fk': divisionIdFk,
      if (provinceIdFk != null) 'province_id_fk': provinceIdFk,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistrictTableCompanion copyWith(
      {Value<int>? districtId,
      Value<String>? districtName,
      Value<int>? divisionIdFk,
      Value<int>? provinceIdFk,
      Value<int>? rowid}) {
    return DistrictTableCompanion(
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      divisionIdFk: divisionIdFk ?? this.divisionIdFk,
      provinceIdFk: provinceIdFk ?? this.provinceIdFk,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (districtId.present) {
      map['district_id'] = Variable<int>(districtId.value);
    }
    if (districtName.present) {
      map['district_name'] = Variable<String>(districtName.value);
    }
    if (divisionIdFk.present) {
      map['division_id_fk'] = Variable<int>(divisionIdFk.value);
    }
    if (provinceIdFk.present) {
      map['province_id_fk'] = Variable<int>(provinceIdFk.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistrictTableCompanion(')
          ..write('districtId: $districtId, ')
          ..write('districtName: $districtName, ')
          ..write('divisionIdFk: $divisionIdFk, ')
          ..write('provinceIdFk: $provinceIdFk, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnsentTableTable extends UnsentTable
    with TableInfo<$UnsentTableTable, Unsent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnsentTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _unsentIdMeta =
      const VerificationMeta('unsentId');
  @override
  late final GeneratedColumn<int> unsentId = GeneratedColumn<int>(
      'unsent_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _unsentDateTimeMeta =
      const VerificationMeta('unsentDateTime');
  @override
  late final GeneratedColumn<int> unsentDateTime = GeneratedColumn<int>(
      'unsent_date_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unsentTypeMeta =
      const VerificationMeta('unsentType');
  @override
  late final GeneratedColumn<String> unsentType = GeneratedColumn<String>(
      'unsent_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unsentDataMeta =
      const VerificationMeta('unsentData');
  @override
  late final GeneratedColumn<String> unsentData = GeneratedColumn<String>(
      'unsent_data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unsentTitleMeta =
      const VerificationMeta('unsentTitle');
  @override
  late final GeneratedColumn<String> unsentTitle = GeneratedColumn<String>(
      'unsent_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [unsentId, unsentDateTime, unsentType, unsentData, unsentTitle];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unsent_table';
  @override
  VerificationContext validateIntegrity(Insertable<Unsent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('unsent_id')) {
      context.handle(_unsentIdMeta,
          unsentId.isAcceptableOrUnknown(data['unsent_id']!, _unsentIdMeta));
    }
    if (data.containsKey('unsent_date_time')) {
      context.handle(
          _unsentDateTimeMeta,
          unsentDateTime.isAcceptableOrUnknown(
              data['unsent_date_time']!, _unsentDateTimeMeta));
    } else if (isInserting) {
      context.missing(_unsentDateTimeMeta);
    }
    if (data.containsKey('unsent_type')) {
      context.handle(
          _unsentTypeMeta,
          unsentType.isAcceptableOrUnknown(
              data['unsent_type']!, _unsentTypeMeta));
    } else if (isInserting) {
      context.missing(_unsentTypeMeta);
    }
    if (data.containsKey('unsent_data')) {
      context.handle(
          _unsentDataMeta,
          unsentData.isAcceptableOrUnknown(
              data['unsent_data']!, _unsentDataMeta));
    } else if (isInserting) {
      context.missing(_unsentDataMeta);
    }
    if (data.containsKey('unsent_title')) {
      context.handle(
          _unsentTitleMeta,
          unsentTitle.isAcceptableOrUnknown(
              data['unsent_title']!, _unsentTitleMeta));
    } else if (isInserting) {
      context.missing(_unsentTitleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {unsentId};
  @override
  Unsent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unsent.fromDb(
      unsentTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unsent_title'])!,
      unsentData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unsent_data'])!,
      unsentDateTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unsent_date_time'])!,
      unsentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unsent_type'])!,
    );
  }

  @override
  $UnsentTableTable createAlias(String alias) {
    return $UnsentTableTable(attachedDatabase, alias);
  }
}

class UnsentTableCompanion extends UpdateCompanion<Unsent> {
  final Value<int> unsentId;
  final Value<int> unsentDateTime;
  final Value<String> unsentType;
  final Value<String> unsentData;
  final Value<String> unsentTitle;
  const UnsentTableCompanion({
    this.unsentId = const Value.absent(),
    this.unsentDateTime = const Value.absent(),
    this.unsentType = const Value.absent(),
    this.unsentData = const Value.absent(),
    this.unsentTitle = const Value.absent(),
  });
  UnsentTableCompanion.insert({
    this.unsentId = const Value.absent(),
    required int unsentDateTime,
    required String unsentType,
    required String unsentData,
    required String unsentTitle,
  })  : unsentDateTime = Value(unsentDateTime),
        unsentType = Value(unsentType),
        unsentData = Value(unsentData),
        unsentTitle = Value(unsentTitle);
  static Insertable<Unsent> custom({
    Expression<int>? unsentId,
    Expression<int>? unsentDateTime,
    Expression<String>? unsentType,
    Expression<String>? unsentData,
    Expression<String>? unsentTitle,
  }) {
    return RawValuesInsertable({
      if (unsentId != null) 'unsent_id': unsentId,
      if (unsentDateTime != null) 'unsent_date_time': unsentDateTime,
      if (unsentType != null) 'unsent_type': unsentType,
      if (unsentData != null) 'unsent_data': unsentData,
      if (unsentTitle != null) 'unsent_title': unsentTitle,
    });
  }

  UnsentTableCompanion copyWith(
      {Value<int>? unsentId,
      Value<int>? unsentDateTime,
      Value<String>? unsentType,
      Value<String>? unsentData,
      Value<String>? unsentTitle}) {
    return UnsentTableCompanion(
      unsentId: unsentId ?? this.unsentId,
      unsentDateTime: unsentDateTime ?? this.unsentDateTime,
      unsentType: unsentType ?? this.unsentType,
      unsentData: unsentData ?? this.unsentData,
      unsentTitle: unsentTitle ?? this.unsentTitle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (unsentId.present) {
      map['unsent_id'] = Variable<int>(unsentId.value);
    }
    if (unsentDateTime.present) {
      map['unsent_date_time'] = Variable<int>(unsentDateTime.value);
    }
    if (unsentType.present) {
      map['unsent_type'] = Variable<String>(unsentType.value);
    }
    if (unsentData.present) {
      map['unsent_data'] = Variable<String>(unsentData.value);
    }
    if (unsentTitle.present) {
      map['unsent_title'] = Variable<String>(unsentTitle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnsentTableCompanion(')
          ..write('unsentId: $unsentId, ')
          ..write('unsentDateTime: $unsentDateTime, ')
          ..write('unsentType: $unsentType, ')
          ..write('unsentData: $unsentData, ')
          ..write('unsentTitle: $unsentTitle')
          ..write(')'))
        .toString();
  }
}

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(QueryExecutor e) : super(e);
  late final $DistrictTableTable districtTable = $DistrictTableTable(this);
  late final $UnsentTableTable unsentTable = $UnsentTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [districtTable, unsentTable];
}
