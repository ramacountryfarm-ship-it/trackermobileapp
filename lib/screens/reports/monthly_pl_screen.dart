import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class MonthlyPLScreen extends StatefulWidget {
  const MonthlyPLScreen({super.key});

  @override
  State<MonthlyPLScreen> createState() => _MonthlyPLScreenState();
}

class _MonthlyPLScreenState extends State<MonthlyPLScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  int _months = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/reports/monthly-pl', query: {'months': '$_months'});
      setState(() => _data = res.data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final rows = List<Map<String, dynamic>>.from(_data['rows'] ?? []);
    final totals = Map<String, dynamic>.from(_data['totals'] ?? {});

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Monthly P&L'),
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
            onSelected: (v) { _months = v; _load(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 3, child: Text('Last 3 months')),
              const PopupMenuItem(value: 6, child: Text('Last 6 months')),
              const PopupMenuItem(value: 12, child: Text('Last 12 months')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Summary totals card
                _totalCard(totals),
                const SizedBox(height: 16),
                // Month rows
                ...rows.reversed.map((r) => _monthRow(r)),
              ],
            ),
    );
  }

  Widget _totalCard(Map<String, dynamic> t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF204D3A), Color(0xFF2D6B51)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Last $_months months', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          _totalStat('Revenue', t['revenue'] ?? 0, Colors.white),
          _totalStat('Expenses', t['expenses'] ?? 0, Colors.white70),
          _totalStat('Profit', t['profit'] ?? 0, const Color(0xFFF0B322)),
        ]),
      ]),
    );
  }

  Widget _totalStat(String label, num value, Color color) {
    final isNeg = value < 0;
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      Text(
        '${isNeg ? '-' : ''}₹${Fmt.money(value.abs())}',
        style: TextStyle(color: isNeg ? Colors.redAccent : color, fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ]));
  }

  Widget _monthRow(Map<String, dynamic> r) {
    final revenue = (r['revenue'] as num?)?.toDouble() ?? 0;
    final expenses = (r['expenses'] as num?)?.toDouble() ?? 0;
    final profit = (r['profit'] as num?)?.toDouble() ?? 0;
    final isProfit = profit >= 0;

    final month = r['month'] as String? ?? '';
    final parts = month.split('-');
    final label = parts.length == 2
        ? '${_monthName(int.tryParse(parts[1]) ?? 1)} ${parts[0]}'
        : month;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          border: Border(left: BorderSide(color: isProfit ? const Color(0xFF204D3A) : Colors.red, width: 4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isProfit ? const Color(0xFF204D3A) : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${isProfit ? '+' : '-'}₹${Fmt.money(profit.abs())}',
                style: TextStyle(
                  color: isProfit ? const Color(0xFF204D3A) : Colors.red,
                  fontWeight: FontWeight.w700, fontSize: 13,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _statChip('Revenue', revenue, const Color(0xFF007AFF)),
            const SizedBox(width: 8),
            _statChip('Expenses', expenses, Colors.orange),
          ]),
        ]),
      ),
    );
  }

  Widget _statChip(String label, double value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        Text('₹${Fmt.money(value)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    ));
  }

  String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m.clamp(1, 12)];
  }
}
