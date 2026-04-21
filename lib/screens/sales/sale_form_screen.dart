import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/sale_service.dart';
import '../../services/api_client.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SaleService();
  bool _loading = false;
  bool _saving = false;
  String? _editId;

  DateTime _date = DateTime.now();
  String _productType = 'Eggs';
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _customerType = 'Walk-in';
  final _customerNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double get _total => (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0);

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
      final res = await ApiClient().get('/sales/$_editId');
      final s = res.data;
      _date = DateTime.tryParse(s['date'] ?? '') ?? DateTime.now();
      _productType = s['productType'] ?? 'Eggs';
      _qtyCtrl.text = '${s['quantity'] ?? ''}';
      _priceCtrl.text = '${s['pricePerUnit'] ?? ''}';
      _customerType = s['customerType'] ?? 'Walk-in';
      _customerNameCtrl.text = s['customerName'] ?? '';
      _notesCtrl.text = s['notes'] ?? '';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'date': Fmt.dateApi(_date),
      'productType': _productType,
      'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
      'pricePerUnit': double.tryParse(_priceCtrl.text) ?? 0,
      'totalAmount': _total,
      'customerType': _customerType,
      'customerName': _customerNameCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _qtyCtrl.dispose(); _priceCtrl.dispose(); _customerNameCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Sale' : 'New Sale')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Date'),
          GestureDetector(onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
                builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!));
            if (d != null) setState(() => _date = d);
          }, child: AbsorbPointer(child: TextFormField(decoration: InputDecoration(hintText: Fmt.dateShort(_date), suffixIcon: const Icon(Icons.calendar_today, size: 18))))),
          const SizedBox(height: 16),
          _label('Product Type'),
          DropdownButtonFormField<String>(value: _productType, decoration: const InputDecoration(),
              items: C.productTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _productType = v ?? 'Eggs')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Quantity'), TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0'), onChanged: (_) => setState(() {}), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Price / Unit (\u20B9)'), TextFormField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0'), onChanged: (_) => setState(() {}), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            ])),
          ]),
          if (_total > 0) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total', style: TextStyle(fontSize: 13, color: AppTheme.gray)),
                Text(Fmt.currencyDecimal(_total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ])),
          ],
          const SizedBox(height: 16),
          _label('Customer Type'),
          DropdownButtonFormField<String>(value: _customerType, decoration: const InputDecoration(),
              items: C.customerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _customerType = v ?? 'Walk-in')),
          const SizedBox(height: 16),
          _label('Customer Name'),
          TextFormField(controller: _customerNameCtrl, decoration: const InputDecoration(hintText: 'Optional')),
          const SizedBox(height: 16),
          _label('Notes'),
          TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update' : 'Save Sale'),
          )),
        ])),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}
