import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

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
      setState(() => _error = 'Заполните все поля');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      setState(() => _error = 'Неверный email или пароль');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithTelegram() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.Surface,
        title: const Text('Вход через Telegram'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '1. Нажмите "Открыть бот"\n2. Бот пришлёт вам код\n3. Введите его ниже:',
              style: TextStyle(color: AppTheme.TextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Код из Telegram',
                prefixIcon: Icon(Icons.pin),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('https://t.me/yogaasana_bot?start=auth');
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Telegram не установлен. Установите Telegram и попробуйте снова.')),
                  );
                }
              }
            },
            child: const Text('Открыть бот'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) Navigator.pop(ctx, controller.text);
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.verifyTelegramCode(result);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
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
    return 'Неверный или просроченный код';
  }

  @override
  Widget build(BuildContext context) {
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
                          color: AppTheme.Accent,
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
                              color: AppTheme.Accent,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Войдите в свой аккаунт',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 40),
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
                      decoration: const InputDecoration(
                        hintText: 'Пароль',
                        prefixIcon: Icon(Icons.lock_outline),
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
                          : const Text('Войти'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Нет аккаунта? ',
                          style: TextStyle(color: AppTheme.TextSecondary),
                          children: [
                            TextSpan(
                              text: 'Зарегистрируйтесь',
                              style: TextStyle(
                                color: AppTheme.Accent,
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
                          child: Text('или', style: TextStyle(color: AppTheme.TextSecondary)),
                        ),
                        Expanded(child: Divider(color: AppTheme.CardBorder)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithTelegram,
                        icon: const Icon(Icons.telegram, color: Color(0xFF0088CC)),
                        label: const Text(
                          'Войти через Telegram',
                          style: TextStyle(color: Color(0xFF0088CC)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF0088CC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
