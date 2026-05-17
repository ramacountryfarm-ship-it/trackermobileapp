import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class OrderSourceReportScreen extends StatefulWidget {
  const OrderSourceReportScreen({super.key});

  @override
  State<OrderSourceReportScreen> createState() => _OrderSourceReportScreenState();
}

class _OrderSourceReportScreenState extends State<OrderSourceReportScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  DateTime? _from;
  DateTime? _to;
  String _rangeLabel = 'All Time';

  final _sourceColors = {
    'Walk-in': const Color(0xFF34C759),
    'WhatsApp': const Color(0xFF25D366),
    'Instagram': const Color(0xFFE1306C),
    'Phone Call': const Color(0xFF007AFF),
    'Agent': const Color(0xFFAF52DE),
    'Other': const Color(0xFFFF9500),
  };

  final _sourceIcons = {
    'Walk-in': Icons.storefront_outlined,
    'WhatsApp': Icons.chat_outlined,
    'Instagram': Icons.photo_camera_outlined,
    'Phone Call': Icons.phone_outlined,
    'Agent': Icons.handshake_outlined,
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
      final res = await ApiClient().get('/reports/order-sources', query: params);
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
    final bySource = List<Map>.from(_data['bySource'] ?? []);
    final totalRevenue = (_data['totalRevenue'] ?? 0).toDouble();
    final totalOrders = _data['totalOrders'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Sources'),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_rangeLabel,
                        style: const TextStyle(fontSize: 12, color: AppTheme.gray, fontWeight: FontWeight.w500)),
                  ),

                  // Summary banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF204D3A), Color(0xFF2D6B51)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Total Revenue', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(Fmt.currency(totalRevenue),
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('Orders', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text('$totalOrders',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.brandHighlight)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  const Text('Where Your Orders Come From',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkGray)),
                  const SizedBox(height: 10),

                  if (bySource.isEmpty)
                    _empty('No sales recorded for this period')
                  else
                    ...bySource.map((s) {
                      final source = s['_id'] as String? ?? 'Other';
                      final revenue = (s['revenue'] ?? 0).toDouble();
                      final count = s['count'] ?? 0;
                      final color = _sourceColors[source] ?? AppTheme.gray;
                      final icon = _sourceIcons[source] ?? Icons.circle_outlined;
                      final pct = totalRevenue > 0 ? revenue / totalRevenue : 0.0;
                      final avgOrder = count > 0 ? revenue / count : 0.0;

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
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(icon, color: color, size: 21),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(source, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('$count order${count == 1 ? '' : 's'} · avg ${Fmt.currency(avgOrder)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(Fmt.currency(revenue),
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

  Widget _empty(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(child: Text(msg, style: const TextStyle(color: AppTheme.gray, fontSize: 14))),
  );
}
