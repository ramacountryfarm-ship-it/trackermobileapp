import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/daily_log_service.dart';
import '../../services/batch_service.dart';
import '../../utils/formatters.dart';

class DailyLogListScreen extends StatefulWidget {
  const DailyLogListScreen({super.key});

  @override
  State<DailyLogListScreen> createState() => _DailyLogListScreenState();
}

class _DailyLogListScreenState extends State<DailyLogListScreen> {
  final _service = DailyLogService();
  List<dynamic> _logs = [];
  List<dynamic> _batches = [];
  bool _loading = true;
  String? _batchFilter;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getAll(batch: _batchFilter),
        BatchService().getAll(),
      ]);
      _logs = results[0];
      _batches = results[1];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Log'),
        content: const Text('Delete this daily log entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.delete(id);
      _loadAll();
    }
  }

  String _batchName(dynamic batch) {
    if (batch is Map) return batch['batchName'] ?? '-';
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Log')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          heroTag: 'fab_daily_log',
          backgroundColor: AppTheme.black,
          foregroundColor: AppTheme.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/daily-log-form');
            if (result == true) _loadAll();
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        children: [
          // Batch filter
          if (_batches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All', _batchFilter == null, () {
                      setState(() => _batchFilter = null);
                      _loadAll();
                    }),
                    ..._batches.map((b) => _filterChip(
                      b['batchName'] ?? '',
                      _batchFilter == b['_id'],
                      () {
                        setState(() => _batchFilter = b['_id']);
                        _loadAll();
                      },
                    )),
                  ],
                ),
              ),
            ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_calendar_outlined, size: 48, color: AppTheme.gray.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No logs yet', style: TextStyle(color: AppTheme.gray)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.black,
                        onRefresh: _loadAll,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final log = _logs[i];
                            final deaths = (log['birdDeaths'] as num?)?.toInt() ?? 0;
                            final broken = (log['brokenEggs'] as num?)?.toInt() ?? 0;

                            return Dismissible(
                              key: Key(log['_id'] ?? '$i'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete, color: AppTheme.white),
                              ),
                              confirmDismiss: (_) async {
                                _delete(log['_id']);
                                return false;
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.pushNamed(context, '/daily-log-form', arguments: log['_id']);
                                    if (result == true) _loadAll();
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(_batchName(log['batch']),
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          Text(Fmt.dateShort(DateTime.tryParse(log['date'] ?? '')),
                                              style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _metric(Icons.grass, '${Fmt.decimal(log['feedGivenKg'])} kg', AppTheme.darkGray),
                                          const SizedBox(width: 16),
                                          _metric(Icons.egg_outlined, '${log['eggsCollected'] ?? 0}', AppTheme.darkGray),
                                          if (broken > 0) ...[
                                            const SizedBox(width: 16),
                                            _metric(Icons.broken_image_outlined, '$broken', AppTheme.warning),
                                          ],
                                          if (deaths > 0) ...[
                                            const SizedBox(width: 16),
                                            _metric(Icons.dangerous_outlined, '$deaths', AppTheme.error),
                                          ],
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
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.black : AppTheme.lightGray,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppTheme.white : AppTheme.darkGray,
              )),
        ),
      ),
    );
  }
}
