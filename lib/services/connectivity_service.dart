import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  late Stream<ConnectivityResult> _connectivityStream;

  ConnectivityService() {
    _connectivityStream = _connectivity.onConnectivityChanged;
  }

  /// Check if device has active internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivityStream.map((result) => result != ConnectivityResult.none);
  }

  /// Get connectivity result stream
  Stream<ConnectivityResult> get connectivityResultStream {
    return _connectivityStream;
  }

  /// Check if connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.wifi;
    } catch (e) {
      return false;
    }
  }

  /// Check if connected to mobile data
  Future<bool> isConnectedToMobile() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result == ConnectivityResult.mobile;
    } catch (e) {
      return false;
    }
  }
}

