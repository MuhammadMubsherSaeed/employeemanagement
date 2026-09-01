import 'package:equatable/equatable.dart';

class SettingsUpdateState extends Equatable {
  const SettingsUpdateState({
    this.isSubmitting = false,
    this.fieldErrors = const <String, String>{},
    this.error,
  });

  final bool isSubmitting;
  final Map<String, String> fieldErrors;
  final String? error;

  SettingsUpdateState copyWith({
    bool? isSubmitting,
    Map<String, String>? fieldErrors,
    String? error,
    bool clearError = false,
  }) {
    return SettingsUpdateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[isSubmitting, fieldErrors, error];
}
