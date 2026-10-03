import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

/// Контурные (без заливки) знаки соцсетей — требование партнёра: тонкие линии,
/// цвет контура = цвет текста интерфейса, hover/press — мягкий градиент.
///
/// Чтобы добавить соцсеть (VK, MAX и т.д.): дописать значение в [SocialNetwork]
/// и путь в [_socialPaths] — кнопки, подложки и hover берут стиль отсюда.
enum SocialNetwork { google, telegram }

class SocialIcon extends StatelessWidget {
  const SocialIcon({
    super.key,
    required this.network,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.5,
  });

  final SocialNetwork network;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final effective = color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        AppTheme.TextSecondary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SocialIconPainter(
          paths: _socialPaths[network]!,
          color: effective,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _SocialIconPainter extends CustomPainter {
  const _SocialIconPainter({
    required this.paths,
    required this.color,
    required this.strokeWidth,
  });

  /// Пути в системе координат 24x24 — те же, что на сайте
  /// (dharana_web_app/components/brand/social-icon.tsx).
  final List<Path> paths;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      // Масштабируем холст, поэтому компенсируем толщину, чтобы она осталась
      // в логических пикселях (как stroke-width в CSS).
      ..strokeWidth = strokeWidth / scale;
    canvas
      ..save()
      ..scale(scale);
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SocialIconPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      !identical(old.paths, paths);
}

/// «G»: окружность с разрывом справа и горизонтальной перекладиной внутрь.
Path _googlePath() {
  return Path()
    ..arcTo(
      Rect.fromCircle(center: const Offset(11.98, 12.2), radius: 6.6),
      -0.729,
      -(2 * math.pi - 1.458),
      true,
    )
    ..lineTo(12.3, 16.6);
}

/// Телеграм: контур «бумажного самолётика» (скруглённые углы — дуги радиуса 1).
Path _telegramPath() {
  const corner = Radius.circular(1);
  return Path()
    ..moveTo(21.5, 3.5)
    ..lineTo(2.8, 10.7)
    ..arcToPoint(const Offset(2.8, 12.5), radius: corner, clockwise: false)
    ..lineTo(7.5, 14.1)
    ..lineTo(9.3, 19.5)
    ..arcToPoint(const Offset(11.0, 19.6), radius: corner, clockwise: false)
    ..lineTo(13.4, 17.0)
    ..lineTo(18.0, 20.4)
    ..arcToPoint(const Offset(19.5, 19.7), radius: corner, clockwise: false)
    ..lineTo(22.9, 4.7)
    ..arcToPoint(const Offset(22.0, 3.5), radius: corner, clockwise: false)
    ..close();
}

/// Линия сгиба внутри знака телеграма.
Path _telegramFoldPath() {
  return Path()
    ..moveTo(9.5, 13.5)
    ..lineTo(19.0, 7.5)
    ..lineTo(12.3, 15.2);
}

final Map<SocialNetwork, List<Path>> _socialPaths = {
  SocialNetwork.google: [_googlePath()],
  SocialNetwork.telegram: [_telegramPath(), _telegramFoldPath()],
};