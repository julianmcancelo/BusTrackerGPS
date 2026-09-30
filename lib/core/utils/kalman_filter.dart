import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// 2D Kalman filter customized for GPS vehicle trajectory smoothing and street alignment.
class GpsKalmanFilter {
  final double processNoise; // Q: estimation variance (motion model)
  double _latVariance = 0.0;
  double _lngVariance = 0.0;
  double? _lat;
  double? _lng;
  int? _lastTimestampMs;

  GpsKalmanFilter({this.processNoise = 3.0});

  void reset() {
    _lat = null;
    _lng = null;
    _latVariance = 0.0;
    _lngVariance = 0.0;
    _lastTimestampMs = null;
  }

  /// Process raw GPS point with accuracy and return smoothed coordinate.
  LatLng process({
    required double lat,
    required double lng,
    required double accuracyMeters,
    required int timestampMs,
  }) {
    // Initial state
    if (_lat == null || _lng == null || _lastTimestampMs == null) {
      _lat = lat;
      _lng = lng;
      _latVariance = accuracyMeters * accuracyMeters;
      _lngVariance = accuracyMeters * accuracyMeters;
      _lastTimestampMs = timestampMs;
      return LatLng(lat, lng);
    }

    final dt = (timestampMs - _lastTimestampMs!) / 1000.0;
    _lastTimestampMs = timestampMs;

    if (dt <= 0) {
      return LatLng(_lat!, _lng!);
    }

    // Measurement noise covariance (R)
    final r = math.max(accuracyMeters * accuracyMeters, 1.0);

    // Predict state variance: P = P + Q * dt
    _latVariance += processNoise * dt;
    _lngVariance += processNoise * dt;

    // Kalman gain: K = P / (P + R)
    final kLat = _latVariance / (_latVariance + r);
    final kLng = _lngVariance / (_lngVariance + r);

    // Update state estimate: x = x + K * (measurement - x)
    _lat = _lat! + kLat * (lat - _lat!);
    _lng = _lng! + kLng * (lng - _lng!);

    // Update error covariance: P = (1 - K) * P
    _latVariance = (1.0 - kLat) * _latVariance;
    _lngVariance = (1.0 - kLng) * _lngVariance;

    return LatLng(_lat!, _lng!);
  }
}
