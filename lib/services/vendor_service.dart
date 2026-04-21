import 'api_client.dart';

class VendorService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll() async {
    final res = await _api.get('/vendors');
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/vendors', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/vendors/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/vendors/$id');
  }
}
