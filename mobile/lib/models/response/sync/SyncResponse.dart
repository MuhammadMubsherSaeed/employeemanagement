class SyncResponse {
  SyncResponse({
    bool? status,
    String? message,
    dynamic data,
    Version? version,
    int? statusCode,
    int? code,
  }) {
    _status = status;
    _message = message;
    _data = data;
    _version = version;
    _statusCode = statusCode;
    _code = code;
  }

  SyncResponse.fromJson(dynamic json) {
    _status = json['status'];
    _message = json['message'];
    _data = json['data'];
    _version =
        json['version'] != null ? Version.fromJson(json['version']) : null;
    _statusCode = json['status_code'];
    _code = json['code'];
  }
  bool? _status;
  String? _message;
  dynamic _data;
  Version? _version;
  int? _statusCode;
  int? _code;

  bool? get status => _status;
  String? get message => _message;
  dynamic get data => _data;
  Version? get version => _version;
  int? get statusCode => _statusCode;
  int? get code => _code;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    map['message'] = _message;
    map['data'] = _data;
    if (_version != null) {
      map['version'] = _version?.toJson();
    }
    map['status_code'] = _statusCode;
    map['code'] = _code;
    return map;
  }
}

class Version {
  Version({
    String? serverVersionCode,
    int? isForceUpdate,
    String? dialogeMessage,
  }) {
    _serverVersionCode = serverVersionCode;
    _isForceUpdate = isForceUpdate;
    _dialogeMessage = dialogeMessage;
  }

  Version.fromJson(dynamic json) {
    _serverVersionCode = json['server_version_code'];
    _isForceUpdate = json['is_force_update'];
    _dialogeMessage = json['dialoge_message'];
  }
  String? _serverVersionCode;
  int? _isForceUpdate;
  String? _dialogeMessage;

  String? get serverVersionCode => _serverVersionCode;
  int? get isForceUpdate => _isForceUpdate;
  String? get dialogeMessage => _dialogeMessage;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['server_version_code'] = _serverVersionCode;
    map['is_force_update'] = _isForceUpdate;
    map['dialoge_message'] = _dialogeMessage;
    return map;
  }
}
