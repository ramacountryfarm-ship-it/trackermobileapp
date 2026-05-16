import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/egg_trading_service.dart';
import '../../utils/formatters.dart';

class ProcurementFormScreen extends StatefulWidget {
  const ProcurementFormScreen({super.key});
  @override
  State<ProcurementFormScreen> createState() => _ProcurementFormScreenState();
}

class _ProcurementFormScreenState extends State<ProcurementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EggTradingService();
  bool _saving = false;

  List<dynamic> _farmers = [];
  String? _farmerId;
  String? _editId;
  DateTime _date = DateTime.now();
  String _unit = 'pieces';
  String _paymentStatus = 'Paid';

  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _brokenCtrl = TextEditingController(text: '0');
  final _qualityCtrl = TextEditingController(text: '5');
  final _amountPaidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const _units = ['pieces', 'dozens', 'trays'];
  static const _statuses = ['Paid', 'Partial', 'Pending'];

  double get _total => (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List) {
        _farmers = args;
      } else if (args is Map<String, dynamic>) {
        _farmers = (args['farmers'] as List?) ?? [];
        final rec = args['record'] as Map<String, dynamic>?;
        if (rec != null) {
          _editId = rec['_id'];
          _farmerId = rec['farmer'] is Map ? rec['farmer']['_id'] : rec['farmer'];
          _date = DateTime.tryParse(rec['date'] ?? '') ?? DateTime.now();
          _unit = rec['unit'] ?? 'pieces';
          _paymentStatus = rec['paymentStatus'] ?? 'Paid';
          _qtyCtrl.text = '${rec['quantity'] ?? ''}';
          _priceCtrl.text = '${rec['pricePerUnit'] ?? ''}';
          _brokenCtrl.text = '${rec['brokenOnArrival'] ?? 0}';
          _qualityCtrl.text = '${rec['qualityRating'] ?? 5}';
          _amountPaidCtrl.text = '${rec['amountPaid'] ?? ''}';
          _notesCtrl.text = rec['notes'] ?? '';
        }
      }
      setState(() {});
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'farmer': _farmerId,
      'date': Fmt.dateApi(_date),
      'unit': _unit,
      'quantity': double.tryParse(_qtyCtrl.text) ?? 0,
      'pricePerUnit': double.tryParse(_priceCtrl.text) ?? 0,
      'brokenOnArrival': int.tryParse(_brokenCtrl.text) ?? 0,
      'qualityRating': int.tryParse(_qualityCtrl.text) ?? 5,
      'paymentStatus': _paymentStatus,
      'amountPaid': double.tryParse(_amountPaidCtrl.text) ?? 0,
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_editId != null) { await _service.updateProcurement(_editId!, data); }
      else { await _service.createProcurement(data); }
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
    _qtyCtrl.dispose(); _priceCtrl.dispose(); _brokenCtrl.dispose();
    _qualityCtrl.dispose(); _amountPaidCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Procurement' : 'New Procurement')),
      body: SingleChildScrollView(
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
          _label('Farmer *'),
          DropdownButtonFormField<String>(
            value: _farmerId,
            hint: const Text('Select farmer'),
            items: _farmers.map((f) => DropdownMenuItem<String>(value: f['_id'] as String, child: Text(f['name'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _farmerId = v),
            validator: (v) => v == null ? 'Select a farmer' : null,
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
                const Text('Total Cost', style: TextStyle(fontSize: 13, color: AppTheme.gray)),
                Text(Fmt.currencyDecimal(_total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ])),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Broken on Arrival'),
              TextFormField(controller: _brokenCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '0')),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Quality (1-5)'),
              TextFormField(controller: _qualityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '5')),
            ])),
          ]),
          const SizedBox(height: 16),
          _label('Payment Status'),
          DropdownButtonFormField<String>(
            value: _paymentStatus,
            items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _paymentStatus = v ?? 'Paid'),
          ),
          if (_paymentStatus != 'Paid') ...[
            const SizedBox(height: 16),
            _label('Amount Paid (₹)'),
            TextFormField(controller: _amountPaidCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0')),
          ],
          const SizedBox(height: 16),
          _label('Notes'),
          TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional notes')),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                : Text(_editId != null ? 'Update' : 'Save Procurement'),
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
