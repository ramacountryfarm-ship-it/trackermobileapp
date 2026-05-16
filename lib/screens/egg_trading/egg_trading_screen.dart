import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/egg_trading_service.dart';
import '../../utils/formatters.dart';

class EggTradingScreen extends StatefulWidget {
  const EggTradingScreen({super.key});
  @override
  State<EggTradingScreen> createState() => _EggTradingScreenState();
}

class _EggTradingScreenState extends State<EggTradingScreen> with SingleTickerProviderStateMixin {
  final _service = EggTradingService();
  late TabController _tab;
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _farmers = [];
  List<dynamic> _procurement = [];
  List<dynamic> _resale = [];
  List<dynamic> _wastage = [];
  List<dynamic> _pending = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getSummary(),
        _service.getFarmers(),
        _service.getProcurement(),
        _service.getResale(),
        _service.getWastage(),
        _service.getPendingPayments(),
      ]);
      _summary = results[0] as Map<String, dynamic>;
      _farmers = results[1] as List<dynamic>;
      _procurement = results[2] as List<dynamic>;
      _resale = results[3] as List<dynamic>;
      _wastage = results[4] as List<dynamic>;
      _pending = results[5] as List<dynamic>;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _deleteFarmer(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(title: const Text('Delete Farmer'), content: const Text('Delete this farmer?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error)))],
      ));
    if (ok == true) { try { await _service.deleteFarmer(id); _load(); } catch (_) {} }
  }

  Future<void> _deleteProcurement(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(title: const Text('Delete Record'), content: const Text('Delete this procurement?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error)))],
      ));
    if (ok == true) { try { await _service.deleteProcurement(id); _load(); } catch (_) {} }
  }

  Future<void> _deleteResale(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(title: const Text('Delete Record'), content: const Text('Delete this resale?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error)))],
      ));
    if (ok == true) { try { await _service.deleteResale(id); _load(); } catch (_) {} }
  }

  Future<void> _deleteWastage(String id) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(title: const Text('Delete Record'), content: const Text('Delete this wastage record?'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error)))],
      ));
    if (ok == true) { try { await _service.deleteWastage(id); _load(); } catch (_) {} }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Trading'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Farmers'),
            Tab(text: 'Procurement'),
            Tab(text: 'Resale'),
            Tab(text: 'Wastage'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : RefreshIndicator(
              color: AppTheme.black, onRefresh: _load,
              child: TabBarView(controller: _tab, children: [
                _summaryTab(),
                _farmersTab(),
                _procurementTab(),
                _resaleTab(),
                _wastageTab(),
                _pendingTab(),
              ]),
            ),
    );
  }

  // ── Summary Tab ─────────────────────────────────────────────────────────────

  Widget _summaryTab() {
    final stock = (_summary['tradingStock'] as num?)?.toInt() ?? 0;
    final procured = (_summary['totalProcured'] as num?)?.toInt() ?? 0;
    final sold = (_summary['totalSold'] as num?)?.toInt() ?? 0;
    final wasted = (_summary['totalWasted'] as num?)?.toInt() ?? 0;
    final pendingFrom = (_summary['pendingFromCustomers'] as num?)?.toDouble() ?? 0;
    final pendingTo = (_summary['pendingToFarmers'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Stock card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Trading Stock', style: TextStyle(color: Color(0xFF8A8FA0), fontSize: 13)),
            const SizedBox(height: 6),
            Text(Fmt.number(stock), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1)),
            const Text('eggs on hand', style: TextStyle(color: Color(0xFF8A8FA0), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        // Stats row
        Row(children: [
          Expanded(child: _summaryCard('Procured', Fmt.number(procured), Icons.download_rounded, AppTheme.info)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Sold', Fmt.number(sold), Icons.upload_rounded, AppTheme.success)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _summaryCard('Wasted', Fmt.number(wasted), Icons.delete_outline_rounded, AppTheme.error)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Farmers', '${_farmers.length}', Icons.agriculture_outlined, AppTheme.warning)),
        ]),
        const SizedBox(height: 16),
        // Pending payments
        GlassCard(padding: const EdgeInsets.all(16), child: Column(children: [
          _pendingRow('To Receive (Customers)', pendingFrom, AppTheme.success),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppTheme.separator),
          const SizedBox(height: 12),
          _pendingRow('To Pay (Farmers)', pendingTo, AppTheme.error),
        ])),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
        ]),
      ]),
    );
  }

  Widget _pendingRow(String label, double amount, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
      Text(Fmt.currency(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: amount > 0 ? color : AppTheme.gray)),
    ]);
  }

  // ── Farmers Tab ──────────────────────────────────────────────────────────────

  Widget _farmersTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton.icon(
            onPressed: () async {
              final r = await Navigator.pushNamed(context, '/farmer-form');
              if (r == true) _load();
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Farmer'),
          ),
        ]),
      ),
      Expanded(
        child: _farmers.isEmpty
            ? _empty('No farmers yet')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _farmers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final f = _farmers[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 42, height: 42,
                        decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text((f['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (f['phone'] != null) Text(f['phone'], style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                        if (f['village'] != null) Text(f['village'], style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                      ])),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            final r = await Navigator.pushNamed(context, '/farmer-form', arguments: f);
                            if (r == true) _load();
                          } else { _deleteFarmer(f['_id']); }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                        ],
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Procurement Tab ──────────────────────────────────────────────────────────

  Widget _procurementTab() {
    final total = _procurement.fold<int>(0, (s, p) => s + ((p['quantityInPieces'] as num?)?.toInt() ?? 0));
    return Column(children: [
      if (_procurement.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.download_rounded, size: 16, color: AppTheme.info),
            const SizedBox(width: 8),
            Text('Total procured: ${Fmt.number(total)} eggs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.info)),
            const Spacer(),
            ElevatedButton(
              onPressed: () async { final r = await Navigator.pushNamed(context, '/procurement-form', arguments: _farmers); if (r == true) _load(); },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
              child: const Text('+ Add', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      if (_procurement.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              onPressed: () async { final r = await Navigator.pushNamed(context, '/procurement-form', arguments: _farmers); if (r == true) _load(); },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Procurement'),
            ),
          ]),
        ),
      Expanded(
        child: _procurement.isEmpty
            ? _empty('No procurement records yet')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _procurement.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _procurement[i];
                  final farmerName = p['farmer'] is Map ? p['farmer']['name'] : (p['farmer'] ?? '');
                  final qty = (p['quantityInPieces'] as num?)?.toInt() ?? 0;
                  final status = p['paymentStatus'] ?? 'Paid';
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(farmerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _payBadge(status),
                        ]),
                        const SizedBox(height: 4),
                        Text('${Fmt.number(qty)} eggs  •  ${Fmt.currency(p['totalCost'])}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                        Text(Fmt.date(DateTime.tryParse(p['date'] ?? '')),
                            style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                      ])),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') { final r = await Navigator.pushNamed(context, '/procurement-form', arguments: {'record': p, 'farmers': _farmers}); if (r == true) _load(); }
                          else { _deleteProcurement(p['_id']); }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                        ],
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Resale Tab ───────────────────────────────────────────────────────────────

  Widget _resaleTab() {
    final total = _resale.fold<int>(0, (s, r) => s + ((r['quantityInPieces'] as num?)?.toInt() ?? 0));
    final revenue = _resale.fold<double>(0, (s, r) => s + ((r['totalAmount'] as num?)?.toDouble() ?? 0));
    return Column(children: [
      if (_resale.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(child: Text('${Fmt.number(total)} eggs  •  ${Fmt.currency(revenue)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.success))),
            ElevatedButton(
              onPressed: () async { final r = await Navigator.pushNamed(context, '/resale-form'); if (r == true) _load(); },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
              child: const Text('+ Add', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      if (_resale.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            ElevatedButton.icon(
              onPressed: () async { final r = await Navigator.pushNamed(context, '/resale-form'); if (r == true) _load(); },
              icon: const Icon(Icons.add, size: 16), label: const Text('Add Resale'),
            ),
          ]),
        ),
      Expanded(
        child: _resale.isEmpty
            ? _empty('No resale records yet')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _resale.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final r = _resale[i];
                  final custName = r['customer'] is Map ? r['customer']['name'] : (r['customerName'] ?? 'Walk-in');
                  final qty = (r['quantityInPieces'] as num?)?.toInt() ?? 0;
                  final status = r['paymentStatus'] ?? 'Paid';
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(custName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _payBadge(status),
                        ]),
                        const SizedBox(height: 4),
                        Text('${Fmt.number(qty)} eggs  •  ${Fmt.currency(r['totalAmount'])}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                        Text(Fmt.date(DateTime.tryParse(r['date'] ?? '')),
                            style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                      ])),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') { final r2 = await Navigator.pushNamed(context, '/resale-form', arguments: r['_id']); if (r2 == true) _load(); }
                          else { _deleteResale(r['_id']); }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                        ],
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Wastage Tab ──────────────────────────────────────────────────────────────

  Widget _wastageTab() {
    final total = _wastage.fold<int>(0, (s, w) => s + ((w['quantity'] as num?)?.toInt() ?? 0));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          if (total > 0) Expanded(child: Text('Total wasted: ${Fmt.number(total)} eggs',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.error))),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async { final r = await Navigator.pushNamed(context, '/wastage-form'); if (r == true) _load(); },
            icon: const Icon(Icons.add, size: 16), label: const Text('Add Wastage'),
          ),
        ]),
      ),
      Expanded(
        child: _wastage.isEmpty
            ? _empty('No wastage records')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _wastage.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final w = _wastage[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${Fmt.number(w['quantity'])} eggs wasted',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (w['reason'] != null && (w['reason'] as String).isNotEmpty)
                          Text(w['reason'], style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                        Text(Fmt.date(DateTime.tryParse(w['date'] ?? '')),
                            style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
                      ])),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') { final r = await Navigator.pushNamed(context, '/wastage-form', arguments: w); if (r == true) _load(); }
                          else { _deleteWastage(w['_id']); }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                        ],
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  // ── Pending Payments Tab ─────────────────────────────────────────────────────

  Widget _pendingTab() {
    return _pending.isEmpty
        ? _empty('No pending payments')
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: _pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = _pending[i];
              final type = p['type'] ?? '';
              final isCustomer = type == 'customer';
              final name = p['name'] ?? '';
              final amount = (p['pendingAmount'] as num?)?.toDouble() ?? 0;
              return GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: (isCustomer ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(isCustomer ? Icons.person_outline : Icons.agriculture_outlined,
                        color: isCustomer ? AppTheme.success : AppTheme.error, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(isCustomer ? 'Customer owes you' : 'You owe farmer',
                        style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                  ])),
                  Text(Fmt.currency(amount),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: isCustomer ? AppTheme.success : AppTheme.error)),
                ]),
              );
            },
          );
  }

  Widget _payBadge(String status) {
    final color = status == 'Paid' ? AppTheme.success : status == 'Partial' ? AppTheme.warning : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _empty(String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.gray),
    const SizedBox(height: 12),
    Text(msg, style: const TextStyle(color: AppTheme.gray, fontSize: 14)),
  ]));
}
