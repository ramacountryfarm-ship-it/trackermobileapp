import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../services/daily_log_service.dart';
import '../../services/batch_service.dart';
import '../../services/feed_service.dart';
import '../../utils/formatters.dart';

class DailyLogFormScreen extends StatefulWidget {
  const DailyLogFormScreen({super.key});
  @override
  State<DailyLogFormScreen> createState() => _DailyLogFormScreenState();
}

class _Feeding {
  String time; // morning/afternoon/evening/night
  String feedType; // commercial/own_mix
  String? commercialFeedId;
  String? ownFeedMixId;
  TextEditingController qty;

  _Feeding({
    required this.time,
    this.feedType = 'commercial',
    this.commercialFeedId,
    this.ownFeedMixId,
    String qty = '',
  }) : qty = TextEditingController(text: qty);

  void dispose() => qty.dispose();

  Map<String, dynamic> toJson() => {
    'time': time,
    'feedType': feedType,
    'commercialFeed': feedType == 'commercial' ? commercialFeedId : null,
    'ownFeedMix': feedType == 'own_mix' ? ownFeedMixId : null,
    'quantityKg': double.tryParse(qty.text) ?? 0,
  };
}

class _DailyLogFormScreenState extends State<DailyLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DailyLogService();
  bool _loading = true; bool _saving = false; String? _editId;

  List<dynamic> _batches = [];
  List<dynamic> _commercialFeeds = [];
  List<dynamic> _ownMixes = [];

  String? _batchId;
  String _locationName = '';
  DateTime _date = DateTime.now();
  final List<_Feeding> _feedings = [];
  final _eggsCtrl = TextEditingController(text: '0');
  final _brokenCtrl = TextEditingController(text: '0');
  final _deathsCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  static const _times = ['morning', 'afternoon', 'evening', 'night'];
  static const _timeLabels = {
    'morning': 'Morning',
    'afternoon': 'Afternoon',
    'evening': 'Evening',
    'night': 'Night',
  };
  static const _timeIcons = {
    'morning': Icons.wb_sunny_outlined,
    'afternoon': Icons.wb_sunny_rounded,
    'evening': Icons.wb_twilight_rounded,
    'night': Icons.nightlight_round,
  };

  double get _totalFeed => _feedings.fold(0.0, (s, f) => s + (double.tryParse(f.qty.text) ?? 0));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) _editId = args;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        BatchService().getAll(),
        FeedService().getCommercialFeeds(),
        FeedService().getOwnFeedMixes(),
      ]);
      _batches = results[0];
      _commercialFeeds = results[1];
      _ownMixes = results[2];

      if (_editId != null) {
        final res = await ApiClient().get('/daily-logs/$_editId');
        final log = res.data;
        _batchId = log['batch'] is Map ? log['batch']['_id'] : log['batch'];
        _date = DateTime.tryParse(log['date'] ?? '') ?? DateTime.now();
        _eggsCtrl.text = '${log['eggsCollected'] ?? 0}';
        _brokenCtrl.text = '${log['brokenEggs'] ?? 0}';
        _deathsCtrl.text = '${log['birdDeaths'] ?? 0}';
        _notesCtrl.text = log['notes'] ?? '';
        if (log['feedings'] is List) {
          for (final f in log['feedings']) {
            _feedings.add(_Feeding(
              time: f['time'] ?? 'morning',
              feedType: f['feedType'] ?? 'commercial',
              commercialFeedId: f['commercialFeed'] is Map ? f['commercialFeed']['_id'] : f['commercialFeed'],
              ownFeedMixId: f['ownFeedMix'] is Map ? f['ownFeedMix']['_id'] : f['ownFeedMix'],
              qty: '${f['quantityKg'] ?? ''}',
            ));
          }
        }
        _updateLocation();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _updateLocation() {
    if (_batchId == null) { _locationName = ''; return; }
    for (final b in _batches) {
      if (b['_id'] == _batchId) {
        final loc = b['location'];
        _locationName = loc is Map ? (loc['name'] ?? '') : '';
        return;
      }
    }
  }

  void _addFeeding() {
    // Pick next unused time slot
    final usedTimes = _feedings.map((f) => f.time).toSet();
    final available = _times.firstWhere((t) => !usedTimes.contains(t), orElse: () => 'morning');
    setState(() => _feedings.add(_Feeding(time: available)));
  }

  void _removeFeeding(int i) {
    _feedings[i].dispose();
    setState(() => _feedings.removeAt(i));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _date, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'batch': _batchId,
        'date': Fmt.dateApi(_date),
        'feedings': _feedings.map((f) => f.toJson()).toList(),
        'eggsCollected': int.tryParse(_eggsCtrl.text) ?? 0,
        'brokenEggs': int.tryParse(_brokenCtrl.text) ?? 0,
        'birdDeaths': int.tryParse(_deathsCtrl.text) ?? 0,
        'notes': _notesCtrl.text.trim(),
      };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _eggsCtrl.dispose(); _brokenCtrl.dispose(); _deathsCtrl.dispose(); _notesCtrl.dispose();
    for (final f in _feedings) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Log' : 'New Log Entry')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Date
                _label('Date'),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(child: TextFormField(
                    decoration: InputDecoration(hintText: Fmt.dateShort(_date), suffixIcon: const Icon(Icons.calendar_today, size: 18)),
                  )),
                ),
                const SizedBox(height: 16),

                // Batch
                _label('Batch'),
                DropdownButtonFormField<String>(
                  value: _batchId, isExpanded: true,
                  hint: const Text('Select batch'),
                  items: _batches.map((b) => DropdownMenuItem<String>(
                    value: b['_id'] as String?, child: Text(b['batchName'] ?? '', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) { setState(() { _batchId = v; _updateLocation(); }); },
                  validator: (v) => v == null ? 'Required' : null,
                ),
                if (_locationName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.gray),
                      const SizedBox(width: 6),
                      Text(_locationName, style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),

                // Feedings section
                Row(children: [
                  const Text('Feed Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (_totalFeed > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.black, borderRadius: BorderRadius.circular(8)),
                      child: Text('Total: ${Fmt.kg(_totalFeed)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  const Spacer(),
                  if (_feedings.length < 4)
                    TextButton.icon(onPressed: _addFeeding, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
                ]),
                const SizedBox(height: 8),
                if (_feedings.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.gray),
                      SizedBox(width: 8),
                      Expanded(child: Text('Tap "Add" to record a feeding session', style: TextStyle(fontSize: 12, color: AppTheme.gray))),
                    ]),
                  ),
                ..._feedings.asMap().entries.map((e) => _feedingCard(e.key, e.value)),
                const SizedBox(height: 20),

                // Eggs + Broken
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Eggs Collected'),
                    TextFormField(controller: _eggsCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0')),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Broken Eggs'),
                    TextFormField(controller: _brokenCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0')),
                  ])),
                ]),
                const SizedBox(height: 16),
                _label('Bird Deaths'),
                TextFormField(controller: _deathsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0')),
                const SizedBox(height: 16),
                _label('Notes'),
                TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
                const SizedBox(height: 28),

                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                      : Text(_editId != null ? 'Update' : 'Save Entry'),
                )),
              ])),
            ),
    );
  }

  Widget _feedingCard(int idx, _Feeding f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.separator.withValues(alpha: 0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Time picker row
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.black, borderRadius: BorderRadius.circular(10)),
            child: Icon(_timeIcons[f.time], color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: f.time, isExpanded: true,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: _times.map((t) => DropdownMenuItem(value: t, child: Text(_timeLabels[t]!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
              onChanged: (v) => setState(() => f.time = v ?? 'morning'),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(onTap: () => _removeFeeding(idx), child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error)),
        ]),
        const SizedBox(height: 12),

        // Feed type toggle
        Row(children: [
          Expanded(child: _typeBtn(f, 'commercial', 'Commercial', Icons.inventory_2_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _typeBtn(f, 'own_mix', 'Own Mix', Icons.grass_rounded)),
        ]),
        const SizedBox(height: 10),

        // Feed selector
        if (f.feedType == 'commercial')
          DropdownButtonFormField<String>(
            value: f.commercialFeedId, isExpanded: true,
            hint: const Text('Select commercial feed', style: TextStyle(fontSize: 13)),
            decoration: const InputDecoration(isDense: true),
            items: _commercialFeeds.map((c) => DropdownMenuItem<String>(
              value: c['_id'], child: Text(c['feedName'] ?? '', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => f.commercialFeedId = v),
            validator: (v) => v == null ? 'Required' : null,
          )
        else
          DropdownButtonFormField<String>(
            value: f.ownFeedMixId, isExpanded: true,
            hint: const Text('Select own mix', style: TextStyle(fontSize: 13)),
            decoration: const InputDecoration(isDense: true),
            items: _ownMixes.map((m) => DropdownMenuItem<String>(
              value: m['_id'], child: Text(m['mixName'] ?? '', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => f.ownFeedMixId = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
        const SizedBox(height: 10),

        // Quantity
        TextFormField(
          controller: f.qty,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Quantity in kg',
            suffixText: 'kg',
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if ((double.tryParse(v) ?? 0) <= 0) return 'Must be > 0';
            return null;
          },
        ),
      ]),
    );
  }

  Widget _typeBtn(_Feeding f, String type, String label, IconData icon) {
    final selected = f.feedType == type;
    return GestureDetector(
      onTap: () => setState(() => f.feedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.black : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: selected ? Colors.white : AppTheme.gray),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.gray)),
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)),
  );
}
