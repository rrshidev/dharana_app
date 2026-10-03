import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/l10n/app_localizations.dart';
import 'package:dharana_app/shared/widgets/social_button.dart';
import 'package:dharana_app/shared/widgets/social_icon.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.fillAllFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      setState(
          () => _error = AppLocalizations.of(context)!.invalidEmailOrPassword);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = await _authService.loginWithGoogle();
      if (auth == null) return;
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.googleLoginFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithTelegram() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          backgroundColor: AppTheme.Surface,
          title: Text(l10n.loginViaTelegram),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.tgGuide,
                style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.telegramCodeHint,
                  prefixIcon: const Icon(Icons.pin),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final uri =
                    Uri.parse('https://t.me/yogaasana_bot?start=auth');
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text(l10n.telegramNotInstalledLong)),
                    );
                  }
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SocialIcon(
                    network: SocialNetwork.telegram,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.openBot),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(ctx, controller.text);
                }
              },
              child: Text(l10n.login),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.verifyTelegramCode(result);
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      setState(() => _error = _extractError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractError(Object? e) {
    if (e is DioException) {
      final detail = e.response?.data;
      if (detail is Map && detail['detail'] != null) {
        return detail['detail'].toString();
      }
    }
    return AppLocalizations.of(context)!.invalidTgCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.AccentInk,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.self_improvement,
                          size: 48,
                          color: AppTheme.Background,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Dharana',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.AccentInk,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        l10n.loginToAccount,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.push('/reset_password');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: TextStyle(
                            color: AppTheme.AccentInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.Background,
                              ),
                            )
                          : Text(l10n.login),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: l10n.noAccount,
                          style: TextStyle(color: AppTheme.TextSecondary),
                          children: [
                            TextSpan(
                              text: l10n.registerCta,
                              style: TextStyle(
                                color: AppTheme.AccentInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.CardBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(l10n.or, style: TextStyle(color: AppTheme.TextSecondary)),
                        ),
                        Expanded(child: Divider(color: AppTheme.CardBorder)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SocialButton(
                      network: SocialNetwork.google,
                      label: l10n.loginWithGoogle,
                      onPressed: _isLoading ? null : _loginWithGoogle,
                    ),
                    const SizedBox(height: 12),
                    SocialButton(
                      network: SocialNetwork.telegram,
                      label: l10n.loginWithTelegram,
                      onPressed: _isLoading ? null : _loginWithTelegram,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
