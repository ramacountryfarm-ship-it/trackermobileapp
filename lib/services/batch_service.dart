import 'api_client.dart';

class BatchService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll({String? livestockType}) async {
    final q = <String, dynamic>{};
    if (livestockType != null) q['livestockType'] = livestockType;
    final res = await _api.get('/batches', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _api.get('/batches/$id');
    return res.data;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/batches', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/batches/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/batches/$id');
  }

  Future<int> getCurrentBirds(String id) async {
    final res = await _api.get('/batches/$id/current-birds');
    return res.data?['currentBirds'] ?? 0;
  }
}
