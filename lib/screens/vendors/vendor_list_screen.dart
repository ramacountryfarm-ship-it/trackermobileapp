import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});
  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _service = VendorService();
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _items = await _service.getAll(); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Vendor'), content: const Text('Delete this vendor?'),
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
      appBar: AppBar(title: const Text('Vendors')),
      floatingActionButton: FloatingActionButton(heroTag: 'fab_vendors', backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async { final r = await Navigator.pushNamed(context, '/vendor-form'); if (r == true) _load(); }, child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : _items.isEmpty ? const Center(child: Text('No vendors yet', style: TextStyle(color: AppTheme.gray)))
          : RefreshIndicator(color: AppTheme.black, onRefresh: _load,
              child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final v = _items[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppTheme.separator.withValues(alpha: 0.6))),
                    title: Text(v['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: v['vendorType'] != null ? Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(v['vendorType'], style: const TextStyle(fontSize: 12, color: AppTheme.gray))) : null,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (v['phone'] != null) Padding(padding: const EdgeInsets.only(right: 12),
                        child: Text(v['phone'], style: const TextStyle(fontSize: 12, color: AppTheme.gray))),
                      GestureDetector(onTap: () => _delete(v['_id']), child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
                    ]),
                    onTap: () async { final r = await Navigator.pushNamed(context, '/vendor-form', arguments: v['_id']); if (r == true) _load(); },
                  );
                })),
    );
  }
}
