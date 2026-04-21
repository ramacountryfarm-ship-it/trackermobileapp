import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/investment_service.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';

class InvestmentListScreen extends StatefulWidget {
  const InvestmentListScreen({super.key});
  @override
  State<InvestmentListScreen> createState() => _InvestmentListScreenState();
}

class _InvestmentListScreenState extends State<InvestmentListScreen> {
  final _service = InvestmentService();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _catFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _items = await _service.getAll(category: _catFilter); } catch (_) {}
    setState(() => _loading = false);
  }

  double get _total => _items.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Investment'), content: const Text('Delete this record?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
      ],
    ));
    if (ok == true) { await _service.delete(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_investments',
        backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async { final r = await Navigator.pushNamed(context, '/investment-form'); if (r == true) _load(); },
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Row(children: [
          Expanded(child: SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip('All', _catFilter == null, () { setState(() => _catFilter = null); _load(); }),
            ...C.investmentCategories.map((c) => _chip(c, _catFilter == c, () { setState(() => _catFilter = c); _load(); })),
          ]))),
          if (!_loading) Text(Fmt.currency(_total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.error)),
        ])),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
            : _items.isEmpty
                ? const Center(child: Text('No investments yet', style: TextStyle(color: AppTheme.gray)))
                : RefreshIndicator(color: AppTheme.black, onRefresh: _load,
                    child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final inv = _items[i];
                        return Container(padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)), borderRadius: BorderRadius.circular(14)),
                          child: InkWell(
                            onTap: () async { final r = await Navigator.pushNamed(context, '/investment-form', arguments: inv['_id']); if (r == true) _load(); },
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(6)),
                                  child: Text(inv['category'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                const SizedBox(height: 6),
                                Text(Fmt.dateShort(DateTime.tryParse(inv['date'] ?? '')), style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(Fmt.currency(inv['amount']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                GestureDetector(onTap: () => _delete(inv['_id']), child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: sel ? AppTheme.black : AppTheme.lightGray, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? AppTheme.white : AppTheme.darkGray)),
    )));
}
