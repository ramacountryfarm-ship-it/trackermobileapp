import 'api_client.dart';

class VaccinationService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll({String? batch, String? status}) async {
    final q = <String, dynamic>{};
    if (batch != null) q['batch'] = batch;
    if (status != null) q['status'] = status;
    final res = await _api.get('/vaccinations', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/vaccinations', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/vaccinations/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/vaccinations/$id');
  }

  Future<void> toggleStatus(String id) async {
    await _api.patch('/vaccinations/$id/toggle');
  }
}
