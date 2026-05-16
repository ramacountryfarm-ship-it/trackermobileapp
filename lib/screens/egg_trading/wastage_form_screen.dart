import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/egg_trading_service.dart';
import '../../utils/formatters.dart';

class WastageFormScreen extends StatefulWidget {
  const WastageFormScreen({super.key});
  @override
  State<WastageFormScreen> createState() => _WastageFormScreenState();
}

class _WastageFormScreenState extends State<WastageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EggTradingService();
  bool _saving = false;
  Map<String, dynamic>? _existing;

  DateTime _date = DateTime.now();
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _existing = args;
        _date = DateTime.tryParse(args['date'] ?? '') ?? DateTime.now();
        _qtyCtrl.text = '${args['quantity'] ?? ''}';
        _reasonCtrl.text = args['reason'] ?? '';
        _notesCtrl.text = args['notes'] ?? '';
        setState(() {});
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'date': Fmt.dateApi(_date),
      'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
      'reason': _reasonCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    };
    try {
      if (_existing != null) { await _service.updateWastage(_existing!['_id'], data); }
      else { await _service.createWastage(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _qtyCtrl.dispose(); _reasonCtrl.dispose(); _notesCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_existing != null ? 'Edit Wastage' : 'New Wastage')),
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
          _label('Quantity (eggs) *'),
          TextFormField(controller: _qtyCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 16),
          _label('Reason'),
          TextFormField(controller: _reasonCtrl, decoration: const InputDecoration(hintText: 'e.g. Broken in transit, Spoiled')),
          const SizedBox(height: 16),
          _label('Notes'),
          TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Additional notes')),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                : Text(_existing != null ? 'Update' : 'Save Wastage'),
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
