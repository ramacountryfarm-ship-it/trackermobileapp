import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/location_service.dart';
import '../../services/api_client.dart';

class LocationFormScreen extends StatefulWidget {
  const LocationFormScreen({super.key});
  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LocationService();
  bool _loading = false; bool _saving = false; String? _editId;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments; if (args is String) { _editId = args; _loadEdit(); }
  }); }

  Future<void> _loadEdit() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/locations/$_editId');
      final d = res.data; _nameCtrl.text = d['name'] ?? ''; _addressCtrl.text = d['address'] ?? ''; _notesCtrl.text = d['notes'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = { 'name': _nameCtrl.text.trim(), 'address': _addressCtrl.text.trim(), 'notes': _notesCtrl.text.trim() };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error)); }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _addressCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Location' : 'New Location')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Name'), TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Location name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Address'), TextFormField(controller: _addressCtrl, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 16),
        _label('Notes'), TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update' : 'Save'))),
      ]))),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
