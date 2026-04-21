import 'api_client.dart';

class FeedService {
  final _api = ApiClient();

  // Commercial Feeds
  Future<List<dynamic>> getCommercialFeeds() async {
    final res = await _api.get('/feeds/commercial');
    return res.data is List ? res.data : [];
  }

  Future<void> createCommercialFeed(Map<String, dynamic> data) async {
    await _api.post('/feeds/commercial', data: data);
  }

  Future<void> updateCommercialFeed(String id, Map<String, dynamic> data) async {
    await _api.put('/feeds/commercial/$id', data: data);
  }

  Future<void> deleteCommercialFeed(String id) async {
    await _api.delete('/feeds/commercial/$id');
  }

  // Own Feed Mixes
  Future<List<dynamic>> getOwnFeedMixes() async {
    final res = await _api.get('/feeds/own-mix');
    return res.data is List ? res.data : [];
  }

  Future<Map<String, dynamic>> getOwnFeedMixById(String id) async {
    final res = await _api.get('/feeds/own-mix/$id');
    return res.data;
  }

  Future<void> createOwnFeedMix(Map<String, dynamic> data) async {
    await _api.post('/feeds/own-mix', data: data);
  }

  Future<void> updateOwnFeedMix(String id, Map<String, dynamic> data) async {
    await _api.put('/feeds/own-mix/$id', data: data);
  }

  Future<void> deleteOwnFeedMix(String id) async {
    await _api.delete('/feeds/own-mix/$id');
  }
}
