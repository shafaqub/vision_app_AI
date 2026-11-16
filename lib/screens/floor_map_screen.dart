import 'dart:async';

import 'package:flutter/material.dart';

import '../services/heading_service.dart';
import '../services/position_service.dart';
import '../widgets/floor_map_painter.dart';

class FloorMapScreen extends StatefulWidget {
  const FloorMapScreen({super.key});

  @override
  State<FloorMapScreen> createState() =>
      _FloorMapScreenState();
}

class _FloorMapScreenState
    extends State<FloorMapScreen> {
  final PositionService positionService =
      PositionService();

  final HeadingService headingService =
      HeadingService();

  Timer? positionTimer;

  StreamSubscription<double>? headingSubscription;

  Offset userPosition =
      const Offset(0.15, 0.82);

  double heading = 0;

  @override
  void initState() {
    super.initState();

    startTracking();
  }

  void startTracking() {
    // Start phone compass
    headingService.start();

    headingSubscription =
        headingService.headingStream.listen(
      (newHeading) {
        if (!mounted) {
          return;
        }

        setState(() {
          heading = newHeading;
        });
      },
    );

    // Get position immediately
    updatePosition();

    // Keep asking backend for new position
    positionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        updatePosition();
      },
    );
  }

  Future<void> updatePosition() async {
    final position =
        await positionService.getPosition();

    if (position == null || !mounted) {
      return;
    }

    setState(() {
      userPosition = Offset(
        position.x,
        position.y,
      );
    });

    print(
      'Flutter position: '
      '${position.location} '
      '${position.x}, ${position.y}',
    );
  }

  @override
  void dispose() {
    positionTimer?.cancel();
    headingSubscription?.cancel();

    headingService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: CustomPaint(
          painter: FloorMapPainter(
            userPosition: userPosition,
            heading: heading,
          ),
        ),
      ),
    );
  }
}