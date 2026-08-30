import 'package:flutter/material.dart';
import 'package:flutter_base/core/router/app_routes.dart';
import 'package:flutter_base/core/theme/app_spacing.dart';
import 'package:flutter_base/core/widgets/app_button.dart';
import 'package:flutter_base/core/widgets/app_text_field.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_error_mapper.dart';
import 'package:flutter_base/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_base/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.uid,
    this.token,
  });

  final String? uid;
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _uid = TextEditingController();
  final TextEditingController _token = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _uid.text = widget.uid ?? '';
    _token.text = widget.token ?? '';
  }

  @override
  void dispose() {
    _uid.dispose();
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() {
      _error = null;
      _success = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(resetPasswordUseCaseProvider)(
        uid: _uid.text.trim(),
        token: _token.text.trim(),
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) {
        return;
      }
      setState(() => _success = 'Password reset successful. You can sign in.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = AuthErrorMapper.message(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset password',
      subtitle: 'Enter the reset code from your email and choose a new password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _uid,
              label: 'Reset ID',
              enabled: !_submitting,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Reset ID is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _token,
              label: 'Reset token',
              enabled: !_submitting,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Reset token is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _password,
              label: 'New password',
              obscureText: _obscure,
              enabled: !_submitting,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: AuthValidators.strongPassword,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirm,
              label: 'Confirm password',
              obscureText: _obscure,
              enabled: !_submitting,
              validator: (String? value) =>
                  AuthValidators.confirmPassword(value, _password.text),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_success != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(_success!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Reset password',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Back to sign in',
              variant: AppButtonVariant.text,
              onPressed: _submitting
                  ? null
                  : () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
