import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/sale_service.dart';
import '../../services/customer_service.dart';
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
  final _customerService = CustomerService();
  bool _loading = true;
  bool _saving = false;
  String? _editId;

  List<dynamic> _customers = [];
  String? _customerId;
  DateTime _date = DateTime.now();
  String _productType = 'Eggs';
  String _paymentStatus = 'Paid';
  String _paymentMethod = 'Cash';
  String _orderSource = 'Walk-in';
  DateTime? _dueDate;

  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _amountReceivedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double get _total => (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0);
  bool get _showPaymentFields => _paymentStatus == 'Partial' || _paymentStatus == 'Pending';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _customers = await _customerService.getAll();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _editId = args;
        final res = await ApiClient().get('/sales/$_editId');
        final s = res.data;
        _date = DateTime.tryParse(s['date'] ?? '') ?? DateTime.now();
        _productType = s['productType'] ?? 'Eggs';
        _qtyCtrl.text = '${s['quantity'] ?? ''}';
        _priceCtrl.text = '${s['pricePerUnit'] ?? ''}';
        _customerId = s['customer'] is Map ? s['customer']['_id'] : s['customer'];
        _customerNameCtrl.text = s['customerName'] ?? '';
        _paymentStatus = s['paymentStatus'] ?? 'Paid';
        _paymentMethod = s['paymentMethod'] ?? 'Cash';
        _orderSource = s['orderSource'] ?? 'Walk-in';
        _amountReceivedCtrl.text = '${s['amountReceived'] ?? ''}';
        if (s['paymentDueDate'] != null) _dueDate = DateTime.tryParse(s['paymentDueDate']);
        _notesCtrl.text = s['notes'] ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // If customer selected from master, use their name
    String? customerName = _customerNameCtrl.text.trim();
    String? customerType;
    if (_customerId != null) {
      final cust = _customers.firstWhere((c) => c['_id'] == _customerId, orElse: () => null);
      if (cust != null) {
        customerName = cust['name'];
        customerType = cust['type'];
      }
    }

    final data = {
      'date': Fmt.dateApi(_date),
      'productType': _productType,
      'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
      'pricePerUnit': double.tryParse(_priceCtrl.text) ?? 0,
      'totalAmount': _total,
      'customer': _customerId,
      'customerName': customerName,
      'customerType': customerType ?? 'Walk-in',
      'paymentMethod': _paymentMethod,
      'orderSource': _orderSource,
      'paymentStatus': _paymentStatus,
      'amountReceived': double.tryParse(_amountReceivedCtrl.text) ?? 0,
      if (_dueDate != null) 'paymentDueDate': Fmt.dateApi(_dueDate!),
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_editId != null) { await _service.update(_editId!, data); } else { await _service.create(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose(); _priceCtrl.dispose();
    _customerNameCtrl.dispose(); _amountReceivedCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Sale' : 'New Sale')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                _label('Date'),
                GestureDetector(onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _date,
                      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!));
                  if (d != null) setState(() => _date = d);
                }, child: AbsorbPointer(child: TextFormField(decoration: InputDecoration(
                  hintText: Fmt.dateShort(_date), suffixIcon: const Icon(Icons.calendar_today, size: 18))))),
                const SizedBox(height: 16),

                _label('Product Type'),
                DropdownButtonFormField<String>(value: _productType, decoration: const InputDecoration(),
                    items: C.productTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _productType = v ?? 'Eggs')),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Quantity'),
                    TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Price / Unit (₹)'),
                    TextFormField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '0'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  ])),
                ]),
                if (_total > 0) ...[
                  const SizedBox(height: 10),
                  Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total', style: TextStyle(fontSize: 13, color: AppTheme.gray)),
                      Text(Fmt.currencyDecimal(_total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ])),
                ],
                const SizedBox(height: 16),

                // Customer from master list
                _label('Customer'),
                DropdownButtonFormField<String>(
                  value: _customerId,
                  hint: const Text('Select customer (optional)'),
                  decoration: const InputDecoration(),
                  items: _customers.map((c) => DropdownMenuItem<String>(
                    value: c['_id'] as String,
                    child: Text('${c['name']} (${c['type'] ?? ''})'),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _customerId = v;
                      final cust = _customers.firstWhere((c) => c['_id'] == v, orElse: () => null);
                      if (cust != null) _customerNameCtrl.text = cust['name'] ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Or walk-in name
                _label('Walk-in Name (if not in list)'),
                TextFormField(controller: _customerNameCtrl, decoration: const InputDecoration(hintText: 'Customer name')),
                const SizedBox(height: 16),

                // Order source + payment method side by side
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Order From'),
                    DropdownButtonFormField<String>(
                      value: _orderSource,
                      decoration: const InputDecoration(),
                      items: C.orderSources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _orderSource = v ?? 'Walk-in'),
                    ),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Payment Via'),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(),
                      items: C.paymentMethods.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
                    ),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Payment status
                _label('Payment Status'),
                DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  items: ['Paid', 'Partial', 'Pending'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _paymentStatus = v ?? 'Paid'),
                ),
                if (_showPaymentFields) ...[
                  const SizedBox(height: 16),
                  _label('Amount Received (₹)'),
                  TextFormField(controller: _amountReceivedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0')),
                  const SizedBox(height: 16),
                  _label('Payment Due Date'),
                  GestureDetector(onTap: () async {
                    final d = await showDatePicker(context: context,
                        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(), lastDate: DateTime(2030),
                        builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!));
                    if (d != null) setState(() => _dueDate = d);
                  }, child: AbsorbPointer(child: TextFormField(decoration: InputDecoration(
                    hintText: _dueDate != null ? Fmt.dateShort(_dueDate!) : 'Select due date',
                    suffixIcon: const Icon(Icons.calendar_today, size: 18))))),
                ],
                const SizedBox(height: 16),

                _label('Notes'),
                TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Additional notes')),
                const SizedBox(height: 28),

                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                      : Text(_editId != null ? 'Update Sale' : 'Save Sale'),
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
