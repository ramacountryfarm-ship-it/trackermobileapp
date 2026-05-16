import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/egg_trading_service.dart';
import '../../services/customer_service.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';

class ResaleFormScreen extends StatefulWidget {
  const ResaleFormScreen({super.key});
  @override
  State<ResaleFormScreen> createState() => _ResaleFormScreenState();
}

class _ResaleFormScreenState extends State<ResaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EggTradingService();
  final _customerService = CustomerService();
  bool _loading = true;
  bool _saving = false;
  String? _editId;

  List<dynamic> _customers = [];
  String? _customerId;
  DateTime _date = DateTime.now();
  String _unit = 'pieces';
  String _paymentStatus = 'Paid';

  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _units = ['pieces', 'dozens', 'trays'];
  static const _statuses = ['Paid', 'Partial', 'Pending'];

  double get _total => (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0);

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
        final res = await ApiClient().get('/egg-trading/resale/$args');
        final r = res.data;
        _customerId = r['customer'] is Map ? r['customer']['_id'] : r['customer'];
        _date = DateTime.tryParse(r['date'] ?? '') ?? DateTime.now();
        _unit = r['unit'] ?? 'pieces';
        _paymentStatus = r['paymentStatus'] ?? 'Paid';
        _qtyCtrl.text = '${r['quantity'] ?? ''}';
        _priceCtrl.text = '${r['pricePerUnit'] ?? ''}';
        _amountCtrl.text = '${r['amountReceived'] ?? ''}';
        _addressCtrl.text = r['deliveryAddress'] ?? '';
        _notesCtrl.text = r['notes'] ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'customer': _customerId,
      'date': Fmt.dateApi(_date),
      'unit': _unit,
      'quantity': double.tryParse(_qtyCtrl.text) ?? 0,
      'pricePerUnit': double.tryParse(_priceCtrl.text) ?? 0,
      'paymentStatus': _paymentStatus,
      'amountReceived': double.tryParse(_amountCtrl.text) ?? 0,
      'deliveryAddress': _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_editId != null) { await _service.updateResale(_editId!, data); }
      else { await _service.createResale(data); }
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
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _amountCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Resale' : 'New Resale')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Date'),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _date,
                        firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (ctx, c) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.black)), child: c!));
                    if (d != null) setState(() => _date = d);
                  },
                  child: AbsorbPointer(child: TextFormField(decoration: InputDecoration(
                    hintText: Fmt.dateShort(_date), suffixIcon: const Icon(Icons.calendar_today, size: 18)))),
                ),
                const SizedBox(height: 16),
                _label('Customer'),
                DropdownButtonFormField<String>(
                  value: _customerId,
                  hint: const Text('Select customer (optional)'),
                  items: _customers.map((c) => DropdownMenuItem<String>(value: c['_id'] as String, child: Text(c['name'] ?? ''))).toList(),
                  onChanged: (v) => setState(() => _customerId = v),
                ),
                const SizedBox(height: 16),
                _label('Unit'),
                DropdownButtonFormField<String>(
                  value: _unit,
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u[0].toUpperCase() + u.substring(1)))).toList(),
                  onChanged: (v) => setState(() => _unit = v ?? 'pieces'),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Quantity *'),
                    TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0'),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Price / unit (₹)'),
                    TextFormField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '0'),
                        onChanged: (_) => setState(() {})),
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
                _label('Payment Status'),
                DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _paymentStatus = v ?? 'Paid'),
                ),
                if (_paymentStatus != 'Paid') ...[
                  const SizedBox(height: 16),
                  _label('Amount Received (₹)'),
                  TextFormField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0')),
                ],
                const SizedBox(height: 16),
                _label('Delivery Address'),
                TextFormField(controller: _addressCtrl, decoration: const InputDecoration(hintText: 'Optional')),
                const SizedBox(height: 16),
                _label('Notes'),
                TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional notes')),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                      : Text(_editId != null ? 'Update' : 'Save Resale'),
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
