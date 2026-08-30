import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkAvailability {
  online,
  offline,
}

class NetworkStatus {
  const NetworkStatus(this._connectivity);

  NetworkStatus.withDefault() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<NetworkAvailability> get availability async {
    return await isOnline
        ? NetworkAvailability.online
        : NetworkAvailability.offline;
  }
}

final networkStatusProvider = Provider<NetworkStatus>((Ref ref) {
  return NetworkStatus.withDefault();
});
