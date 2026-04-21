import 'api_client.dart';

class DailyLogService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll({String? batch, String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (batch != null) q['batch'] = batch;
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    final res = await _api.get('/daily-logs', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/daily-logs', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/daily-logs/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/daily-logs/$id');
  }
}
