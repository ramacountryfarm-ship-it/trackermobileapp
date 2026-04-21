import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/location_service.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});
  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  final _service = LocationService();
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
      title: const Text('Delete Location'), content: const Text('Delete this location?'),
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
      appBar: AppBar(title: const Text('Locations')),
      floatingActionButton: FloatingActionButton(heroTag: 'fab_locations', backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async { final r = await Navigator.pushNamed(context, '/location-form'); if (r == true) _load(); }, child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : _items.isEmpty ? const Center(child: Text('No locations yet', style: TextStyle(color: AppTheme.gray)))
          : RefreshIndicator(color: AppTheme.black, onRefresh: _load,
              child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final loc = _items[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppTheme.separator.withValues(alpha: 0.6))),
                    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on_outlined, size: 20, color: AppTheme.darkGray)),
                    title: Text(loc['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: loc['address'] != null && loc['address'].toString().isNotEmpty ? Padding(padding: const EdgeInsets.only(top: 2),
                      child: Text(loc['address'], style: const TextStyle(fontSize: 12, color: AppTheme.gray))) : null,
                    trailing: GestureDetector(onTap: () => _delete(loc['_id']), child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
                    onTap: () async { final r = await Navigator.pushNamed(context, '/location-form', arguments: loc['_id']); if (r == true) _load(); },
                  );
                })),
    );
  }
}
