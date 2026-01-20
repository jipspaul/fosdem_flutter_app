import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus {
  online,
  offline,
  wifi,
  mobile,
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });

    // Check initial status
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      print('Error checking initial connectivity: $e');
      _currentStatus = ConnectivityStatus.offline;
      _statusController.add(_currentStatus);
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _currentStatus = ConnectivityStatus.offline;
    } else if (results.contains(ConnectivityResult.wifi)) {
      _currentStatus = ConnectivityStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _currentStatus = ConnectivityStatus.mobile;
    } else {
      _currentStatus = ConnectivityStatus.online;
    }
    _statusController.add(_currentStatus);
  }

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  ConnectivityStatus get currentStatus => _currentStatus;

  bool get isOnline =>
      _currentStatus != ConnectivityStatus.offline;

  bool get isWifi => _currentStatus == ConnectivityStatus.wifi;

  bool get isMobile => _currentStatus == ConnectivityStatus.mobile;

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
