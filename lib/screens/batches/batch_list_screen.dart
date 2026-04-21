import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/batch_service.dart';
import '../../utils/formatters.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  final _service = BatchService();
  List<dynamic> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _batches = await _service.getAll();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Batch'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(id);
      _load();
    }
  }

  String _getName(dynamic ref, String fallback) {
    if (ref is Map) return ref['name'] ?? ref['breedName'] ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          heroTag: 'fab_batches',
          backgroundColor: AppTheme.black,
          foregroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/batch-form');
            if (result == true) _load();
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : _batches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_outlined, size: 48, color: AppTheme.gray.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No batches yet', style: TextStyle(color: AppTheme.gray)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.black,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _batches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final b = _batches[i];
                      final gender = b['gender'] ?? '';
                      final isMixed = gender == 'Mixed';
                      final birdCount = isMixed
                          ? '${(b['femaleCount'] ?? 0) + (b['maleCount'] ?? 0)}'
                          : '${b['initialBirdCount'] ?? 0}';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, '/batch-form', arguments: b['_id']);
                            if (result == true) _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: name + gender badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b['batchName'] ?? '',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    _genderBadge(gender),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Info row
                                Row(
                                  children: [
                                    _infoChip(Icons.location_on_outlined, _getName(b['location'], '-')),
                                    const SizedBox(width: 12),
                                    _infoChip(Icons.pets_outlined, _getName(b['breed'], '-')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Bottom row: birds + date + delete
                                Row(
                                  children: [
                                    Text(
                                      '$birdCount birds',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    if (isMixed) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${b['femaleCount'] ?? 0}F / ${b['maleCount'] ?? 0}M)',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      Fmt.dateShort(DateTime.tryParse(b['purchaseDate'] ?? '')),
                                      style: const TextStyle(fontSize: 12, color: AppTheme.gray),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _delete(b['_id']),
                                      child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _genderBadge(String gender) {
    Color bg;
    Color fg;
    switch (gender) {
      case 'Female':
        bg = const Color(0xFFFCE4EC);
        fg = const Color(0xFFE91E63);
        break;
      case 'Male':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        break;
      default:
        bg = AppTheme.lightGray;
        fg = AppTheme.darkGray;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(gender, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.gray),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
      ],
    );
  }
}
