import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/floor_plan.dart';

class FloorMapPainter extends CustomPainter {
  final Offset userPosition;
  final double heading;

  FloorMapPainter({
    required this.userPosition,
    required this.heading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final thinWall = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final floor = Rect.fromLTWH(
      20,
      20,
      size.width - 40,
      size.height - 40,
    );

    canvas.drawRect(floor, wall);

    final compLab = Rect.fromLTWH(
      floor.left + floor.width * 0.08,
      floor.top + floor.height * 0.06,
      floor.width * 0.38,
      floor.height * 0.28,
    );

    final stairs = Rect.fromLTWH(
      floor.left + floor.width * 0.54,
      floor.top + floor.height * 0.06,
      floor.width * 0.38,
      floor.height * 0.28,
    );

    final washroom = Rect.fromLTWH(
      floor.left + floor.width * 0.54,
      floor.top + floor.height * 0.65,
      floor.width * 0.38,
      floor.height * 0.28,
    );

    // Color coded zones.
    void drawZoneFill(
      Canvas canvas,
      Rect zone,
      Color color,
    ) {
      final fill = Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;

      final border = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(
        zone,
        fill,
      );

      canvas.drawRect(
        zone,
        border,
      );
    }
    drawZoneFill(
      canvas,
      compLab,
      Colors.blue,
    );

    drawZoneFill(
      canvas,
      stairs,
      Colors.orange,
    );

    drawZoneFill(
      canvas,
      washroom,
      Colors.green,
    );

    drawRoomWithBottomDoor(
      canvas,
      compLab,
      'COMPUTER LAB',
      '01',
      wall,
      thinWall,
    );

    drawOnlyStairs(
      canvas,
      stairs,
      thinWall,
    );

    drawRoomWithTopDoor(
      canvas,
      washroom,
      'WASHROOM',
      '',
      wall,
      thinWall,
    );

    // Draw BLE beacons.
    for (final beacon in beaconLocations) {
      final beaconPosition = Offset(
        floor.left + beacon.x * floor.width,
        floor.top + beacon.y * floor.height,
      );

      drawBeacon(
        canvas,
        beaconPosition,
        beacon.name,
      );
    }

    // User position.
    final userCenter = Offset(
      floor.left + userPosition.dx * floor.width,
      floor.top + userPosition.dy * floor.height,
    );

    final glow = Paint()
      ..color = Colors.blue.withValues(alpha: 0.12);

    canvas.drawCircle(
      userCenter,
      16,
      glow,
    );

    canvas.save();

    canvas.translate(
      userCenter.dx,
      userCenter.dy,
    );

    canvas.rotate(
      heading * math.pi / 180,
    );

    final arrowPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final arrow = Path()
      ..moveTo(0, -10)
      ..lineTo(-5, 6)
      ..lineTo(0, 3)
      ..lineTo(5, 6)
      ..close();

    canvas.drawPath(
      arrow,
      arrowPaint,
    );

    final centerPaint = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      Offset.zero,
      2,
      centerPaint,
    );

    canvas.restore();
  }

  void drawBeacon(
    Canvas canvas,
    Offset position,
    String label,
  ) {
    final outerRing = Paint()
      ..color = Colors.blue.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final ring = Paint()
      ..color = Colors.blue.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final beaconPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      position,
      11,
      outerRing,
    );

    canvas.drawCircle(
      position,
      8,
      ring,
    );

    canvas.drawCircle(
      position,
      4,
      beaconPaint,
    );

    drawText(
      canvas,
      label,
      Offset(
        position.dx,
        position.dy + 17,
      ),
      8,
      FontWeight.w600,
      Colors.blue.shade700,
    );
  }

  void drawRoomWithBottomDoor(
    Canvas canvas,
    Rect room,
    String name,
    String number,
    Paint wall,
    Paint thinWall,
  ) {
    final doorWidth = room.width * 0.3;

    final doorLeft = room.center.dx - doorWidth / 2;
    final doorRight = room.center.dx + doorWidth / 2;

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
      Offset(doorLeft, room.bottom),
      wall,
    );

    canvas.drawLine(
      Offset(doorRight, room.bottom),
      Offset(room.right, room.bottom),
      wall,
    );

    final hinge = Offset(
      doorLeft,
      room.bottom,
    );

    canvas.drawLine(
      hinge,
      Offset(
        doorLeft,
        room.bottom - doorWidth,
      ),
      thinWall,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: hinge,
        radius: doorWidth,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      thinWall,
    );

    drawRoomLabel(
      canvas,
      room,
      name,
      number,
    );
  }

  void drawRoomWithTopDoor(
    Canvas canvas,
    Rect room,
    String name,
    String number,
    Paint wall,
    Paint thinWall,
  ) {
    final doorWidth = room.width * 0.3;

    final doorLeft = room.center.dx - doorWidth / 2;
    final doorRight = room.center.dx + doorWidth / 2;

    canvas.drawLine(
      Offset(room.left, room.bottom),
      Offset(room.right, room.bottom),
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
      Offset(room.left, room.top),
      Offset(doorLeft, room.top),
      wall,
    );

    canvas.drawLine(
      Offset(doorRight, room.top),
      Offset(room.right, room.top),
      wall,
    );

    final hinge = Offset(
      doorLeft,
      room.top,
    );

    canvas.drawLine(
      hinge,
      Offset(
        doorLeft,
        room.top + doorWidth,
      ),
      thinWall,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: hinge,
        radius: doorWidth,
      ),
      0,
      math.pi / 2,
      false,
      thinWall,
    );

    drawRoomLabel(
      canvas,
      room,
      name,
      number,
    );
  }

  void drawOnlyStairs(
    Canvas canvas,
    Rect room,
    Paint paint,
  ) {
    final left = room.left + room.width * 0.1;
    final right = room.right - room.width * 0.1;

    final top = room.top + room.height * 0.22;
    final bottom = room.bottom - room.height * 0.05;

    const steps = 9;

    final stepHeight = (bottom - top) / steps;

    for (int i = 0; i <= steps; i++) {
      final y = top + i * stepHeight;

      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        paint,
      );
    }

    drawText(
      canvas,
      'STAIRS',
      Offset(
        room.center.dx,
        room.top + room.height * 0.09,
      ),
      13,
      FontWeight.bold,
      Colors.black,
    );
  }

  void drawRoomLabel(
    Canvas canvas,
    Rect room,
    String name,
    String number,
  ) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    titlePainter.layout(
      maxWidth: room.width * 0.8,
    );

    double titleY;

    if (number.isEmpty) {
      titleY = room.center.dy - titlePainter.height / 2;
    } else {
      titleY =
          room.center.dy -
          titlePainter.height / 2 -
          8;
    }

    titlePainter.paint(
      canvas,
      Offset(
        room.center.dx - titlePainter.width / 2,
        titleY,
      ),
    );

    if (number.isNotEmpty) {
      final numberPainter = TextPainter(
        text: TextSpan(
          text: number,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      numberPainter.layout();

      numberPainter.paint(
        canvas,
        Offset(
          room.center.dx - numberPainter.width / 2,
          titleY + titlePainter.height + 4,
        ),
      );
    }
  }

  void drawText(
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
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();

    painter.paint(
      canvas,
      Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant FloorMapPainter oldDelegate,
  ) {
    return oldDelegate.userPosition != userPosition ||
        oldDelegate.heading != heading;
  }
}