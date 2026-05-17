import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _totals = {};
  bool _showPendingOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/reports/customer-report');
      setState(() {
        _rows = List<Map<String, dynamic>>.from(res.data['rows'] ?? []);
        _totals = Map<String, dynamic>.from(res.data['totals'] ?? {});
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _showPendingOnly
        ? _rows.where((r) => (r['pending'] as num? ?? 0) > 0).toList()
        : _rows;

    return Scaffold(
      backgroundColor: AppTheme.surfaceBg,
      appBar: AppBar(
        title: const Text('Customer Report'),
        backgroundColor: AppTheme.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Totals card
                _totalsCard(),
                const SizedBox(height: 12),
                // Filter
                Row(children: [
                  const Text('All Time', style: TextStyle(fontSize: 13, color: AppTheme.gray)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showPendingOnly = !_showPendingOnly),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showPendingOnly ? const Color(0xFFFF3B30).withValues(alpha: 0.1) : AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.filter_list_rounded, size: 14, color: _showPendingOnly ? const Color(0xFFFF3B30) : AppTheme.gray),
                        const SizedBox(width: 4),
                        Text('Pending only', style: TextStyle(fontSize: 12, color: _showPendingOnly ? const Color(0xFFFF3B30) : AppTheme.gray, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                ...visible.asMap().entries.map((e) => _customerCard(e.value, e.key)),
              ],
            ),
    );
  }

  Widget _totalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5856D6), Color(0xFF007AFF)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        _tStat('Total Revenue', _totals['revenue'] ?? 0),
        _tStat('Collected', _totals['received'] ?? 0),
        _tStat('Pending', _totals['pending'] ?? 0, red: true),
        _tStat('Orders', _totals['orders'] ?? 0, isCount: true),
      ]),
    );
  }

  Widget _tStat(String label, num value, {bool red = false, bool isCount = false}) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(
        isCount ? '$value' : '₹${Fmt.compact(value.toDouble())}',
        style: TextStyle(color: red && (value as double) > 0 ? Colors.redAccent[100] : Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ]));
  }

  Widget _customerCard(Map<String, dynamic> r, int rank) {
    final revenue = (r['revenue'] as num?)?.toDouble() ?? 0;
    final pending = (r['pending'] as num?)?.toDouble() ?? 0;
    final orders = (r['orders'] as num?)?.toInt() ?? 0;
    final hasPending = pending > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          border: hasPending ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF5856D6).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Center(child: Text(
              (r['name'] as String? ?? '?')[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF5856D6), fontWeight: FontWeight.w800, fontSize: 16),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('$orders orders • ₹${Fmt.money(revenue)} total', style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          ])),
          if (hasPending)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Pending', style: TextStyle(fontSize: 10, color: Colors.red)),
              Text('₹${Fmt.money(pending)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 14)),
            ])
          else
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34C759), size: 20),
        ]),
      ),
    );
  }
}
