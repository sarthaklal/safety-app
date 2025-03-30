import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Callback for phone shakes
typedef PhoneShakeCallback = void Function(int shakeCount);

/// ShakeDetector class for phone shake functionality
class ShakeDetector {
  /// User callback for phone shake with current shake count
  final PhoneShakeCallback onPhoneShake;

  /// Shake detection threshold
  final double shakeThresholdGravity;

  /// Minimum time between shakes
  final int shakeSlopTimeMS;

  /// Time before shake count resets
  final int shakeCountResetTime;

  /// Number of shakes required to trigger actions
  final int minimumShakeCount;

  /// Maximum shake count to trigger additional action
  final int maxShakeCount;

  /// Timer for delaying the action
  Timer? _actionTimer;

  int mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int mShakeCount = 0;

  /// StreamSubscription for Accelerometer events
  StreamSubscription? streamSubscription;

  /// Constructor waits until [startListening] is called
  ShakeDetector.waitForStart({
    required this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 1000,
    this.shakeCountResetTime = 1000,
    this.minimumShakeCount = 1,
    this.maxShakeCount = 3,
  });

  /// Constructor automatically calls [startListening]
  ShakeDetector.autoStart({
    required this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 1000,
    this.minimumShakeCount = 1,
    this.maxShakeCount = 3,
  }) {
    startListening();
  }

  /// Starts listening to accelerometer events
  void startListening() {
    streamSubscription = accelerometerEventStream().listen(
          (AccelerometerEvent event) {
        double x = event.x;
        double y = event.y;
        double z = event.z;

        double gX = x / 9.80665;
        double gY = y / 9.80665;
        double gZ = z / 9.80665;

        // gForce will be close to 1 when there is no movement.
        double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

        if (gForce > shakeThresholdGravity) {
          var now = DateTime.now().millisecondsSinceEpoch;

          // Ignore shake events too close to each other
          if (mShakeTimestamp + shakeSlopTimeMS > now) {
            return;
          }

          // Reset the shake count after 3 seconds of no shakes
          if (mShakeTimestamp + shakeCountResetTime < now) {
            mShakeCount = 0;
          }

          mShakeTimestamp = now;
          mShakeCount++;

          // Cancel any previously scheduled action
          _actionTimer?.cancel();

          // Delay action execution to check for higher shake counts
          _actionTimer = Timer(Duration(milliseconds: shakeSlopTimeMS), () {
            onPhoneShake(mShakeCount);
            if (mShakeCount >= maxShakeCount) {
              mShakeCount = 0; // Reset after max shakes
            }
          });
        }
      },
    );
  }

  /// Stops listening to accelerometer events
  void stopListening() {
    streamSubscription?.cancel();
    _actionTimer?.cancel();
  }
}
