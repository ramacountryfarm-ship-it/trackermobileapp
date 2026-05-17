import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class EggTrendScreen extends StatefulWidget {
  const EggTrendScreen({super.key});

  @override
  State<EggTrendScreen> createState() => _EggTrendScreenState();
}

class _EggTrendScreenState extends State<EggTrendScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _daily = [];
  Map<String, dynamic> _totals = {};
  int _avgPerDay = 0;
  DateTime? _from;
  DateTime? _to;
  String _rangeLabel = 'Last 30 days';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = now.subtract(const Duration(days: 29));
    _to = now;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = <String, String>{};
      if (_from != null) params['from'] = Fmt.dateApi(_from!);
      if (_to != null) params['to'] = Fmt.dateApi(_to!);
      final res = await ApiClient().get('/reports/egg-trend', query: params);
      setState(() {
        _daily = List<Map<String, dynamic>>.from(res.data['daily'] ?? []);
        _totals = Map<String, dynamic>.from(res.data['totals'] ?? {});
        _avgPerDay = res.data['avgPerDay'] ?? 0;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _setRange(String label, int days) {
    final now = DateTime.now();
    setState(() {
      _rangeLabel = label;
      _from = now.subtract(Duration(days: days - 1));
      _to = now;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final maxEggs = _daily.fold<int>(0, (m, d) => (d['eggs'] as num? ?? 0) > m ? (d['eggs'] as num).toInt() : m);

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Egg Production'),
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Quick filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _chip('Last 7 days', 7),
                    _chip('Last 30 days', 30),
                    _chip('Last 90 days', 90),
                  ]),
                ),
                const SizedBox(height: 16),
                // Summary card
                _summaryCard(),
                const SizedBox(height: 16),
                // Daily list
                if (_daily.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No data for selected period', style: TextStyle(color: AppTheme.gray)),
                  ))
                else
                  ..._daily.reversed.map((d) => _dayRow(d, maxEggs)),
              ],
            ),
    );
  }

  Widget _chip(String label, int days) {
    final active = _rangeLabel == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _setRange(label, days),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF204D3A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? const Color(0xFF204D3A) : AppTheme.separator),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.darkGray)),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0B322).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0B322).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        _summStat('Total Eggs', '${Fmt.compact((_totals['eggs'] as num?)?.toDouble() ?? 0)}', Icons.egg_outlined),
        _summStat('Avg / Day', '$_avgPerDay', Icons.trending_up_rounded),
        _summStat('Broken', '${_totals['broken'] ?? 0}', Icons.egg_alt_outlined),
        _summStat('Deaths', '${_totals['deaths'] ?? 0}', Icons.trending_down_rounded),
      ]),
    );
  }

  Widget _summStat(String label, String value, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, size: 18, color: const Color(0xFFC08A00)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1C1C1E))),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.gray)),
    ]));
  }

  Widget _dayRow(Map<String, dynamic> d, int maxEggs) {
    final eggs = (d['eggs'] as num?)?.toInt() ?? 0;
    final broken = (d['broken'] as num?)?.toInt() ?? 0;
    final deaths = (d['deaths'] as num?)?.toInt() ?? 0;
    final date = d['_id'] as String? ?? '';
    final progress = maxEggs > 0 ? eggs / maxEggs : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(Fmt.dateDisplay(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
            Row(children: [
              Text('$eggs eggs', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1C1C1E))),
              if (broken > 0) Padding(padding: const EdgeInsets.only(left: 8), child: Text('$broken broken', style: const TextStyle(fontSize: 11, color: Colors.orange))),
              if (deaths > 0) Padding(padding: const EdgeInsets.only(left: 8), child: Text('$deaths deaths', style: const TextStyle(fontSize: 11, color: Colors.red))),
            ]),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.toDouble(),
            backgroundColor: const Color(0xFFF0B322).withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF0B322)),
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ]),
      ),
    );
  }
}
