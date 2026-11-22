import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/floor_plan.dart';

class FloorMapPainter extends CustomPainter {
  final Offset userPosition;
  final double heading;

  FloorMapPainter({required this.userPosition, required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF4F0E6), BlendMode.src);

    final unit = (size.width / 667).clamp(0.55, 1.35).toDouble();

    final mapWidth = size.width - 48 * unit;
    final mapHeight = math
        .min(size.height * 0.69, size.width * 1.36)
        .toDouble();
    final mapTop = math
        .max(24 * unit, (size.height - mapHeight - 170 * unit) / 2)
        .toDouble();
    final mapRect = Rect.fromLTWH(
      (size.width - mapWidth) / 2,
      mapTop,
      mapWidth,
      mapHeight,
    );

    final wallPaint = Paint()
      ..color = const Color(0xFF263545)
      ..style = PaintingStyle.fill;

    final wallLine = Paint()
      ..color = const Color(0xFF263545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * unit
      ..strokeCap = StrokeCap.square;

    final thinLine = Paint()
      ..color = const Color(0xFF263545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * unit
      ..strokeCap = StrokeCap.square;

    canvas.drawRRect(
      RRect.fromRectAndRadius(mapRect, Radius.circular(6 * unit)),
      wallPaint,
    );

    final interior = Rect.fromLTWH(
      mapRect.left + 12 * unit,
      mapRect.top + 12 * unit,
      mapRect.width - 24 * unit,
      mapRect.height - 24 * unit,
    );

    canvas.drawRect(interior, Paint()..color = const Color(0xFFF4F0E6));

    _drawGrid(canvas, interior, unit);

    final lab = Rect.fromLTWH(
      interior.left,
      interior.top,
      interior.width * 0.38,
      interior.height * 0.28,
    );

    final stairs = Rect.fromLTWH(
      interior.left + interior.width * 0.54,
      interior.top,
      interior.width * 0.38,
      interior.height * 0.28,
    );

    final washroom = Rect.fromLTWH(
      interior.left + interior.width * 0.60,
      interior.top + interior.height * 0.68,
      interior.width * 0.38,
      interior.height * 0.27,
    );

    canvas.drawRect(
      lab.shift(const Offset(3, 3)),
      Paint()..color = const Color(0xFFB8CBDE),
    );
    canvas.drawRect(lab, Paint()..color = const Color(0xFFE4EFFD));

    canvas.drawRect(
      stairs.shift(const Offset(3, 3)),
      Paint()..color = const Color(0xFF9FA5AA),
    );
    canvas.drawRect(stairs, Paint()..color = const Color(0xFFC9CDCF));

    canvas.drawRect(
      washroom.shift(const Offset(3, 3)),
      Paint()..color = const Color(0xFFAFC5D9),
    );
    canvas.drawRect(washroom, Paint()..color = const Color(0xFFE1EFFA));

    _drawComputerLab(canvas, lab, unit);
    _drawStairs(canvas, stairs, unit);
    _drawWashroom(canvas, washroom, unit);

    _drawRoomOutline(canvas, lab, wallLine, thinLine, unit, 'lab');
    _drawRoomOutline(canvas, stairs, wallLine, thinLine, unit, 'stairs');
    _drawRoomOutline(canvas, washroom, wallLine, thinLine, unit, 'washroom');
    _drawOuterBottomDoor(canvas, interior, wallLine, thinLine, unit);

    // The computer-lab plant is intentionally omitted. Plants belong in the corridor.
    _drawPlant(
      canvas,
      Offset(interior.left + 30 * unit, interior.top + interior.height * 0.39),
      unit,
    );
    _drawPlant(
      canvas,
      Offset(interior.right - 30 * unit, interior.top + interior.height * 0.39),
      unit,
    );
    _drawPlant(
      canvas,
      Offset(interior.left + 30 * unit, interior.top + interior.height * 0.71),
      unit,
    );

    _drawCorridorLabel(
      canvas,
      Offset(interior.center.dx, interior.top + interior.height * 0.47),
      unit,
    );

    for (final beacon in beaconLocations) {
      Offset beaconPosition;
      if (beacon.id == 'BEACON_LAB') {
        beaconPosition = Offset(
          lab.left + lab.width * 0.82,
          lab.top + lab.height * 0.20,
        );
      } else if (beacon.id == 'BEACON_STAIRS') {
        beaconPosition = Offset(
          stairs.right - stairs.width * 0.16,
          stairs.top + stairs.height * 0.20,
        );
      } else if (beacon.id == 'BEACON_WASHROOM') {
        beaconPosition = Offset(
          washroom.left + washroom.width * 0.24,
          washroom.top + washroom.height * 0.48,
        );
      } else {
        beaconPosition = Offset(
          mapRect.left + beacon.x * mapRect.width,
          mapRect.top + beacon.y * mapRect.height,
        );
      }
      _drawBeacon(canvas, beaconPosition, beacon.name, unit);
    }

    final userCenter = Offset(
      mapRect.left + userPosition.dx * mapRect.width,
      mapRect.top + userPosition.dy * mapRect.height,
    );
    _drawUserPosition(canvas, userCenter, heading, unit);

    _drawStartHere(
      canvas,
      Offset(size.width * 0.23, mapRect.bottom + 78 * unit),
      unit,
    );

    _drawLegend(
      canvas,
      Offset(size.width * 0.67, mapRect.bottom + 78 * unit),
      unit,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect, double unit) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDED8CB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 * unit;

    final spacing = 74 * unit;
    for (double x = rect.left; x <= rect.right; x += spacing) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
    for (double y = rect.top; y <= rect.bottom; y += spacing) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawComputerLab(Canvas canvas, Rect room, double unit) {
    final deskPaint = Paint()..color = const Color(0xFFE9A16D);
    final deskLine = Paint()
      ..color = const Color(0xFF263545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * unit;
    final monitorPaint = Paint()..color = const Color(0xFF40516B);

    for (int row = 0; row < 3; row++) {
      final y = room.top + room.height * (0.23 + row * 0.25);
      for (int col = 0; col < 2; col++) {
        // Leave the lower-right corner clear for the lab door swing.
        if (row == 2 && col == 1) {
          continue;
        }
        final x = room.left + room.width * (0.23 + col * 0.46);

        final desk = Rect.fromCenter(
          center: Offset(x, y),
          width: room.width * 0.29,
          height: room.height * 0.12,
        );
        canvas.drawRect(desk, deskPaint);
        canvas.drawRect(desk, deskLine);

        final monitor = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y - desk.height * 0.78),
            width: desk.width * 0.70,
            height: desk.height * 0.82,
          ),
          Radius.circular(3 * unit),
        );
        canvas.drawRRect(monitor, monitorPaint);
        canvas.drawRRect(monitor, deskLine);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y + desk.height * 0.90),
              width: desk.width * 0.55,
              height: desk.height * 0.72,
            ),
            Radius.circular(4 * unit),
          ),
          Paint()..color = const Color(0xFF4A5A70),
        );

        canvas.drawLine(
          Offset(x, y - desk.height * 0.35),
          Offset(x, y + desk.height * 0.20),
          deskLine,
        );
      }
    }

    _drawRoomLabel(
      canvas,
      'Computer\nLab',
      Offset(room.left + room.width * 0.62, room.top + room.height * 0.50),
      unit,
      width: 106 * unit,
    );
  }

  void _drawStairs(Canvas canvas, Rect room, double unit) {
    canvas.drawRect(room, Paint()..color = const Color(0xFFC9CBCD));

    final rail = Paint()
      ..color = const Color(0xFF263545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * unit;

    final left = room.left + room.width * 0.24;
    final right = room.right - room.width * 0.10;
    final top = room.top + room.height * 0.18;
    final bottom = room.bottom - room.height * 0.06;
    const steps = 8;
    final stepHeight = (bottom - top) / (steps + 1);

    for (int i = 0; i <= steps; i++) {
      final y = top + i * stepHeight;
      canvas.drawLine(Offset(left, y), Offset(right, y), rail);
    }

    canvas.drawLine(Offset(right, top), Offset(right, bottom), rail);

    _drawRoomLabel(
      canvas,
      'Stairs',
      Offset(room.left + room.width * 0.34, room.top + room.height * 0.42),
      unit,
      width: 82 * unit,
    );
  }

  void _drawWashroom(Canvas canvas, Rect room, double unit) {
    final border = Paint()
      ..color = const Color(0xFF263545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * unit;
    final fixture = Paint()
      ..color = const Color(0xFFF9FBFD)
      ..style = PaintingStyle.fill;

    final sink = Rect.fromCenter(
      center: Offset(
        room.right - room.width * 0.24,
        room.top + room.height * 0.22,
      ),
      width: room.width * 0.48,
      height: room.height * 0.16,
    );
    canvas.drawOval(sink, fixture);
    canvas.drawOval(sink, border);
    canvas.drawCircle(
      Offset(sink.center.dx, sink.center.dy - 2 * unit),
      3 * unit,
      Paint()..color = const Color(0xFF263545),
    );

    final toilet = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          room.right - room.width * 0.24,
          room.bottom - room.height * 0.18,
        ),
        width: room.width * 0.36,
        height: room.height * 0.38,
      ),
      Radius.circular(18 * unit),
    );
    canvas.drawRRect(toilet, fixture);
    canvas.drawRRect(toilet, border);

    _drawRoomLabel(
      canvas,
      'Washroom',
      Offset(room.left + room.width * 0.48, room.top + room.height * 0.68),
      unit,
      width: 112 * unit,
    );
  }

  void _drawRoomOutline(
    Canvas canvas,
    Rect room,
    Paint wall,
    Paint thin,
    double unit,
    String roomType,
  ) {
    canvas.drawLine(
      Offset(room.left, room.top),
      Offset(room.right, room.top),
      wall,
    );
    canvas.drawLine(
      Offset(room.left, room.top),
      Offset(room.left, room.bottom),
      wall,
    );
    canvas.drawLine(
      Offset(room.right, room.top),
      Offset(room.right, room.bottom),
      wall,
    );
    canvas.drawLine(
      Offset(room.left, room.bottom),
      Offset(room.right, room.bottom),
      wall,
    );

    if (roomType == 'lab') {
      final doorWidth = room.width * 0.30;
      final doorLeft = room.left + room.width * 0.40;
      final doorRight = doorLeft + doorWidth;
      canvas.drawLine(
        Offset(room.left, room.bottom),
        Offset(doorLeft, room.bottom),
        wall,
      );
      canvas.drawLine(
        Offset(doorRight, room.bottom),
        Offset(room.right, room.bottom),
        wall,
      );
      canvas.drawLine(
        Offset(doorLeft, room.bottom),
        Offset(doorLeft, room.bottom - doorWidth),
        thin,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(doorLeft, room.bottom),
          radius: doorWidth,
        ),
        -math.pi / 2,
        math.pi / 2,
        false,
        thin,
      );
    } else if (roomType == 'stairs') {
      final doorWidth = room.width * 0.28;
      final doorLeft = room.left + room.width * 0.02;
      final doorRight = doorLeft + doorWidth;

      canvas.drawLine(
        Offset(room.left, room.bottom),
        Offset(doorLeft, room.bottom),
        wall,
      );
      canvas.drawLine(
        Offset(doorRight, room.bottom),
        Offset(room.right, room.bottom),
        wall,
      );
      canvas.drawLine(
        Offset(doorLeft, room.bottom),
        Offset(doorLeft, room.bottom - doorWidth),
        thin,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(doorLeft, room.bottom),
          radius: doorWidth,
        ),
        -math.pi / 2,
        math.pi / 2,
        false,
        thin,
      );
    } else if (roomType == 'washroom') {
      final doorWidth = room.width * 0.30;
      final doorLeft = room.left + room.width * 0.02;
      final doorRight = doorLeft + doorWidth;

      canvas.drawLine(
        Offset(room.left, room.top),
        Offset(doorLeft, room.top),
        wall,
      );
      canvas.drawLine(
        Offset(doorRight, room.top),
        Offset(room.right, room.top),
        wall,
      );
      canvas.drawLine(
        Offset(doorLeft, room.top),
        Offset(doorLeft, room.top + doorWidth),
        thin,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(doorLeft, room.top), radius: doorWidth),
        0,
        math.pi / 2,
        false,
        thin,
      );
    }
  }

  void _drawCorridorLabel(Canvas canvas, Offset center, double unit) {
    _drawRoomLabel(canvas, 'Corridor', center, unit, width: 105 * unit);
  }

  void _drawOuterBottomDoor(
    Canvas canvas,
    Rect interior,
    Paint wall,
    Paint thin,
    double unit,
  ) {
    final doorWidth = interior.width * 0.16;
    final doorLeft = interior.left + interior.width * 0.10;
    final doorRight = doorLeft + doorWidth;

    canvas.drawLine(
      Offset(interior.left, interior.bottom),
      Offset(doorLeft, interior.bottom),
      wall,
    );
    canvas.drawLine(
      Offset(doorRight, interior.bottom),
      Offset(interior.right, interior.bottom),
      wall,
    );
    canvas.drawLine(
      Offset(doorLeft, interior.bottom),
      Offset(doorLeft, interior.bottom - doorWidth),
      thin,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(doorLeft, interior.bottom),
        radius: doorWidth,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      thin,
    );
  }

  void _drawRoomLabel(
    Canvas canvas,
    String text,
    Offset center,
    double unit, {
    required double width,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: text == 'Computer\nLab' ? 20 * unit : 18 * unit,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    painter.layout();

    final rect = Rect.fromCenter(
      center: center,
      width: math.max(width, painter.width + 24 * unit),
      height: painter.height + 18 * unit,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(10 * unit)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(10 * unit)),
      Paint()
        ..color = const Color(0xFFBAC2CA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * unit,
    );
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  void _drawWifiDevice(Canvas canvas, Offset center, double unit) {
    final blue = Paint()..color = const Color(0xFF1677F2);
    final blueLine = Paint()
      ..color = const Color(0xFF1677F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * unit;

    canvas.drawArc(
      Rect.fromCenter(center: center, width: 38 * unit, height: 38 * unit),
      3.55,
      2.18,
      false,
      blueLine,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy),
        width: 24 * unit,
        height: 24 * unit,
      ),
      3.55,
      2.18,
      false,
      blueLine,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 25 * unit),
          width: 24 * unit,
          height: 42 * unit,
        ),
        Radius.circular(8 * unit),
      ),
      blue,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + 18 * unit),
      3.2 * unit,
      Paint()..color = Colors.white,
    );
  }

  void _drawBeacon(Canvas canvas, Offset position, String label, double unit) {
    final beaconNumber = switch (label) {
      'OUTSIDE' => 'B6',
      'LAB' => 'B5',
      'STAIRS' => 'B1',
      'WASHROOM' => 'B4',
      'CENTER L' => 'B2',
      'CENTER R' => 'B3',
      _ => label,
    };

    _drawWifiDevice(
      canvas,
      Offset(position.dx, position.dy - 6 * unit),
      unit * 0.58,
    );

    final badgeRect = Rect.fromCenter(
      center: Offset(position.dx, position.dy + 30 * unit),
      width: 38 * unit,
      height: 28 * unit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, Radius.circular(9 * unit)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, Radius.circular(9 * unit)),
      Paint()
        ..color = const Color(0xFFBBC4CC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * unit,
    );
    _drawCenteredText(
      canvas,
      beaconNumber,
      badgeRect.center,
      16 * unit,
      FontWeight.w800,
      const Color(0xFF263545),
    );
  }

  void _drawUserPosition(
    Canvas canvas,
    Offset position,
    double heading,
    double unit,
  ) {
    canvas.drawCircle(
      position,
      16 * unit,
      Paint()..color = const Color(0x281677F2),
    );
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(heading * math.pi / 180);

    final arrow = Path()
      ..moveTo(0, -12 * unit)
      ..lineTo(-7 * unit, 8 * unit)
      ..lineTo(0, 3 * unit)
      ..lineTo(7 * unit, 8 * unit)
      ..close();
    canvas.drawPath(
      arrow,
      Paint()
        ..color = const Color(0xFF1677F2)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  void _drawPlant(Canvas canvas, Offset center, double unit) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 24 * unit),
          width: 27 * unit,
          height: 22 * unit,
        ),
        Radius.circular(4 * unit),
      ),
      Paint()..color = const Color(0xFFC18A55),
    );

    final leaf = Paint()..color = const Color(0xFF5A9E48);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            center.dx + math.cos(angle) * 11 * unit,
            center.dy + math.sin(angle) * 11 * unit,
          ),
          width: 12 * unit,
          height: 23 * unit,
        ),
        leaf,
      );
    }
  }

  void _drawStartHere(Canvas canvas, Offset center, double unit) {
    final arrow = Path()
      ..moveTo(center.dx, center.dy - 58 * unit)
      ..lineTo(center.dx - 15 * unit, center.dy - 36 * unit)
      ..lineTo(center.dx - 7 * unit, center.dy - 36 * unit)
      ..lineTo(center.dx - 7 * unit, center.dy - 12 * unit)
      ..lineTo(center.dx + 7 * unit, center.dy - 12 * unit)
      ..lineTo(center.dx + 7 * unit, center.dy - 36 * unit)
      ..lineTo(center.dx + 15 * unit, center.dy - 36 * unit)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFF263545));

    final rect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 16 * unit),
      width: 190 * unit,
      height: 58 * unit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(16 * unit)),
      Paint()..color = const Color(0xFFDDF5D8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(16 * unit)),
      Paint()
        ..color = const Color(0xFF4BAE51)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * unit,
    );
    _drawCenteredText(
      canvas,
      'Start Here',
      rect.center,
      24 * unit,
      FontWeight.w800,
      Colors.black,
    );
  }

  void _drawLegend(Canvas canvas, Offset center, double unit) {
    final rect = Rect.fromCenter(
      center: center,
      width: 370 * unit,
      height: 70 * unit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(14 * unit)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(14 * unit)),
      Paint()
        ..color = const Color(0xFFBFC7D1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * unit,
    );

    _drawWifiDevice(
      canvas,
      Offset(rect.left + 48 * unit, rect.center.dy),
      unit * 0.72,
    );
    _drawCenteredText(
      canvas,
      '= Bluetooth Low Energy Beacon',
      Offset(rect.center.dx + 45 * unit, rect.center.dy),
      17 * unit,
      FontWeight.w500,
      Colors.black,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    FontWeight weight,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant FloorMapPainter oldDelegate) {
    return oldDelegate.userPosition != userPosition ||
        oldDelegate.heading != heading;
  }
}
