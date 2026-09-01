import 'package:flutter_base/features/settings/domain/entities/company_settings.dart';
import 'package:flutter_base/features/settings/domain/services/settings_logo_picker.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerSettingsLogoPicker implements SettingsLogoPicker {
  ImagePickerSettingsLogoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<SettingsLogoFile?> pick() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 90,
    );
    if (file == null) {
      return null;
    }
    return SettingsLogoFile(
      path: file.path,
      name: file.name,
      size: await file.length(),
    );
  }
}
