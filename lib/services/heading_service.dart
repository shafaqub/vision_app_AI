import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class HeadingService {
  StreamSubscription<MagnetometerEvent>? _subscription;

  final StreamController<double> _headingController =
      StreamController<double>.broadcast();

  Stream<double> get headingStream =>
      _headingController.stream;

  double _heading = 0;

  void start() {
    _subscription =
        magnetometerEventStream().listen(
      (event) {
        if (event.x == 0 && event.y == 0) {
          return;
        }

        double heading =
            math.atan2(
              event.x,
              event.y,
            ) *
            180 /
            math.pi;

        if (heading < 0) {
          heading += 360;
        }

        // Smooth sudden changes
        double difference =
            heading - _heading;

        if (difference > 180) {
          difference -= 360;
        }

        if (difference < -180) {
          difference += 360;
        }

        _heading += difference * 0.15;

        if (_heading < 0) {
          _heading += 360;
        }

        if (_heading >= 360) {
          _heading -= 360;
        }

        _headingController.add(_heading);
      },
      onError: (error) {
        print(
          'Magnetometer error: $error',
        );
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _headingController.close();
  }
}