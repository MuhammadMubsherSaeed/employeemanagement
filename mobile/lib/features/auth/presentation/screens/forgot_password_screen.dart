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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _success;

  static const String _genericSuccess =
      'If an account exists for this email, password reset instructions have been sent.';

  @override
  void dispose() {
    _email.dispose();
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
      await ref.read(forgotPasswordUseCaseProvider)(
        email: _email.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _success = _genericSuccess);
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
      title: 'Forgot password',
      subtitle: 'We will email reset instructions if an account exists.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              enabled: !_submitting,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: AuthValidators.email,
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
              label: 'Send instructions',
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
