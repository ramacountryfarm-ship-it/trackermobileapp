import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = ApiClient();
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/analytics');
      _data = res.data is Map ? res.data as Map<String, dynamic> : {};
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final overview = _data['overview'] as Map<String, dynamic>? ?? {};
    final insights = _data['insights'] as List? ?? [];
    final monthlyTrend = _data['monthlyTrend'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : RefreshIndicator(color: AppTheme.black, onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        // Overview cards
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2,
          children: [
            _overviewCard('Revenue', Fmt.currency(overview['totalRevenue']), AppTheme.success),
            _overviewCard('Expenses', Fmt.currency(overview['totalExpenses']), AppTheme.error),
            _overviewCard('Net Profit', Fmt.currency(overview['netProfit']),
                ((overview['netProfit'] as num?) ?? 0) >= 0 ? AppTheme.success : AppTheme.error),
            _overviewCard('Birds', Fmt.number(overview['totalBirds']), AppTheme.darkGray),
          ]),
        const SizedBox(height: 20),

        // Monthly trend chart
        if (monthlyTrend.isNotEmpty) ...[
          const Text('Monthly Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: BarChart(BarChartData(
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= monthlyTrend.length) return const SizedBox();
                  return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(monthlyTrend[i]['label'] ?? '', style: const TextStyle(fontSize: 10, color: AppTheme.gray)));
                })),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: monthlyTrend.asMap().entries.map((e) {
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: (e.value['revenue'] as num?)?.toDouble() ?? 0, color: AppTheme.success, width: 8, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: (e.value['expenses'] as num?)?.toDouble() ?? 0, color: AppTheme.error.withValues(alpha: 0.6), width: 8, borderRadius: BorderRadius.circular(4)),
              ]);
            }).toList(),
          ))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend(AppTheme.success, 'Revenue'), const SizedBox(width: 16), _legend(AppTheme.error.withValues(alpha: 0.6), 'Expenses'),
          ]),
          const SizedBox(height: 20),
        ],

        // Insights
        if (insights.isNotEmpty) ...[
          const Text('Smart Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...insights.map((insight) {
            Color color;
            switch (insight['type']) {
              case 'success': color = AppTheme.success; break;
              case 'warning': color = AppTheme.warning; break;
              case 'critical': color = AppTheme.error; break;
              default: color = AppTheme.info;
            }
            return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(insight['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                if (insight['message'] != null) Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(insight['message'], style: const TextStyle(fontSize: 12, color: AppTheme.darkGray))),
              ]));
          }),
        ],
      ])),
    );
  }

  Widget _overviewCard(String label, String value, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
      color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
      ]));
  }

  Widget _legend(Color c, String t) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
  ]);
}
