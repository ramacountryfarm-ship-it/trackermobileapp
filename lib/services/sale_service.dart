import 'api_client.dart';

class SaleService {
  final _api = ApiClient();

  Future<List<dynamic>> getAll({String? productType, String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (productType != null) q['productType'] = productType;
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    final res = await _api.get('/sales', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _api.post('/sales', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _api.put('/sales/$id', data: data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/sales/$id');
  }
}
