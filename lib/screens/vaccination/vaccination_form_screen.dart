import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vaccination_service.dart';
import '../../services/api_client.dart';
import '../../services/batch_service.dart';
import '../../utils/formatters.dart';

class VaccinationFormScreen extends StatefulWidget {
  const VaccinationFormScreen({super.key});
  @override
  State<VaccinationFormScreen> createState() => _VaccinationFormScreenState();
}

class _VaccinationFormScreenState extends State<VaccinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = VaccinationService();
  bool _loading = true; bool _saving = false; String? _editId;
  List<dynamic> _batches = [];

  String? _batchId;
  final _nameCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now();
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments; if (args is String) _editId = args; _loadData();
  }); }

  Future<void> _loadData() async {
    try {
      _batches = await BatchService().getAll();
      if (_editId != null) {
        final res = await ApiClient().get('/vaccinations/$_editId');
        final d = res.data;
        _batchId = d['batch'] is Map ? d['batch']['_id'] : d['batch'];
        _nameCtrl.text = d['vaccineName'] ?? '';
        _dueDate = DateTime.tryParse(d['dueDate'] ?? '') ?? DateTime.now();
        _notesCtrl.text = d['notes'] ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = { 'batch': _batchId, 'vaccineName': _nameCtrl.text.trim(), 'dueDate': Fmt.dateApi(_dueDate), 'notes': _notesCtrl.text.trim() };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error)); }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Vaccination' : 'Schedule Vaccination')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Batch'),
        DropdownButtonFormField<String>(value: _batchId, isExpanded: true, decoration: const InputDecoration(), hint: const Text('Select batch'),
            items: _batches.map((b) => DropdownMenuItem<String>(value: b['_id'], child: Text(b['batchName'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _batchId = v), validator: (v) => v == null ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Vaccine Name'),
        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Newcastle Disease'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Due Date'),
        GestureDetector(onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!));
          if (d != null) setState(() => _dueDate = d);
        }, child: AbsorbPointer(child: TextFormField(decoration: InputDecoration(hintText: Fmt.dateShort(_dueDate), suffixIcon: const Icon(Icons.calendar_today, size: 18))))),
        const SizedBox(height: 16),
        _label('Notes'),
        TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update' : 'Schedule'))),
      ]))),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
