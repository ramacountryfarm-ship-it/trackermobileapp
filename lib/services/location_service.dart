import 'api_client.dart';

class LocationService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll() async {
    final res = await _api.get('/locations');
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/locations', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/locations/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/locations/$id');
  }
}
