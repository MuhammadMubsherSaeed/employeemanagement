import 'package:drift/drift.dart';
import 'package:flutter_base/models/response/Unsent.dart';

@UseRowClass(Unsent, constructor: "fromDb")
class UnsentTable extends Table {
  IntColumn get unsentId => integer().autoIncrement()();
  IntColumn get unsentDateTime => integer()();
  TextColumn get unsentType => text()();
  TextColumn get unsentData => text()();
  TextColumn get unsentTitle => text()();
}
