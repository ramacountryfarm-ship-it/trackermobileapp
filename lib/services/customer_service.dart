import 'api_client.dart';

class CustomerService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll({String? type, String? search}) async {
    final q = <String, dynamic>{};
    if (type != null && type.isNotEmpty) q['type'] = type;
    if (search != null && search.isNotEmpty) q['search'] = search;
    final res = await _api.get('/customers', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _api.get('/customers/$id');
    return res.data is Map ? Map<String, dynamic>.from(res.data) : {};
  }

  Future<List<dynamic>> getHistory(String id) async {
    final res = await _api.get('/customers/$id/history');
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/customers', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/customers/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/customers/$id');
  }
}
