import 'api_client.dart';

class EggService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getInventory() async {
    final res = await _api.get('/eggs/inventory');
    return res.data is Map ? res.data : {};
  }

  Future<List<dynamic>> getCollection({String? startDate, String? endDate, String? batch}) async {
    final q = <String, dynamic>{};
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    if (batch != null) q['batch'] = batch;
    final res = await _api.get('/eggs/collection', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<List<dynamic>> getDamages({String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    final res = await _api.get('/eggs/damages', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> createDamage(Map<String, dynamic> data) async {
    await _api.post('/eggs/damages', data: data);
  }
}
