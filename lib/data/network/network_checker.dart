import 'package:connectivity_plus/connectivity_plus.dart';

/// 서버 쓰기 요청 전에 명백한 오프라인(비행기 모드, 와이파이·데이터 꺼짐)을 걸러낸다.
/// 와이파이는 잡혔지만 실제 인터넷이 안 되는 경우까지는 판별하지 못한다.
class NetworkChecker {
  NetworkChecker({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}