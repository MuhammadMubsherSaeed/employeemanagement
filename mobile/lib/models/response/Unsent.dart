class Unsent {
  Unsent({
    String? unsentTitle,
    String? unsentData,
    int? unsentDateTime,
    String? unsentType,
  }) {
    _unsentTitle = unsentTitle;
    _unsentData = unsentData;
    _unsentDateTime = unsentDateTime;
    _unsentType = unsentType;
  }

  Unsent.fromDb({
    String? unsentTitle,
    String? unsentData,
    int? unsentDateTime,
    String? unsentType,
  }) {
    _unsentTitle = unsentTitle;
    _unsentData = unsentData;
    _unsentDateTime = unsentDateTime;
    _unsentType = unsentType;
  }

  Unsent.fromJson(dynamic json) {
    _unsentTitle = json['unsentTitle'];
    _unsentData = json['unsentData'];
    _unsentDateTime = json['unsentDateTime'];
    _unsentType = json['unsentType'];
  }
  String? _unsentTitle;
  String? _unsentData;
  int? _unsentDateTime;
  String? _unsentType;

  String? get unsentTitle => _unsentTitle;
  String? get unsentData => _unsentData;
  int? get unsentDateTime => _unsentDateTime;
  String? get unsentType => _unsentType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['unsentTitle'] = _unsentTitle;
    map['unsentData'] = _unsentData;
    map['unsentDateTime'] = _unsentDateTime;
    map['unsentType'] = _unsentType;
    return map;
  }
}
