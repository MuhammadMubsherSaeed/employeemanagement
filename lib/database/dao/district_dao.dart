import 'package:drift/drift.dart';
import 'package:flutter_base/database/my_database.dart';
import 'package:flutter_base/database/tables/district_table.dart';
import 'package:flutter_base/models/response/sync/District.dart';
part 'district_dao.g.dart';

/*@dao
abstract class DistrictDao {
  // @Query('SELECT * FROM District')
  // Future<List<District>> findAllDistrict();
  //
  // @Query('SELECT * FROM District where districtId = :id')
  // Future<District?> findDistrictWithId(int id);
  //
  // @Query('SELECT * FROM District where divisionIdFk = :id')
  // Future<List<District>> findDistrictWithDivisionId(int id);
  //
  // @Query('SELECT * FROM District where provinceIdFk = :id')
  // Future<List<District>> findDistrictWithProvinceId(int id);
  //
  // @Insert(onConflict: OnConflictStrategy.replace)
  // Future<void> insertDistrict(District district);
  //
  // @Insert(onConflict: OnConflictStrategy.replace)
  // Future<List<int>> insertAllDistrict(List<District> districts);
  //
  // @Query("delete from District")
  // Future<void> deleteAll();
}*/

@DriftAccessor(tables: [DistrictTable])
class DistrictDao extends DatabaseAccessor<MyDatabase>
    with _$DistrictDaoMixin
    implements IDistrictTable {
  DistrictDao(MyDatabase db) : super(db);

  @override
  Future<void> deleteAll() {
    return (delete(districtTable)).go();
  }

  @override
  Future<int> insertData(District data) {
    return into(districtTable).insertOnConflictUpdate(
      DistrictTableCompanion.insert(
        districtId: data.districtId!,
        districtName: data.districtName ?? "",
        provinceIdFk: data.provinceIdFk!,
        divisionIdFk: data.divisionIdFk!,
      ),
    );
  }

  @override
  Future<District?> getData() {
    return (select(districtTable)..limit(1)).getSingleOrNull()
        as Future<District?>;
  }

  @override
  Future<List<District>> getAllData() async {
    return await (select(districtTable)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.districtName, mode: OrderingMode.asc)
          ]))
        .get() as List<District>;
  }

  @override
  Future<List<District>> getAllDataByProvinceId(int provinceId) async {
    return await (select(districtTable)
          ..where((tbl) => tbl.provinceIdFk.equals(provinceId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.districtName, mode: OrderingMode.asc)
          ]))
        .get() as List<District>;
  }

  @override
  Future<void> insertAllData(List<District> list) async {
    return await batch((batch) {
      /*batch.insertAll(
        districtTable,
        List<Insertable>.generate(list.length + 1, (index) {
          if (index == 0) {
            return DistrictTableCompanion.insert(
              districtId: -1,
              provinceId: -1,
              isActive: -1,
              districtCode: 0,
              districtName: 'Select District',
            );
          } else {
            return DistrictTableCompanion.insert(
              districtId: list[index - 1].districtId!,
              provinceId: list[index - 1].provinceId!,
              isActive: list[index - 1].isActive!,
              districtCode: list[index - 1].districtCode!,
              districtName: list[index - 1].districtName!,
            );
          }
        }),
      );*/
      batch.insertAll(districtTable, [
        DistrictTableCompanion.insert(
          districtId: -1,
          districtName: 'Please Select',
          provinceIdFk: -1,
          divisionIdFk: -1,
        ),
        for (District item in list)
          DistrictTableCompanion.insert(
            districtId: item.districtId!,
            districtName: item.districtName!,
            provinceIdFk: item.provinceIdFk!,
            divisionIdFk: item.divisionIdFk!,
          )
      ]);
    });
  }
}

abstract class IDistrictTable {
  Future<District?> getData();

  Future<List<District>?> getAllData();

  Future<List<District>?> getAllDataByProvinceId(int provinceId);

  Future<int> insertData(District user);

  Future<void> insertAllData(List<District> user);

  // Future <int> updateUser(LoginResponseTableCompanion user);
  //
  // Future <int> updateUserData(UserDetailsResponse usr) ;
  //
  // Future <void> deleteUserRecord(LoginResponseTableCompanion user);

  Future<void> deleteAll();
}
