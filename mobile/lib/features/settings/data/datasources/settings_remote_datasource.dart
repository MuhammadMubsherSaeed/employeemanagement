import 'package:flutter_base/core/errors/app_exception.dart';
import 'package:flutter_base/core/network/api_client.dart';
import 'package:flutter_base/core/network/models/api_envelope.dart';
import 'package:flutter_base/features/settings/data/settings_endpoints.dart';
import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:dio/dio.dart';

abstract class SettingsRemoteDataSource {
  Future<CompanySettings> getSettings();

  Future<CompanySettings> updateSettings(CompanySettingsPatch patch);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<CompanySettings> getSettings() async {
    final response = await _client.get<dynamic>(SettingsEndpoints.settings);
    return CompanySettings.fromJson(_data(_envelope(response.data)));
  }

  @override
  Future<CompanySettings> updateSettings(CompanySettingsPatch patch) async {
    final Object payload;
    if (patch.hasLogo) {
      payload = FormData.fromMap(<String, dynamic>{
        ...patch.toJson(),
        'logo': await MultipartFile.fromFile(
          patch.logo!.path,
          filename: patch.logo!.name,
        ),
      });
    } else {
      payload = patch.toJson();
    }
    final response = await _client.patch<dynamic>(
      SettingsEndpoints.settings,
      data: payload,
    );
    return CompanySettings.fromJson(_data(_envelope(response.data)));
  }

  Map<String, dynamic> _data(ApiEnvelope envelope) {
    try {
      return envelope.requireDataMap();
    } on FormatException {
      throw const UnknownException();
    }
  }

  ApiEnvelope _envelope(dynamic data) {
    try {
      final ApiEnvelope envelope = ApiEnvelope.parse(data);
      if (!envelope.success && envelope.data == null) {
        throw UnknownException(envelope.message ?? 'Request failed.');
      }
      return envelope;
    } on FormatException {
      throw const UnknownException();
    }
  }
}
