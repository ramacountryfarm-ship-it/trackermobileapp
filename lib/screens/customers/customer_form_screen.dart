import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/customer_service.dart';
import '../../services/api_client.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key});
  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  bool _loading = false;
  bool _saving = false;
  String? _editId;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'Walk-in';

  static const _types = ['Walk-in', 'Individual', 'Wholesaler', 'Retailer'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) { _editId = args; _loadEdit(); }
    });
  }

  Future<void> _loadEdit() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/customers/$_editId');
      final c = res.data;
      _nameCtrl.text = c['name'] ?? '';
      _phoneCtrl.text = c['phone'] ?? '';
      _addressCtrl.text = c['address'] ?? '';
      _notesCtrl.text = c['notes'] ?? '';
      setState(() => _type = c['type'] ?? 'Walk-in');
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'type': _type,
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_editId != null) {
        await _service.update(_editId!, data);
      } else {
        await _service.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Customer' : 'New Customer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Name *'),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Customer name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _label('Phone'),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'Phone number'),
                  ),
                  const SizedBox(height: 16),
                  _label('Type'),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _type = v ?? 'Walk-in'),
                  ),
                  const SizedBox(height: 16),
                  _label('Address'),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Address (optional)'),
                  ),
                  const SizedBox(height: 16),
                  _label('Notes'),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Additional notes'),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                          : Text(_editId != null ? 'Update Customer' : 'Save Customer'),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)),
  );
}
