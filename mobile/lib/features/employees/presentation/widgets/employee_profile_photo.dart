import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_base/core/extensions/context_extensions.dart';
import 'package:flutter_base/core/widgets/app_avatar.dart';
import 'package:flutter_base/features/documents/domain/document_access.dart';
import 'package:flutter_base/features/documents/domain/document_validation.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_error_mapper.dart';
import 'package:flutter_base/features/employees/presentation/providers/employee_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeProfilePhoto extends ConsumerWidget {
  const EmployeeProfilePhoto({
    super.key,
    required this.employee,
    required this.access,
    this.size = 64,
  });

  final Employee employee;
  final DocumentAccess access;
  final double size;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final XFile? cameraOrGallery = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  final XFile? file = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 2048,
                    imageQuality: 90,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () async {
                  final XFile? file = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    maxWidth: 2048,
                    imageQuality: 90,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
    if (cameraOrGallery == null) {
      return;
    }
    final int sizeBytes = await cameraOrGallery.length();
    final String? error = validateProfileImageFile(
      name: cameraOrGallery.name,
      size: sizeBytes,
    );
    if (error != null) {
      if (context.mounted) {
        context.showSnack(error);
      }
      return;
    }
    try {
      await ref.read(uploadProfileImageUseCaseProvider)(
        id: employee.id,
        path: cameraOrGallery.path,
        filename: cameraOrGallery.name,
      );
      ref.invalidate(employeeProfileImageProvider(employee.id));
      ref.invalidate(employeeDetailProvider(employee.id));
      if (context.mounted) {
        context.showSnack('Profile photo updated.');
      }
    } catch (error) {
      if (context.mounted) {
        context.showSnack(EmployeeErrorMapper.message(error));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Uint8List?> image =
        ref.watch(employeeProfileImageProvider(employee.id));
    final ImageProvider? memory = image.maybeWhen(
      data: (Uint8List? bytes) =>
          bytes == null || bytes.isEmpty ? null : MemoryImage(bytes),
      orElse: () => null,
    );
    final Widget avatar = AppAvatar(
      name: employee.fullName,
      image: memory,
      imageUrl: memory == null && employee.profileImage.isNotEmpty
          ? employee.profileImage
          : null,
      size: size,
    );
    if (!access.canManageProfileImage) {
      return avatar;
    }
    return GestureDetector(
      onTap: () => _pick(context, ref),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          avatar,
          CircleAvatar(
            radius: 12,
            child: Icon(
              Icons.camera_alt_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
