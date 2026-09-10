import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/features/auth/services/auth_service.dart';

class ResetPasswordFormScreen extends StatefulWidget {
  const ResetPasswordFormScreen({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordFormScreen> createState() => _ResetPasswordFormScreenState();
}

class _ResetPasswordFormScreenState extends State<ResetPasswordFormScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _done = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    setState(() => _error = null);

    if (password.length < 8) {
      setState(() => _error = 'Пароль должен быть не короче 8 символов');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(widget.token, password);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = _mapError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(Object error) {
    String? detail;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        detail = data['detail'] as String;
      }
    }
    switch (detail) {
      case 'INVALID_RESET_TOKEN':
        return 'Ссылка недействительна или устарела. Запросите новую';
      case 'PASSWORD_TOO_SHORT':
        return 'Пароль должен быть не короче 8 символов';
      case 'PASSWORD_TOO_LONG':
        return 'Пароль слишком длинный (максимум 128 символов)';
      default:
        return 'Не удалось изменить пароль. Попробуйте позже';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            children: _done
                ? [
                    const SizedBox(height: 32),
                    Icon(
                      Icons.check_circle_outline,
                      size: 56,
                      color: AppTheme.Accent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пароль изменён',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Теперь можно войти с новым паролем.',
                      style: TextStyle(
                        color: AppTheme.TextSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Войти'),
                    ),
                  ]
                : [
                    Text(
                      'Новый пароль',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Придумайте новый пароль для входа. Ссылка действует 30 минут.',
                      style: TextStyle(
                        color: AppTheme.TextSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Новый пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Повторите пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: AppTheme.Danger,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.Background,
                              ),
                            )
                          : const Text('Сохранить пароль'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}