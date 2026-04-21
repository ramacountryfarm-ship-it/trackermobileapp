import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/bird_breed_service.dart';

class BreedListScreen extends StatefulWidget {
  const BreedListScreen({super.key});
  @override
  State<BreedListScreen> createState() => _BreedListScreenState();
}

class _BreedListScreenState extends State<BreedListScreen> {
  final _service = BirdBreedService();
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
      title: const Text('Delete Breed'), content: const Text('Delete this breed?'),
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
      appBar: AppBar(title: const Text('Bird Breeds')),
      floatingActionButton: FloatingActionButton(heroTag: 'fab_breeds', backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async { final r = await Navigator.pushNamed(context, '/breed-form'); if (r == true) _load(); }, child: const Icon(Icons.add)),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : _items.isEmpty ? const Center(child: Text('No breeds yet', style: TextStyle(color: AppTheme.gray)))
          : RefreshIndicator(color: AppTheme.black, onRefresh: _load,
              child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final b = _items[i];
                  final type = b['birdType'] ?? '';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppTheme.separator.withValues(alpha: 0.6))),
                    title: Text(b['breedName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(6)),
                        child: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      if (b['eggsPerYear'] != null) ...[const SizedBox(width: 8), Text('${b['eggsPerYear']} eggs/yr', style: const TextStyle(fontSize: 12, color: AppTheme.gray))],
                    ])),
                    trailing: GestureDetector(onTap: () => _delete(b['_id']), child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
                    onTap: () async { final r = await Navigator.pushNamed(context, '/breed-form', arguments: b['_id']); if (r == true) _load(); },
                  );
                })),
    );
  }
}
