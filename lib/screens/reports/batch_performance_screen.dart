import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class BatchPerformanceScreen extends StatefulWidget {
  const BatchPerformanceScreen({super.key});

  @override
  State<BatchPerformanceScreen> createState() => _BatchPerformanceScreenState();
}

class _BatchPerformanceScreenState extends State<BatchPerformanceScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_from != null) params['from'] = Fmt.dateApi(_from!);
      if (_to != null) params['to'] = Fmt.dateApi(_to!);
      final res = await ApiClient().get('/reports/batch-performance', query: params);
      setState(() => _rows = List<Map<String, dynamic>>.from(res.data['rows'] ?? []));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: _from != null && _to != null ? DateTimeRange(start: _from!, end: _to!) : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF204D3A))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _from = picked.start; _to = picked.end; });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Batch Performance'),
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined, color: Colors.white),
            onPressed: _pickRange,
          ),
          if (_from != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
              onPressed: () { setState(() { _from = null; _to = null; }); _load(); },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : _rows.isEmpty
              ? const Center(child: Text('No batch data found', style: TextStyle(color: AppTheme.gray)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _rows.length,
                  itemBuilder: (context, i) => _batchCard(_rows[i], i),
                ),
    );
  }

  Widget _batchCard(Map<String, dynamic> r, int rank) {
    final eggs = (r['totalEggs'] as num?)?.toInt() ?? 0;
    final feed = (r['totalFeedKg'] as num?)?.toDouble() ?? 0;
    final deaths = (r['totalDeaths'] as num?)?.toInt() ?? 0;
    final revenue = (r['revenue'] as num?)?.toDouble() ?? 0;
    final fcr = r['fcr']?.toString();
    final days = (r['daysLogged'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: const Color(0xFF204D3A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('#${rank + 1}', style: const TextStyle(color: Color(0xFF204D3A), fontWeight: FontWeight.w800, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(r['batchName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            if (fcr != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF0B322).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text('FCR $fcr kg/dz', style: const TextStyle(color: Color(0xFFC08A00), fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _stat(Icons.egg_outlined, '${Fmt.compact(eggs.toDouble())} eggs', const Color(0xFFF0B322)),
            _stat(Icons.grass_outlined, '${feed.toStringAsFixed(1)} kg feed', const Color(0xFF34C759)),
            _stat(Icons.trending_down_rounded, '$deaths deaths', deaths > 0 ? Colors.red : AppTheme.gray),
            _stat(Icons.currency_rupee_rounded, Fmt.money(revenue), const Color(0xFF007AFF)),
          ]),
          if (days > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('$days days logged', style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
            ),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String text, Color color) {
    return Expanded(child: Row(children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Flexible(child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
    ]));
  }
}
