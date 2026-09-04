import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_bottom_sheet.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/devices/domain/entities/device_enums.dart';
import 'package:flutter_base/features/devices/domain/entities/device_query.dart';

const List<String> kSuggestedDeviceTypes = <String>[
  'Laptop',
  'Desktop',
  'Mobile',
  'Tablet',
  'Monitor',
  'Printer',
  'Other',
];

Future<DeviceQuery?> showDeviceFilterSheet({
  required BuildContext context,
  required DeviceQuery current,
}) {
  return AppBottomSheet.show<DeviceQuery>(
    context: context,
    builder: (BuildContext context) {
      return DeviceFilterSheet(current: current);
    },
  );
}

class DeviceFilterSheet extends StatefulWidget {
  const DeviceFilterSheet({
    super.key,
    required this.current,
  });

  final DeviceQuery current;

  @override
  State<DeviceFilterSheet> createState() => _DeviceFilterSheetState();
}

class _DeviceFilterSheetState extends State<DeviceFilterSheet> {
  late DeviceQuery _draft;
  late final TextEditingController _type;
  late final TextEditingController _manufacturer;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
    _type = TextEditingController(text: widget.current.type ?? '');
    _manufacturer =
        TextEditingController(text: widget.current.manufacturer ?? '');
  }

  @override
  void dispose() {
    _type.dispose();
    _manufacturer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<DeviceStatus?>(
              label: 'Status',
              hint: 'Any status',
              value: _draft.status,
              items: <AppDropdownItem<DeviceStatus?>>[
                const AppDropdownItem<DeviceStatus?>(
                  value: null,
                  label: 'Any status',
                ),
                ...DeviceStatus.values
                    .where((DeviceStatus item) => item != DeviceStatus.unknown)
                    .map(
                      (DeviceStatus item) => AppDropdownItem<DeviceStatus?>(
                        value: item,
                        label: item.label,
                      ),
                    ),
              ],
              onChanged: (DeviceStatus? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    status: value,
                    clearStatus: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _type,
              label: 'Device type',
              hint: 'Laptop, Mobile…',
              onChanged: (String value) {
                setState(() {
                  _draft = _draft.copyWith(
                    type: value,
                    clearType: value.trim().isEmpty,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: kSuggestedDeviceTypes
                  .map(
                    (String type) => ActionChip(
                      label: Text(type),
                      onPressed: () {
                        _type.text = type;
                        setState(() {
                          _draft = _draft.copyWith(type: type);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _manufacturer,
              label: 'Manufacturer',
              onChanged: (String value) {
                setState(() {
                  _draft = _draft.copyWith(
                    manufacturer: value,
                    clearManufacturer: value.trim().isEmpty,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<bool?>(
              label: 'Assignment',
              hint: 'All devices',
              value: _draft.assigned,
              items: const <AppDropdownItem<bool?>>[
                AppDropdownItem<bool?>(value: null, label: 'All devices'),
                AppDropdownItem<bool?>(value: true, label: 'Assigned'),
                AppDropdownItem<bool?>(value: false, label: 'Unassigned'),
              ],
              onChanged: (bool? value) {
                setState(() {
                  _draft = _draft.copyWith(
                    assigned: value,
                    clearAssigned: value == null,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Clear',
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      _type.clear();
                      _manufacturer.clear();
                      Navigator.of(context).pop(_draft.clearedFilters());
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Apply',
                    onPressed: () => Navigator.of(context).pop(_draft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
