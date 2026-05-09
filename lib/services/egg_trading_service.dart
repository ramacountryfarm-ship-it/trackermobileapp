import 'api_client.dart';

class EggTradingService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _api.get('/egg-trading/summary');
    return res.data is Map ? Map<String, dynamic>.from(res.data) : {};
  }

  Future<List<dynamic>> getPendingPayments() async {
    final res = await _api.get('/egg-trading/pending-payments');
    return res.data is List ? res.data : [];
  }

  // Farmers
  Future<List<dynamic>> getFarmers() async {
    final res = await _api.get('/egg-trading/farmers');
    return res.data is List ? res.data : [];
  }

  Future<void> createFarmer(Map<String, dynamic> data) async {
    await _api.post('/egg-trading/farmers', data: data);
  }

  Future<void> updateFarmer(String id, Map<String, dynamic> data) async {
    await _api.put('/egg-trading/farmers/$id', data: data);
  }

  Future<void> deleteFarmer(String id) async {
    await _api.delete('/egg-trading/farmers/$id');
  }

  // Procurement
  Future<List<dynamic>> getProcurement({String? farmerId, String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (farmerId != null) q['farmerId'] = farmerId;
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    final res = await _api.get('/egg-trading/procurement', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> createProcurement(Map<String, dynamic> data) async {
    await _api.post('/egg-trading/procurement', data: data);
  }

  Future<void> updateProcurement(String id, Map<String, dynamic> data) async {
    await _api.put('/egg-trading/procurement/$id', data: data);
  }

  Future<void> deleteProcurement(String id) async {
    await _api.delete('/egg-trading/procurement/$id');
  }

  // Resale
  Future<List<dynamic>> getResale({String? startDate, String? endDate}) async {
    final q = <String, dynamic>{};
    if (startDate != null) q['startDate'] = startDate;
    if (endDate != null) q['endDate'] = endDate;
    final res = await _api.get('/egg-trading/resale', query: q.isNotEmpty ? q : null);
    return res.data is List ? res.data : [];
  }

  Future<void> createResale(Map<String, dynamic> data) async {
    await _api.post('/egg-trading/resale', data: data);
  }

  Future<void> updateResale(String id, Map<String, dynamic> data) async {
    await _api.put('/egg-trading/resale/$id', data: data);
  }

  Future<void> deleteResale(String id) async {
    await _api.delete('/egg-trading/resale/$id');
  }

  // Wastage
  Future<List<dynamic>> getWastage() async {
    final res = await _api.get('/egg-trading/wastage');
    return res.data is List ? res.data : [];
  }

  Future<void> createWastage(Map<String, dynamic> data) async {
    await _api.post('/egg-trading/wastage', data: data);
  }

  Future<void> updateWastage(String id, Map<String, dynamic> data) async {
    await _api.put('/egg-trading/wastage/$id', data: data);
  }

  Future<void> deleteWastage(String id) async {
    await _api.delete('/egg-trading/wastage/$id');
  }
}
