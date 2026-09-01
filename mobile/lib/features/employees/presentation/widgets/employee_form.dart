import 'package:flutter/material.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/utils/date_formatter.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_dropdown.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/employees/domain/entities/employee.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_enums.dart';
import 'package:flutter_base/features/employees/domain/entities/employee_query.dart';

class EmployeeForm extends StatefulWidget {
  const EmployeeForm({
    super.key,
    required this.departments,
    required this.positions,
    required this.managers,
    required this.onSubmit,
    this.initial,
    this.submitting = false,
    this.fieldErrors = const <String, String>{},
    this.submitLabel = 'Save',
  });

  final Employee? initial;
  final List<Department> departments;
  final List<Position> positions;
  final List<Employee> managers;
  final bool submitting;
  final Map<String, String> fieldErrors;
  final String submitLabel;
  final Future<void> Function(EmployeeWrite write) onSubmit;

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _code;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _image;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyRelationship;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _userId;
  DateTime? _dob;
  DateTime? _joining;
  EmployeeGender? _gender;
  String? _departmentId;
  String? _positionId;
  String? _managerId;
  EmploymentType _employmentType = EmploymentType.fullTime;
  EmployeeStatus _status = EmployeeStatus.active;
  bool _loadedInitial = false;
  bool _localSubmitting = false;

  @override
  void initState() {
    super.initState();
    final Employee? initial = widget.initial;
    _firstName = TextEditingController(text: initial?.firstName ?? '');
    _lastName = TextEditingController(text: initial?.lastName ?? '');
    _code = TextEditingController(text: initial?.employeeCode ?? '');
    _phone = TextEditingController(text: initial?.phone ?? '');
    _address = TextEditingController(text: initial?.address ?? '');
    _image = TextEditingController(text: initial?.profileImage ?? '');
    _emergencyName = TextEditingController(
      text: initial?.emergencyContactName ?? '',
    );
    _emergencyRelationship = TextEditingController(
      text: initial?.emergencyContactRelationship ?? '',
    );
    _emergencyPhone = TextEditingController(
      text: initial?.emergencyContactPhone ?? '',
    );
    _userId = TextEditingController(
      text: initial?.user?.id.toString() ?? '',
    );
    _dob = initial?.dateOfBirth;
    _joining = initial?.joiningDate;
    _gender = initial?.gender == EmployeeGender.unknown ? null : initial?.gender;
    _departmentId = initial?.department?.id;
    _positionId = initial?.position?.id;
    _managerId = initial?.manager?.id;
    _employmentType = initial?.employmentType ?? EmploymentType.fullTime;
    _status = initial?.status ?? EmployeeStatus.active;
    _loadedInitial = initial != null;
  }

