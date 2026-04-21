import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/medicine_service.dart';
import '../../services/api_client.dart';

class MedicineFormScreen extends StatefulWidget {
  const MedicineFormScreen({super.key});
  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MedicineService();
  bool _loading = false; bool _saving = false; String? _editId;

  final _nameCtrl = TextEditingController();
  String _type = 'Supplement';
  final _unitCtrl = TextEditingController(text: 'ml');
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  static const _types = ['Supplement', 'Vaccine', 'Antibiotic', 'Dewormer', 'Other'];

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments; if (args is String) { _editId = args; _loadEdit(); }
  }); }

  Future<void> _loadEdit() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/medicines/$_editId');
      final d = res.data;
      _nameCtrl.text = d['name'] ?? '';
      _type = d['type'] ?? 'Supplement';
      _unitCtrl.text = d['unit'] ?? 'ml';
      _priceCtrl.text = '${d['pricePerUnit'] ?? ''}';
      _stockCtrl.text = '${d['stockQuantity'] ?? 0}';
      _notesCtrl.text = d['notes'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = { 'name': _nameCtrl.text.trim(), 'type': _type, 'unit': _unitCtrl.text.trim(),
        'pricePerUnit': double.tryParse(_priceCtrl.text) ?? 0, 'stockQuantity': double.tryParse(_stockCtrl.text) ?? 0, 'notes': _notesCtrl.text.trim() };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error)); }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _unitCtrl.dispose(); _priceCtrl.dispose(); _stockCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Medicine' : 'Add Medicine')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Name'), TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Vitamin C'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Type'), DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _type = v ?? 'Supplement')),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Unit'), TextFormField(controller: _unitCtrl, decoration: const InputDecoration(hintText: 'ml, g, tablet'))])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Price/Unit (\u20B9)'), TextFormField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0'))])),
        ]),
        const SizedBox(height: 16),
        _label('Stock'), TextFormField(controller: _stockCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0')),
        const SizedBox(height: 16),
        _label('Notes'), TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update' : 'Save'))),
      ]))),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
