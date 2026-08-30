enum EmploymentType {
  fullTime('FULL_TIME', 'Full time'),
  partTime('PART_TIME', 'Part time'),
  contract('CONTRACT', 'Contract'),
  intern('INTERN', 'Intern'),
  temporary('TEMPORARY', 'Temporary'),
  unknown('UNKNOWN', 'Unknown');

  const EmploymentType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EmploymentType fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final EmploymentType item in EmploymentType.values) {
      if (item != EmploymentType.unknown && item.apiValue == value) {
        return item;
      }
    }
    return EmploymentType.unknown;
  }
}

enum EmployeeStatus {
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive'),
  onLeave('ON_LEAVE', 'On leave'),
  terminated('TERMINATED', 'Terminated'),
  unknown('UNKNOWN', 'Unknown');

  const EmployeeStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EmployeeStatus fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final EmployeeStatus item in EmployeeStatus.values) {
      if (item != EmployeeStatus.unknown && item.apiValue == value) {
        return item;
      }
    }
    return EmployeeStatus.unknown;
  }
}

enum OrgStatus {
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive'),
  unknown('UNKNOWN', 'Unknown');

  const OrgStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OrgStatus fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    for (final OrgStatus item in OrgStatus.values) {
      if (item != OrgStatus.unknown && item.apiValue == value) {
        return item;
      }
    }
    return OrgStatus.unknown;
  }
}

typedef DepartmentStatus = OrgStatus;
typedef PositionStatus = OrgStatus;

enum EmployeeGender {
  male('MALE', 'Male'),
  female('FEMALE', 'Female'),
  other('OTHER', 'Other'),
  preferNotToSay('PREFER_NOT_TO_SAY', 'Prefer not to say'),
  unknown('UNKNOWN', 'Unknown');

  const EmployeeGender(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static EmployeeGender fromApi(String? raw) {
    final String value = (raw ?? '').trim().toUpperCase();
    if (value.isEmpty) {
      return EmployeeGender.unknown;
    }
    for (final EmployeeGender item in EmployeeGender.values) {
      if (item != EmployeeGender.unknown && item.apiValue == value) {
        return item;
      }
    }
    return EmployeeGender.unknown;
  }
}
