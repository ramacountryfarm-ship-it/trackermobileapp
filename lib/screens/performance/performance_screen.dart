import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../services/batch_service.dart';
import '../../utils/formatters.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});
  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _api = ApiClient();
  List<dynamic> _batches = [];
  String? _batchId;
  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _prediction = {};
  Map<String, dynamic> _feedCost = {};
  List<dynamic> _feedPlan = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _batches = await BatchService().getAll();
      final q = _batchId != null ? {'batchId': _batchId} : null;
      final results = await Future.wait([
        _api.get('/performance/metrics', query: q),
        _api.get('/performance/egg-prediction'),
        _api.get('/performance/feed-cost-per-egg'),
        _api.get('/performance/feed-planner'),
      ]);
      _metrics = results[0].data is Map ? results[0].data : {};
      _prediction = results[1].data is Map ? results[1].data : {};
      _feedCost = results[2].data is Map ? results[2].data : {};
      final fpData = results[3].data;
      _feedPlan = fpData is Map ? (fpData['batches'] ?? []) : (fpData is List ? fpData : []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : RefreshIndicator(color: AppTheme.black, onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        // Batch filter
        if (_batches.isNotEmpty) ...[
          DropdownButtonFormField<String>(value: _batchId, isExpanded: true, decoration: const InputDecoration(hintText: 'All Batches'),
              items: [const DropdownMenuItem<String>(value: null, child: Text('All Batches')),
                ..._batches.map((b) => DropdownMenuItem<String>(value: b['_id'], child: Text(b['batchName'] ?? '')))],
              onChanged: (v) { setState(() => _batchId = v); _load(); }),
          const SizedBox(height: 16),
        ],

        // Metrics
        Row(children: [
          Expanded(child: _metricCard('Hen-Day', '${(_metrics['henDayProduction'] as num?)?.toStringAsFixed(1) ?? '0'}%', AppTheme.warning)),
          const SizedBox(width: 10),
          Expanded(child: _metricCard('Mortality', '${(_metrics['mortalityRate'] as num?)?.toStringAsFixed(1) ?? '0'}%', AppTheme.error)),
          const SizedBox(width: 10),
          Expanded(child: _metricCard('Feed Eff.', '${(_metrics['feedEfficiency'] as num?)?.toStringAsFixed(2) ?? '0'} kg/egg', AppTheme.info)),
        ]),
        const SizedBox(height: 16),

        // Prediction + Feed cost
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.black, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Icon(Icons.egg, color: AppTheme.white, size: 28),
              const SizedBox(height: 6),
              Text('${_prediction['predictedEggs'] ?? '-'}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.white)),
              const Text('Tomorrow\'s eggs', style: TextStyle(fontSize: 11, color: AppTheme.gray)),
            ]))),
          const SizedBox(width: 10),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const Icon(Icons.currency_rupee, size: 28, color: AppTheme.darkGray),
              const SizedBox(height: 6),
              Text(Fmt.currencyDecimal(_feedCost['feedCostPerEgg']), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const Text('Cost / egg', style: TextStyle(fontSize: 11, color: AppTheme.gray)),
            ]))),
        ]),
        const SizedBox(height: 20),

        // Feed planner
        if (_feedPlan.isNotEmpty) ...[
          const Text('Feed Planner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(decoration: BoxDecoration(border: Border.all(color: AppTheme.separator), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: const Row(children: [
                  Expanded(flex: 3, child: Text('Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Birds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Feed/day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                ])),
              ..._feedPlan.map((f) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.separator.withValues(alpha: 0.5)))),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(f['batchName'] ?? '', style: const TextStyle(fontSize: 13))),
                  Expanded(flex: 2, child: Text('${f['currentBirds'] ?? f['birds'] ?? '-'}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(Fmt.kg(f['totalFeedKg'] ?? f['feedPerDay']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                ]))),
            ])),
        ],
      ])),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
      ]));
  }
}
