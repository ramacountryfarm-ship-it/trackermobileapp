import 'api_client.dart';

class DashboardService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get('/dashboard/stats');
    return res.data is Map ? res.data : {};
  }

  Future<Map<String, dynamic>> getCharts({String? from, String? to}) async {
    final q = <String, dynamic>{};
    if (from != null) q['from'] = from;
    if (to != null) q['to'] = to;
    final res = await _api.get('/dashboard/charts', query: q.isNotEmpty ? q : null);
    return res.data is Map ? res.data : {};
  }

  Future<List<dynamic>> getAlerts() async {
    final res = await _api.get('/dashboard/alerts');
    return res.data is List ? res.data : [];
  }
}
