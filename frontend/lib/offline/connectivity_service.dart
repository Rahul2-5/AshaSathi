import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static const String baseUrl = "http://10.0.2.2:8080";

  /// True only if:
  /// 1) network exists
  /// 2) backend is reachable
  Future<bool> isOnline() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return false;

    try {
      final res = await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 3));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
