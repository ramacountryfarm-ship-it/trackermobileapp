import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vaccination_service.dart';
import '../../utils/formatters.dart';

class VaccinationListScreen extends StatefulWidget {
  const VaccinationListScreen({super.key});
  @override
  State<VaccinationListScreen> createState() => _VaccinationListScreenState();
}

class _VaccinationListScreenState extends State<VaccinationListScreen> {
  final _service = VaccinationService();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _items = await _service.getAll(status: _statusFilter); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggle(String id) async {
    try { await _service.toggleStatus(id); _load(); } catch (_) {}
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete'), content: const Text('Delete this vaccination?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
      ],
    ));
    if (ok == true) { await _service.delete(id); _load(); }
  }

  String _batchName(dynamic b) => b is Map ? (b['batchName'] ?? '-') : '-';

  bool _isOverdue(dynamic item) {
    if (item['completed'] == true) return false;
    final due = DateTime.tryParse(item['dueDate'] ?? '');
    return due != null && due.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccination')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_vaccination',
        backgroundColor: AppTheme.black, foregroundColor: AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () async { final r = await Navigator.pushNamed(context, '/vaccination-form'); if (r == true) _load(); },
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: SizedBox(height: 36,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip('All', _statusFilter == null, () { setState(() => _statusFilter = null); _load(); }),
            _chip('Pending', _statusFilter == 'Pending', () { setState(() => _statusFilter = 'Pending'); _load(); }),
            _chip('Completed', _statusFilter == 'Completed', () { setState(() => _statusFilter = 'Completed'); _load(); }),
          ]),
        )),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
            : _items.isEmpty
                ? const Center(child: Text('No vaccinations scheduled', style: TextStyle(color: AppTheme.gray)))
                : RefreshIndicator(color: AppTheme.black, onRefresh: _load,
                    child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final v = _items[i];
                        final completed = v['completed'] == true || v['status'] == 'Completed';
                        final overdue = _isOverdue(v);
                        return Container(padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: overdue ? AppTheme.error.withValues(alpha: 0.04) : AppTheme.white,
                            border: Border.all(color: overdue ? AppTheme.error.withValues(alpha: 0.3) : AppTheme.separator.withValues(alpha: 0.6)),
                            borderRadius: BorderRadius.circular(14)),
                          child: InkWell(
                            onTap: () async { final r = await Navigator.pushNamed(context, '/vaccination-form', arguments: v['_id']); if (r == true) _load(); },
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(v['vaccineName'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                GestureDetector(onTap: () => _toggle(v['_id']),
                                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: completed ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                    child: Text(completed ? 'Done' : 'Pending',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: completed ? AppTheme.success : AppTheme.warning)),
                                  )),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text(_batchName(v['batch']), style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                                const Spacer(),
                                Icon(Icons.event, size: 14, color: overdue ? AppTheme.error : AppTheme.gray),
                                const SizedBox(width: 4),
                                Text(Fmt.dateShort(DateTime.tryParse(v['dueDate'] ?? '')),
                                    style: TextStyle(fontSize: 12, color: overdue ? AppTheme.error : AppTheme.gray, fontWeight: overdue ? FontWeight.w600 : FontWeight.w400)),
                                const SizedBox(width: 12),
                                GestureDetector(onTap: () => _delete(v['_id']), child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
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
    child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: sel ? AppTheme.black : AppTheme.lightGray, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? AppTheme.white : AppTheme.darkGray)))));
}
