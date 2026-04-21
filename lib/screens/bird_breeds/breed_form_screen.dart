import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/bird_breed_service.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';

class BreedFormScreen extends StatefulWidget {
  const BreedFormScreen({super.key});
  @override
  State<BreedFormScreen> createState() => _BreedFormScreenState();
}

class _BreedFormScreenState extends State<BreedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = BirdBreedService();
  bool _loading = false; bool _saving = false; String? _editId;
  final _nameCtrl = TextEditingController();
  String _birdType = 'Layer';
  final _eggsCtrl = TextEditingController();
  final _layingAgeCtrl = TextEditingController();
  final List<Map<String, TextEditingController>> _feedSchedule = [];

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments; if (args is String) { _editId = args; _loadEdit(); }
  }); }

  Future<void> _loadEdit() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/bird-breeds/$_editId');
      final d = res.data;
      _nameCtrl.text = d['breedName'] ?? '';
      _birdType = d['birdType'] ?? 'Layer';
      _eggsCtrl.text = '${d['eggsPerYear'] ?? ''}';
      _layingAgeCtrl.text = '${d['eggLayingAgeWeeks'] ?? ''}';
      if (d['feedSchedule'] is List) {
        for (final f in d['feedSchedule']) {
          _feedSchedule.add({
            'fromWeek': TextEditingController(text: '${f['fromWeek'] ?? ''}'),
            'toWeek': TextEditingController(text: '${f['toWeek'] ?? ''}'),
            'feedPerDayKg': TextEditingController(text: '${f['feedPerDayKg'] ?? ''}'),
          });
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _addFeedRow() {
    setState(() { _feedSchedule.add({
      'fromWeek': TextEditingController(), 'toWeek': TextEditingController(), 'feedPerDayKg': TextEditingController(),
    }); });
  }

  void _removeFeedRow(int i) {
    _feedSchedule[i].values.forEach((c) => c.dispose());
    setState(() => _feedSchedule.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'breedName': _nameCtrl.text.trim(), 'birdType': _birdType,
        'eggsPerYear': int.tryParse(_eggsCtrl.text), 'eggLayingAgeWeeks': int.tryParse(_layingAgeCtrl.text),
        'feedSchedule': _feedSchedule.map((f) => {
          'fromWeek': int.tryParse(f['fromWeek']!.text) ?? 0,
          'toWeek': int.tryParse(f['toWeek']!.text) ?? 0,
          'feedPerDayKg': double.tryParse(f['feedPerDayKg']!.text) ?? 0,
        }).toList(),
      };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error)); }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _eggsCtrl.dispose(); _layingAgeCtrl.dispose();
    for (final f in _feedSchedule) f.values.forEach((c) => c.dispose()); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Breed' : 'New Breed')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Breed Name'), TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. BV-380'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Bird Type'), DropdownButtonFormField<String>(value: _birdType, decoration: const InputDecoration(),
            items: C.birdTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _birdType = v ?? 'Layer')),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Eggs/Year'), TextFormField(controller: _eggsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0'))])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Laying Age (wks)'), TextFormField(controller: _layingAgeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0'))])),
        ]),
        const SizedBox(height: 20),
        // Feed schedule
        Row(children: [
          const Text('Feed Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(onPressed: _addFeedRow, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
        ]),
        ..._feedSchedule.asMap().entries.map((e) {
          final i = e.key; final f = e.value;
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(child: TextFormField(controller: f['fromWeek'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'From wk', isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: f['toWeek'], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'To wk', isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: f['feedPerDayKg'], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'g/day', isDense: true))),
              IconButton(icon: const Icon(Icons.close, size: 18, color: AppTheme.error), onPressed: () => _removeFeedRow(i)),
            ]));
        }),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update' : 'Save'))),
      ]))),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
