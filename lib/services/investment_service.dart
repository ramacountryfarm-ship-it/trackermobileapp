import 'api_client.dart';

class InvestmentService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll({String? category, String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (category != null) q['category'] = category;
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    final res = await _api.get('/investments', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/investments', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/investments/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/investments/$id');
  }
}
