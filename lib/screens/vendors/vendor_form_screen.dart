import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';

class VendorFormScreen extends StatefulWidget {
  const VendorFormScreen({super.key});
  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = VendorService();
  bool _loading = false; bool _saving = false; String? _editId;

  final _nameCtrl = TextEditingController();
  String? _vendorType;
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments; if (args is String) { _editId = args; _loadEdit(); }
  }); }

  Future<void> _loadEdit() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/vendors/$_editId');
      final d = res.data;
      _nameCtrl.text = d['name'] ?? '';
      _vendorType = d['vendorType'];
      _phoneCtrl.text = d['phone'] ?? '';
      _notesCtrl.text = d['notes'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = { 'name': _nameCtrl.text.trim(), 'vendorType': _vendorType, 'phone': _phoneCtrl.text.trim(), 'notes': _notesCtrl.text.trim() };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error)); }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Vendor' : 'New Vendor')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Name'), TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Vendor name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Type'), DropdownButtonFormField<String>(value: _vendorType, decoration: const InputDecoration(), hint: const Text('Select type'),
            items: C.vendorTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _vendorType = v)),
        const SizedBox(height: 16),
        _label('Phone'), TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Optional')),
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
