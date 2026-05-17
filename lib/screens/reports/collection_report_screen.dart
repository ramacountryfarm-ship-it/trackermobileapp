import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class CollectionReportScreen extends StatefulWidget {
  const CollectionReportScreen({super.key});

  @override
  State<CollectionReportScreen> createState() => _CollectionReportScreenState();
}

class _CollectionReportScreenState extends State<CollectionReportScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  DateTime? _from;
  DateTime? _to;
  String _rangeLabel = 'All Time';

  final _methodColors = {
    'Cash': const Color(0xFF34C759),
    'UPI': const Color(0xFF007AFF),
    'Bank Transfer': const Color(0xFFAF52DE),
    'Other': const Color(0xFFFF9500),
  };

  final _methodIcons = {
    'Cash': Icons.payments_outlined,
    'UPI': Icons.qr_code_rounded,
    'Bank Transfer': Icons.account_balance_outlined,
    'Other': Icons.more_horiz_rounded,
  };

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
      final res = await ApiClient().get('/reports/collections', query: params);
      setState(() => _data = res.data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: _from ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select start date',
      builder: (ctx, c) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.brandPrimary)),
        child: c!,
      ),
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: from,
      lastDate: now,
      helpText: 'Select end date',
      builder: (ctx, c) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.brandPrimary)),
        child: c!,
      ),
    );
    if (to == null || !mounted) return;
    setState(() {
      _from = from;
      _to = to;
      _rangeLabel = '${Fmt.dateShort(from)} – ${Fmt.dateShort(to)}';
    });
    _load();
  }

  void _clearFilter() {
    setState(() { _from = null; _to = null; _rangeLabel = 'All Time'; });
    _load();
  }

  void _quickFilter(String label, int days) {
    final now = DateTime.now();
    setState(() {
      _from = now.subtract(Duration(days: days - 1));
      _to = now;
      _rangeLabel = label;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final byMethod = List<Map>.from(_data['byMethod'] ?? []);
    final grandTotal = (_data['grandTotal'] ?? 0).toDouble();
    final grandReceived = (_data['grandReceived'] ?? 0).toDouble();
    final pending = grandTotal - grandReceived;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Report'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month_outlined), onPressed: _pickRange),
          if (_from != null)
            IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: _clearFilter),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.brandPrimary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // Quick filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _chip('Today', () => _quickFilter('Today', 1)),
                      _chip('This Week', () => _quickFilter('This Week', 7)),
                      _chip('This Month', () => _quickFilter('This Month', 30)),
                      _chip('Custom', _pickRange),
                      if (_from != null)
                        _chip('All Time', _clearFilter, active: false),
                    ]),
                  ),
                  const SizedBox(height: 4),

                  // Range label
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_rangeLabel,
                        style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w500)),
                  ),

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      const Text('Total Sales', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(Fmt.currency(grandTotal),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _summaryChip('Collected', Fmt.currency(grandReceived), const Color(0xFF34C759))),
                        const SizedBox(width: 10),
                        Expanded(child: _summaryChip('Pending', Fmt.currency(pending), pending > 0 ? const Color(0xFFFF9500) : Colors.white70)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // By payment method
                  const Text('By Payment Method',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
                  const SizedBox(height: 10),

                  if (byMethod.isEmpty)
                    _empty('No sales recorded for this period')
                  else
                    ...byMethod.map((m) {
                      final method = m['_id'] as String? ?? 'Other';
                      final amount = (m['totalAmount'] ?? 0).toDouble();
                      final count = m['count'] ?? 0;
                      final color = _methodColors[method] ?? AppTheme.gray;
                      final icon = _methodIcons[method] ?? Icons.paid_outlined;
                      final pct = grandTotal > 0 ? amount / grandTotal : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.separator.withValues(alpha: 0.5)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(method, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('$count sale${count == 1 ? '' : 's'}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(Fmt.currency(amount),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              Text('${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                            ]),
                          ]),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 6,
                            ),
                          ),
                        ]),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _chip(String label, VoidCallback onTap, {bool active = true}) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active && _rangeLabel == label ? AppTheme.brandPrimary : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active && _rangeLabel == label ? Colors.white : AppTheme.darkGray,
          )),
    ),
  );

  Widget _summaryChip(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  Widget _empty(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text(msg, style: const TextStyle(color: AppTheme.gray, fontSize: 14))),
  );
}
