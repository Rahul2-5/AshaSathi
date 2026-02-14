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
      // Prefer health endpoint if available, but accept any valid HTTP response
      final uri = Uri.parse("$baseUrl/health");
      final res = await http.get(uri).timeout(const Duration(seconds: 3));

      // Treat any response < 500 as server reachable. Some servers may not expose /health (404)
      if (res.statusCode < 500) return true;

      // Fallback: try root URL and accept any non-500 response
      final rootRes = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 3));
      return rootRes.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
