import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/customer_service.dart';
import '../../utils/formatters.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _service = CustomerService();
  List<dynamic> _customers = [];
  bool _loading = true;
  String _filterType = '';
  final _searchCtrl = TextEditingController();

  static const _types = ['', 'Walk-in', 'Individual', 'Wholesaler', 'Retailer'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _customers = await _service.getAll(
        type: _filterType.isEmpty ? null : _filterType,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (ok == true) {
      try { await _service.delete(id); _load(); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () async {
            final res = await Navigator.pushNamed(context, '/customer-form');
            if (res == true) _load();
          }),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or phone…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _load(); })
                  : null,
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: _types.map((t) {
              final active = _filterType == t;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(t.isEmpty ? 'All' : t),
                  selected: active,
                  onSelected: (_) { setState(() => _filterType = t); _load(); },
                  selectedColor: AppTheme.black,
                  labelStyle: TextStyle(color: active ? AppTheme.white : AppTheme.darkGray, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
              : _customers.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_outline, size: 52, color: AppTheme.gray),
                      const SizedBox(height: 12),
                      Text('No customers found', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.gray)),
                    ]))
                  : RefreshIndicator(
                      color: AppTheme.black,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _customerCard(_customers[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _customerCard(dynamic c) {
    final type = c['type'] ?? 'Walk-in';
    final totalPurchases = (c['totalPurchases'] as num?)?.toDouble() ?? 0;
    final pendingAmount = (c['pendingAmount'] as num?)?.toDouble() ?? 0;
    final hasPending = pendingAmount > 0;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(
            (c['name'] ?? '?')[0].toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
            _typeBadge(type),
          ]),
          const SizedBox(height: 2),
          if (c['phone'] != null)
            Text(c['phone'], style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          const SizedBox(height: 6),
          Row(children: [
            _infoChip('Purchases', Fmt.currency(totalPurchases), AppTheme.success),
            if (hasPending) ...[
              const SizedBox(width: 8),
              _infoChip('Pending', Fmt.currency(pendingAmount), AppTheme.error),
            ],
          ]),
        ])),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              final res = await Navigator.pushNamed(context, '/customer-form', arguments: c['_id']);
              if (res == true) _load();
            } else if (v == 'delete') {
              _delete(c['_id'], c['name'] ?? '');
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
          ],
        ),
      ]),
    );
  }

  Widget _typeBadge(String type) {
    final color = type == 'Wholesaler' ? const Color(0xFF007AFF)
        : type == 'Retailer' ? const Color(0xFF9B59B6)
        : type == 'Individual' ? AppTheme.success
        : AppTheme.gray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(type, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$label: ', style: const TextStyle(fontSize: 11, color: AppTheme.gray)),
      Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
