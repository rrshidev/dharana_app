import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';
import 'package:dharana_app/shared/widgets/social_icon.dart';

/// Тон [SocialButtonTone.accent] — для CTA («Бот в Telegram»).
enum SocialButtonTone { neutral, accent }

/// Кнопка входа через соцсеть: контурная иконка в подложке-квадрате (радиус 12),
/// контур и текст — цветами интерфейса, hover/press — мягкий градиент.
/// Партнёрский стандарт, общий для приложения и сайта.
class SocialButton extends StatefulWidget {
  const SocialButton({
    super.key,
    required this.network,
    required this.label,
    this.onPressed,
    this.tone = SocialButtonTone.neutral,
  });

  final SocialNetwork network;
  final String label;
  final VoidCallback? onPressed;
  final SocialButtonTone tone;

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.tone == SocialButtonTone.accent;
    final borderColor = accent
        ? AppTheme.Accent.withValues(alpha: 0.45)
        : AppTheme.CardBorder;
    final fillColor =
        accent ? AppTheme.Accent.withValues(alpha: 0.10) : Colors.transparent;
    final disabled = widget.onPressed == null;

    return OutlinedButton(
      onPressed: widget.onPressed,
      statesController: _states,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        minimumSize: const Size.fromHeight(52),
        backgroundColor: fillColor,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ).copyWith(
        // Контур/текст приглушённые в покое, ярче при наведении/нажатии.
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          final brighter = states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused);
          final base =
              brighter ? AppTheme.TextPrimary : AppTheme.TextSecondary;
          return disabled ? base.withValues(alpha: 0.45) : base;
        }),
      ),
      child: ListenableBuilder(
        listenable: _states,
        builder: (context, _) {
          final active = _states.value.contains(WidgetState.hovered) ||
              _states.value.contains(WidgetState.pressed);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialBadge(network: widget.network, active: active),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Подложка под знак: квадрат 32px с тем же радиусом 12, что и кнопка,
/// в тон фону; при hover/press проявляется мягкий градиент accent → sage.
class SocialBadge extends StatelessWidget {
  const SocialBadge({
    super.key,
    required this.network,
    this.active = false,
    this.size = 32,
  });

  final SocialNetwork network;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.SurfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.CardBorder),
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.Accent.withValues(alpha: 0.30),
                  AppTheme.AccentGreen.withValues(alpha: 0.30),
                ],
              )
            : null,
      ),
      child: Center(
        child: SocialIcon(
          network: network,
          size: 20,
          color: active ? AppTheme.TextPrimary : AppTheme.TextSecondary,
        ),
      ),
    );
  }
}