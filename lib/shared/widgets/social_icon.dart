import 'package:flutter/material.dart';
import 'package:dharana_app/app/theme.dart';

/// Контурные (без заливки) знаки соцсетей — требование партнёра: тонкие линии,
/// цвет контура = цвет текста интерфейса, hover/press — мягкий градиент.
///
/// Чтобы добавить соцсеть (VK, MAX и т.д.): дописать значение в [SocialNetwork]
/// и путь в [_socialPaths] — кнопки, подложки и hover берут стиль отсюда.
enum SocialNetwork { google, telegram, vk, max, yandex }

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

/// «G» по форме оригинала: окружность с разрывом справа сверху и
/// горизонтальной перекладиной на середине высоты.
Path _googlePath() {
  return Path()
    ..arcTo(
      Rect.fromCircle(center: const Offset(12, 12), radius: 6.5),
      -0.700,
      -5.583,
      true,
    )
    ..lineTo(12.2, 12.0);
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

/// VK: контур `V` и `K` раздельно, без скруглений.
Path _vkPath1() {
  return Path()
    ..moveTo(3, 6.2)
    ..lineTo(7.4, 18.2)
    ..lineTo(11.8, 6.2);
}

Path _vkPath2() {
  return Path()
    ..moveTo(13.6, 6.2)
    ..lineTo(13.6, 18.2);
}

Path _vkPath3() {
  return Path()
    ..moveTo(19.8, 6.2)
    ..lineTo(14.4, 12.2)
    ..lineTo(19.8, 18.2);
}

/// MAX: `M` из двух вертикалей и двух склонов (иконка условная).
Path _maxPath() {
  return Path()
    ..moveTo(4, 18.5)
    ..lineTo(4, 5.5)
    ..lineTo(9, 13.5)
    ..lineTo(14, 5.5)
    ..lineTo(14, 18.5);
}

/// Яндекс: «Я» — стойка справа, петля окружности слева, диагональ вниз.
Path _yandexStem() {
  return Path()
    ..moveTo(14, 21)
    ..lineTo(14, 3)
    ..lineTo(9.6, 3);
}

/// Петля: полуокружность радиуса 5.4 (диаметр = 10.8 = разнице координат)
/// из верхней точки в нижнюю, выпуклая влево — counterclockwise.
Path _yandexLoop() {
  return Path()
    ..moveTo(9.6, 3)
    ..arcToPoint(const Offset(9.6, 13.8),
        radius: const Radius.circular(5.4), clockwise: false)
    ..lineTo(14, 13.8);
}

Path _yandexLeg() {
  return Path()
    ..moveTo(9.6, 13.8)
    ..lineTo(4.4, 21);
}

final Map<SocialNetwork, List<Path>> _socialPaths = {
  SocialNetwork.google: [_googlePath()],
  SocialNetwork.telegram: [_telegramPath(), _telegramFoldPath()],
  SocialNetwork.vk: [_vkPath1(), _vkPath2(), _vkPath3()],
  SocialNetwork.max: [_maxPath()],
  SocialNetwork.yandex: [_yandexStem(), _yandexLoop(), _yandexLeg()],
};