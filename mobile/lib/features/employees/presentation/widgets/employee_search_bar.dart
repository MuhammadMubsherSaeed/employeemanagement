import 'package:flutter/material.dart';
import 'package:flutter_base/core/widgets/app_search_field.dart';

class EmployeeSearchBar extends StatelessWidget {
  const EmployeeSearchBar({
    super.key,
    required this.onChanged,
    this.initialValue = '',
    this.hintText = 'Search employees',
  });

  final ValueChanged<String> onChanged;
  final String initialValue;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      onChanged: onChanged,
      initialValue: initialValue,
      hintText: hintText,
    );
  }
}
