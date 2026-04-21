import 'api_client.dart';

class BirdBreedService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll() async {
    final res = await _api.get('/bird-breeds');
    return res.data is List ? res.data : [];
  }

  Future<Map<String, dynamic>> getInfo(String id) async {
    final res = await _api.get('/bird-breeds/$id/info');
    return res.data;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/bird-breeds', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/bird-breeds/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/bird-breeds/$id');
  }
}
