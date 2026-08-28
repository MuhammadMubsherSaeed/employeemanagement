
import 'package:drift/drift.dart';
import 'package:flutter_base/models/response/sync/District.dart';

@UseRowClass(District, constructor: "fromDb")
class DistrictTable extends Table {
  IntColumn get districtId => integer().unique()();
  TextColumn get districtName => text()();
  IntColumn get divisionIdFk => integer()();
  IntColumn get provinceIdFk => integer()();
}
