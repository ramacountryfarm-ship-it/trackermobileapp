import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/feed_service.dart';
import '../../services/vendor_service.dart';

class CommercialFeedForm extends StatefulWidget {
  const CommercialFeedForm({super.key});
  @override
  State<CommercialFeedForm> createState() => _CommercialFeedFormState();
}

class _CommercialFeedFormState extends State<CommercialFeedForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FeedService();
  bool _loading = true; bool _saving = false;
  List<dynamic> _vendors = [];

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  String? _vendorId;
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadVendors(); }

  Future<void> _loadVendors() async {
    try { _vendors = await VendorService().getAll(); } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.createCommercialFeed({
        'feedName': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'pricePerKg': double.tryParse(_priceCtrl.text) ?? 0,
        'stockKg': double.tryParse(_stockCtrl.text) ?? 0,
        'vendor': _vendorId,
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _brandCtrl.dispose(); _priceCtrl.dispose(); _stockCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Commercial Feed')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Feed Name'), TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Starter Feed'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Brand'), TextFormField(controller: _brandCtrl, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Price / kg (\u20B9)'), TextFormField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Stock (kg)'), TextFormField(controller: _stockCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0'))])),
        ]),
        const SizedBox(height: 16),
        _label('Vendor'), DropdownButtonFormField<String>(value: _vendorId, isExpanded: true, decoration: const InputDecoration(), hint: const Text('Optional'),
            items: [const DropdownMenuItem<String>(value: null, child: Text('None')), ..._vendors.map((v) => DropdownMenuItem<String>(value: v['_id'], child: Text(v['name'] ?? '')))],
            onChanged: (v) => setState(() => _vendorId = v)),
        const SizedBox(height: 16),
        _label('Notes'), TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : const Text('Save Feed'))),
      ]))),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
