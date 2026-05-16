import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/egg_trading_service.dart';

class FarmerFormScreen extends StatefulWidget {
  const FarmerFormScreen({super.key});
  @override
  State<FarmerFormScreen> createState() => _FarmerFormScreenState();
}

class _FarmerFormScreenState extends State<FarmerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EggTradingService();
  bool _saving = false;
  Map<String, dynamic>? _existing;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _existing = args;
        _nameCtrl.text = args['name'] ?? '';
        _phoneCtrl.text = args['phone'] ?? '';
        _villageCtrl.text = args['village'] ?? '';
        _termsCtrl.text = args['preferredPaymentTerms'] ?? '';
        _notesCtrl.text = args['notes'] ?? '';
        setState(() {});
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'village': _villageCtrl.text.trim(),
      'preferredPaymentTerms': _termsCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_existing != null) {
        await _service.updateFarmer(_existing!['_id'], data);
      } else {
        await _service.createFarmer(data);
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
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _villageCtrl.dispose();
    _termsCtrl.dispose(); _notesCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_existing != null ? 'Edit Farmer' : 'New Farmer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Name *'),
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Farmer name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          _label('Phone'),
          TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone number')),
          const SizedBox(height: 16),
          _label('Village'),
          TextFormField(controller: _villageCtrl, decoration: const InputDecoration(hintText: 'Village / area')),
          const SizedBox(height: 16),
          _label('Payment Terms'),
          TextFormField(controller: _termsCtrl, decoration: const InputDecoration(hintText: 'e.g. Weekly, Cash on delivery')),
          const SizedBox(height: 16),
          _label('Notes'),
          TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                : Text(_existing != null ? 'Update Farmer' : 'Save Farmer'),
          )),
        ])),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)),
  );
}
