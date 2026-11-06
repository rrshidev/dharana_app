import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/core/legal/legal_links.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:dharana_app/l10n/app_localizations.dart';
import 'package:dharana_app/shared/widgets/legal_footer.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  late final TapGestureRecognizer _consentLinkRecognizer;
  bool _consentAccepted = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _consentLinkRecognizer = TapGestureRecognizer()
      ..onTap = () {
        if (mounted) {
          LegalLinks.open(context, LegalLinks.consent(context));
        }
      };
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n!.fillAllFields);
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = l10n!.checkEmail);
      return;
    }
    if (name.length > 60) {
      setState(() => _error = l10n!.nameTooLong);
      return;
    }
    if (password.length < 8) {
      setState(() => _error = l10n!.passwordTooShort);
      return;
    }
    if (!_consentAccepted) {
      setState(() => _error = l10n!.consentRequired);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.register(email, password, name);
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      setState(() => _error = _mapRegisterError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapRegisterError(Object error) {
    String? detail;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        detail = data['detail'] as String;
      }
    }
    final l10n = AppLocalizations.of(context);
    switch (detail) {
      case 'PASSWORD_TOO_SHORT':
        return l10n!.passwordTooShort;
      case 'EMAIL_INVALID':
        return l10n!.checkEmail;
      case 'EMAIL_DISPOSABLE':
        return l10n!.disposableEmail;
      case 'EMAIL_NOT_DELIVERABLE':
        return l10n!.emailNotDeliverable;
      case 'Email already registered':
        return l10n!.emailAlreadyRegistered;
      case 'NAME_TOO_LONG':
        return l10n!.nameTooLong;
      default:
        return l10n!.registrationError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.createAccount,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.startYogaJourney,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l10n.name,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: l10n.passwordMinHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _consentAccepted,
                      onChanged: (value) =>
                          setState(() => _consentAccepted = value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: l10n.registerConsentPrefix),
                          TextSpan(
                            text: l10n.personalDataConsent,
                            style: TextStyle(
                              color: AppTheme.AccentInk,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: _consentLinkRecognizer,
                          ),
                          TextSpan(text: l10n.registerConsentSuffix),
                        ],
                      ),
                      style: TextStyle(
                        color: AppTheme.TextSecondary,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: AppTheme.Danger, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.Background,
                        ),
                      )
                    : Text(l10n.register),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: RichText(
                  text: TextSpan(
                    text: l10n.alreadyHaveAccount,
                    style: TextStyle(color: AppTheme.TextSecondary),
                    children: [
                      TextSpan(
                        text: l10n.signIn,
                        style: TextStyle(
                          color: AppTheme.AccentInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const LegalFooter(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _consentLinkRecognizer.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
