import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/egg_service.dart';
import '../../utils/formatters.dart';
class EggManagementScreen extends StatefulWidget {
  const EggManagementScreen({super.key});

  @override
  State<EggManagementScreen> createState() => _EggManagementScreenState();
}

class _EggManagementScreenState extends State<EggManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _eggService = EggService();

  Map<String, dynamic> _inventory = {};
  List<dynamic> _collection = [];
  List<dynamic> _damages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _eggService.getInventory(),
        _eggService.getCollection(),
        _eggService.getDamages(),
      ]);
      _inventory = results[0] as Map<String, dynamic>;
      _collection = results[1] as List<dynamic>;
      _damages = results[2] as List<dynamic>;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eggs'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.black,
          unselectedLabelColor: AppTheme.gray,
          indicatorColor: AppTheme.black,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Collection'),
            Tab(text: 'Damages'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildInventory(),
                _buildCollection(),
                _buildDamages(),
              ],
            ),
    );
  }

  Widget _buildInventory() {
    final stock = _inventory['totalStock'] ?? _inventory['eggStock'] ?? 0;
    return RefreshIndicator(
      color: AppTheme.black,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Big stock card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.egg, size: 40, color: AppTheme.white),
                const SizedBox(height: 8),
                Text('$stock', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppTheme.white)),
                const Text('Total Egg Stock', style: TextStyle(fontSize: 14, color: AppTheme.gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollection() {
    final totalEggs = _collection.fold<int>(0, (sum, c) => sum + ((c['eggsCollected'] as num?)?.toInt() ?? 0));
    return RefreshIndicator(
      color: AppTheme.black,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.egg_outlined, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Collected', style: TextStyle(fontSize: 12, color: AppTheme.gray)),
                    Text('$totalEggs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._collection.map((c) {
            final eggs = (c['eggsCollected'] as num?)?.toInt() ?? 0;
            final broken = (c['brokenEggs'] as num?)?.toInt() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(Fmt.dateShort(DateTime.tryParse(c['date'] ?? '')), style: const TextStyle(fontSize: 13))),
                  Text('$eggs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (broken > 0) ...[
                    const SizedBox(width: 8),
                    Text('-$broken', style: const TextStyle(fontSize: 12, color: AppTheme.error)),
                  ],
                  const SizedBox(width: 8),
                  Text('= ${eggs - broken}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.success)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDamages() {
    return RefreshIndicator(
      color: AppTheme.black,
      onRefresh: _load,
      child: _damages.isEmpty
          ? ListView(children: [
              const SizedBox(height: 100),
              Center(child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: AppTheme.gray.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('No damage records', style: TextStyle(color: AppTheme.gray)),
                ],
              )),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _damages.length,
              itemBuilder: (ctx, i) {
                final d = _damages[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Fmt.dateShort(DateTime.tryParse(d['date'] ?? '')), style: const TextStyle(fontSize: 13)),
                            if (d['reason'] != null)
                              Text(d['reason'], style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                          ],
                        ),
                      ),
                      Text('${d['quantity'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.error)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
