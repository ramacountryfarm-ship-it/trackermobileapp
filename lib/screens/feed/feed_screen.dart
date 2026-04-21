import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/feed_service.dart';
import '../../utils/formatters.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _feedService = FeedService();
  List<dynamic> _commercial = [];
  List<dynamic> _ownMixes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _feedService.getCommercialFeeds(),
        _feedService.getOwnFeedMixes(),
      ]);
      _commercial = results[0];
      _ownMixes = results[1];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _deleteCommercial(String id) async {
    final ok = await _confirmDelete('Delete this commercial feed?');
    if (ok) { await _feedService.deleteCommercialFeed(id); _load(); }
  }

  Future<void> _deleteOwnMix(String id) async {
    final ok = await _confirmDelete('Delete this feed mix?');
    if (ok) { await _feedService.deleteOwnFeedMix(id); _load(); }
  }

  Future<bool> _confirmDelete(String msg) async {
    return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete'), content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
      ],
    )) ?? false;
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Management'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.black,
          unselectedLabelColor: AppTheme.gray,
          indicatorColor: AppTheme.black,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'Commercial'), Tab(text: 'Own Mix')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_feed',
        backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async {
          final route = _tabCtrl.index == 0 ? '/commercial-feed-form' : '/own-mix-form';
          final r = await Navigator.pushNamed(context, route);
          if (r == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : TabBarView(controller: _tabCtrl, children: [
              _buildCommercialTab(),
              _buildOwnMixTab(),
            ]),
    );
  }

  Widget _buildCommercialTab() {
    if (_commercial.isEmpty) {
      return const Center(child: Text('No commercial feeds added', style: TextStyle(color: AppTheme.gray)));
    }
    return RefreshIndicator(
      color: AppTheme.black, onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16), itemCount: _commercial.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final f = _commercial[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppTheme.darkGray)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['feedName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(children: [
                  Text('${Fmt.currencyDecimal(f['pricePerKg'])}/kg', style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                  const SizedBox(width: 12),
                  Text('Stock: ${Fmt.decimal(f['stockKg'])} kg', style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                ]),
              ])),
              GestureDetector(onTap: () => _deleteCommercial(f['_id']),
                child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildOwnMixTab() {
    if (_ownMixes.isEmpty) {
      return const Center(child: Text('No feed mixes created', style: TextStyle(color: AppTheme.gray)));
    }
    return RefreshIndicator(
      color: AppTheme.black, onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16), itemCount: _ownMixes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final mix = _ownMixes[i];
          final ingredients = mix['ingredients'] as List? ?? [];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(14)),
            child: InkWell(
              onTap: () async {
                final r = await Navigator.pushNamed(context, '/own-mix-form', arguments: mix['_id']);
                if (r == true) _load();
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(mix['mixName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                  GestureDetector(onTap: () => _deleteOwnMix(mix['_id']),
                    child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
                ]),
                const SizedBox(height: 8),
                // Cost per kg highlight
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.black, borderRadius: BorderRadius.circular(8)),
                  child: Text('${Fmt.currencyDecimal(mix['costPerKg'])} / kg',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.white)),
                ),
                const SizedBox(height: 8),
                // Ingredients
                Wrap(spacing: 6, runSpacing: 4, children: ingredients.map((ing) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(6)),
                    child: Text('${ing['name']} (${Fmt.decimal(ing['quantityKg'])}kg)',
                      style: const TextStyle(fontSize: 11, color: AppTheme.darkGray)),
                  );
                }).toList()),
                const SizedBox(height: 6),
                Text('Total: ${Fmt.kg(mix['totalWeightKg'])} = ${Fmt.currencyDecimal(mix['totalCost'])}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
