class District {
  District({
    int? districtId,
    String? districtName,
    int? divisionIdFk,
    int? provinceIdFk,
  }) {
    _districtId = districtId;
    _districtName = districtName;
    _divisionIdFk = divisionIdFk;
    _provinceIdFk = provinceIdFk;
  }

  District.fromDb({
    int? districtId,
    String? districtName,
    int? divisionIdFk,
    int? provinceIdFk,
  }) {
    _districtId = districtId;
    _districtName = districtName;
    _divisionIdFk = divisionIdFk;
    _provinceIdFk = provinceIdFk;
  }

  District.fromJson(dynamic json) {
    _districtId = json['district_id'];
    _districtName = json['district_name'];
    _divisionIdFk = json['division_idFk'];
    _provinceIdFk = json['province_idFk'];
  }
  int? _districtId;
  String? _districtName;
  int? _divisionIdFk;
  int? _provinceIdFk;

  int? get districtId => _districtId;
  String? get districtName => _districtName;
  int? get divisionIdFk => _divisionIdFk;
  int? get provinceIdFk => _provinceIdFk;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['district_id'] = _districtId;
    map['district_name'] = _districtName;
    map['division_idFk'] = _divisionIdFk;
    map['province_idFk'] = _provinceIdFk;
    return map;
  }
}
