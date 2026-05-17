import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/sale_service.dart';
import '../../services/invoice_service.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  final _service = SaleService();
  List<dynamic> _sales = [];
  bool _loading = true;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _sales = await _service.getAll(productType: _typeFilter); } catch (_) {}
    setState(() => _loading = false);
  }

  double get _totalRevenue => _sales.fold(0.0, (s, e) => s + ((e['totalAmount'] as num?)?.toDouble() ?? 0));

  Future<void> _shareInvoice(String id) async {
    final invoiceNum = 'INV-${id.length >= 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing invoice…'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
    final ok = await InvoiceService.shareInvoice(id, invoiceNum);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate invoice'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Sale'), content: const Text('Delete this sale record?'),
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
      appBar: AppBar(title: const Text('Sales')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_sales',
        backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async { final r = await Navigator.pushNamed(context, '/sale-form'); if (r == true) _load(); },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter + total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      _chip('All', _typeFilter == null, () { setState(() => _typeFilter = null); _load(); }),
                      ...C.productTypes.map((t) => _chip(t, _typeFilter == t, () { setState(() => _typeFilter = t); _load(); })),
                    ]),
                  ),
                ),
                if (!_loading) Text(Fmt.currency(_totalRevenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.success)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
                : _sales.isEmpty
                    ? const Center(child: Text('No sales yet', style: TextStyle(color: AppTheme.gray)))
                    : RefreshIndicator(
                        color: AppTheme.black, onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16), itemCount: _sales.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final s = _sales[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: InkWell(
                                onTap: () async { final r = await Navigator.pushNamed(context, '/sale-form', arguments: s['_id']); if (r == true) _load(); },
                                child: Row(
                                  children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        _badge(s['productType'] ?? ''),
                                        const SizedBox(width: 8),
                                        Text('Qty: ${s['quantity'] ?? 0}', style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(Fmt.dateShort(DateTime.tryParse(s['date'] ?? '')), style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(Fmt.currency(s['totalAmount']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        GestureDetector(
                                          onTap: () => _shareInvoice(s['_id']),
                                          child: const Icon(Icons.share_outlined, size: 18, color: AppTheme.brandPrimary),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () => _delete(s['_id']),
                                          child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                        ),
                                      ]),
                                    ]),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(onTap: onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.black : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: selected ? AppTheme.white : AppTheme.darkGray)),
      )),
    );
  }
}