  @override
  void didUpdateWidget(covariant EmployeeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_loadedInitial && widget.initial != null) {
      _apply(widget.initial!);
      _loadedInitial = true;
    }
  }

  void _apply(Employee employee) {
    _firstName.text = employee.firstName;
    _lastName.text = employee.lastName;
    _code.text = employee.employeeCode;
    _phone.text = employee.phone;
    _address.text = employee.address;
    _image.text = employee.profileImage;
    _emergencyName.text = employee.emergencyContactName;
    _emergencyRelationship.text = employee.emergencyContactRelationship;
    _emergencyPhone.text = employee.emergencyContactPhone;
    _userId.text = employee.user?.id.toString() ?? '';
    setState(() {
      _dob = employee.dateOfBirth;
      _joining = employee.joiningDate;
      _gender = employee.gender == EmployeeGender.unknown
          ? null
          : employee.gender;
      _departmentId = employee.department?.id;
      _positionId = employee.position?.id;
      _managerId = employee.manager?.id;
      _employmentType = employee.employmentType;
      _status = employee.status;
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _code.dispose();
    _phone.dispose();
    _address.dispose();
    _image.dispose();
    _emergencyName.dispose();
    _emergencyRelationship.dispose();
    _emergencyPhone.dispose();
    _userId.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _phoneOptional(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length < 7) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  Future<void> _pickDate({required bool joining}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = joining
        ? (_joining ?? now)
        : (_dob ?? DateTime(now.year - 25));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (joining) {
        _joining = picked;
      } else {
        _dob = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (widget.submitting || _localSubmitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_joining == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joining date is required.')),
      );
      return;
    }
    final int? userId = int.tryParse(_userId.text.trim());
    setState(() => _localSubmitting = true);
    try {
      await widget.onSubmit(
        EmployeeWrite(
          employeeCode: _code.text.trim(),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          employmentType: _employmentType,
          status: _status,
          profileImage: _image.text.trim().startsWith('http')
              ? _image.text.trim()
              : '',
          gender: _gender,
          dateOfBirth: _dob,
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          emergencyContactName: _emergencyName.text.trim(),
          emergencyContactRelationship: _emergencyRelationship.text.trim(),
          emergencyContactPhone: _emergencyPhone.text.trim(),
          userId: userId,
          departmentId: _departmentId,
          positionId: _positionId,
          managerId: _managerId,
          joiningDate: _joining,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _localSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> errors = widget.fieldErrors;
    final bool submitting = widget.submitting || _localSubmitting;
    final List<Position> positions = widget.positions
        .where(
          (Position item) =>
              _departmentId == null || item.departmentId == _departmentId,
        )
        .toList();
    final TextTheme text = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Basic information', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _firstName,
            label: 'First name',
            errorText: errors['first_name'],
            validator: (String? value) => _required(value, 'First name'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _lastName,
            label: 'Last name',
            errorText: errors['last_name'],
            validator: (String? value) => _required(value, 'Last name'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _code,
            label: 'Employee code',
            errorText: errors['employee_code'],
            validator: (String? value) => _required(value, 'Employee code'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<EmployeeGender?>(
            key: ValueKey<String>('gender-$_gender'),
            label: 'Gender',
            value: _gender,
            items: <AppDropdownItem<EmployeeGender?>>[
              const AppDropdownItem<EmployeeGender?>(
                value: null,
                label: 'Not specified',
              ),
              ...EmployeeGender.values
                  .where(
                    (EmployeeGender item) => item != EmployeeGender.unknown,
                  )
                  .map(
                    (EmployeeGender item) => AppDropdownItem<EmployeeGender?>(
                      value: item,
                      label: item.label,
                    ),
                  ),
            ],
            onChanged: (EmployeeGender? value) {
              setState(() => _gender = value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date of birth'),
            subtitle: Text(
              _dob == null ? 'Optional' : AppDateFormatter.date(_dob!),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _pickDate(joining: false),
          ),
          AppTextField(
            controller: _phone,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            errorText: errors['phone'],
            validator: _phoneOptional,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _address,
            label: 'Address',
            maxLines: 3,
            errorText: errors['address'],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Employment', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<String?>(
            key: ValueKey<String>('dept-$_departmentId'),
            label: 'Department',
            value: _departmentId,
            items: <AppDropdownItem<String?>>[
              const AppDropdownItem<String?>(value: null, label: 'None'),
              ...widget.departments.map(
                (Department item) => AppDropdownItem<String?>(
                  value: item.id,
                  label: item.name,
                ),
              ),
            ],
            onChanged: (String? value) {
              setState(() {
                _departmentId = value;
                _positionId = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<String?>(
            key: ValueKey<String>('pos-$_positionId-$_departmentId'),
            label: 'Position',
            value: _positionId,
            items: <AppDropdownItem<String?>>[
              const AppDropdownItem<String?>(value: null, label: 'None'),
              ...positions.map(
                (Position item) => AppDropdownItem<String?>(
                  value: item.id,
                  label: item.title,
                ),
              ),
            ],
            onChanged: (String? value) => setState(() => _positionId = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<String?>(
            key: ValueKey<String>('mgr-$_managerId'),
            label: 'Manager',
            value: _managerId,
            items: <AppDropdownItem<String?>>[
              const AppDropdownItem<String?>(value: null, label: 'None'),
              ...widget.managers
                  .where((Employee item) => item.id != widget.initial?.id)
                  .map(
                    (Employee item) => AppDropdownItem<String?>(
                      value: item.id,
                      label: item.fullName,
                    ),
                  ),
            ],
            onChanged: (String? value) => setState(() => _managerId = value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Joining date'),
            subtitle: Text(
              _joining == null
                  ? 'Required'
                  : AppDateFormatter.date(_joining!),
            ),
            trailing: const Icon(Icons.event_outlined),
            onTap: () => _pickDate(joining: true),
          ),
          AppDropdown<EmploymentType>(
            key: ValueKey<String>('type-$_employmentType'),
            label: 'Employment type',
            value: _employmentType,
            items: EmploymentType.values
                .where((EmploymentType item) => item != EmploymentType.unknown)
                .map(
                  (EmploymentType item) => AppDropdownItem<EmploymentType>(
                    value: item,
                    label: item.label,
                  ),
                )
                .toList(),
            onChanged: (EmploymentType? value) {
              if (value != null) {
                setState(() => _employmentType = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdown<EmployeeStatus>(
            key: ValueKey<String>('status-$_status'),
            label: 'Status',
            value: _status,
            items: EmployeeStatus.values
                .where((EmployeeStatus item) => item != EmployeeStatus.unknown)
                .map(
                  (EmployeeStatus item) => AppDropdownItem<EmployeeStatus>(
                    value: item,
                    label: item.label,
                  ),
                )
                .toList(),
            onChanged: (EmployeeStatus? value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Emergency contact', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _emergencyName,
            label: 'Name',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _emergencyRelationship,
            label: 'Relationship',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _emergencyPhone,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            validator: _phoneOptional,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _userId,
            label: 'Linked user ID',
            hint: 'Optional numeric user id',
            keyboardType: TextInputType.number,
            errorText: errors['user'],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.submitLabel,
            isLoading: submitting,
            onPressed: submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
