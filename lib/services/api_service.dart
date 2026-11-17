import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://amada-api-server-iq.fly.dev";

  static Future<List<Map<String, dynamic>>> getStoreOrders() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/store/orders')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> acceptOrder(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/store/orders/$id/accept')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> readyOrder(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/store/orders/$id/ready')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
