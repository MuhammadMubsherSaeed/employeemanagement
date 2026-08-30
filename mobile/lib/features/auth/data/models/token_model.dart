class TokenModel {
  const TokenModel({required this.access, this.refresh});

  final String access;
  final String? refresh;

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    final Object? access = json['access'];
    final Object? refresh = json['refresh'];
    return TokenModel(
      access: access is String ? access : '',
      refresh: refresh is String && refresh.isNotEmpty ? refresh : null,
    );
  }
}
