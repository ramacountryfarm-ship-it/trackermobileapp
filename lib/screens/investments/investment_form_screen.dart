import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/investment_service.dart';
import '../../services/api_client.dart';
import '../../services/vendor_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class InvestmentFormScreen extends StatefulWidget {
  const InvestmentFormScreen({super.key});
  @override
  State<InvestmentFormScreen> createState() => _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends State<InvestmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = InvestmentService();
  bool _loading = true; bool _saving = false; String? _editId;
  List<dynamic> _vendors = [];

  DateTime _date = DateTime.now();
  String _category = 'Feed Purchase';
  final _amountCtrl = TextEditingController();
  String? _vendorId;
  final _notesCtrl = TextEditingController();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) _editId = args;
    _loadData();
  }); }

  Future<void> _loadData() async {
    try {
      _vendors = await VendorService().getAll();
      if (_editId != null) {
        final res = await ApiClient().get('/investments/$_editId');
        final d = res.data;
        _date = DateTime.tryParse(d['date'] ?? '') ?? DateTime.now();
        _category = d['category'] ?? 'Feed Purchase';
        _amountCtrl.text = '${d['amount'] ?? ''}';
        _vendorId = d['vendor'] is Map ? d['vendor']['_id'] : d['vendor'];
        _notesCtrl.text = d['notes'] ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = { 'date': Fmt.dateApi(_date), 'category': _category, 'amount': double.tryParse(_amountCtrl.text) ?? 0, 'vendor': _vendorId, 'notes': _notesCtrl.text.trim() };
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error)); }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _amountCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Investment' : 'New Investment')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Date'),
        GestureDetector(onTap: () async {
          final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
              builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!));
          if (d != null) setState(() => _date = d);
        }, child: AbsorbPointer(child: TextFormField(decoration: InputDecoration(hintText: Fmt.dateShort(_date), suffixIcon: const Icon(Icons.calendar_today, size: 18))))),
        const SizedBox(height: 16),
        _label('Category'),
        DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(),
            items: C.investmentCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Feed Purchase')),
        const SizedBox(height: 16),
        _label('Amount (\u20B9)'),
        TextFormField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        _label('Vendor'),
        DropdownButtonFormField<String>(value: _vendorId, isExpanded: true, decoration: const InputDecoration(), hint: const Text('Optional'),
            items: [const DropdownMenuItem<String>(value: null, child: Text('None')), ..._vendors.map((v) => DropdownMenuItem<String>(value: v['_id'], child: Text(v['name'] ?? '')))],
            onChanged: (v) => setState(() => _vendorId = v)),
        const SizedBox(height: 16),
        _label('Notes'),
        TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update' : 'Save'))),
      ]))),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
