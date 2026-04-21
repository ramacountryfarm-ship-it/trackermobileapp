import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/feed_service.dart';
import '../../utils/formatters.dart';

class OwnMixForm extends StatefulWidget {
  const OwnMixForm({super.key});
  @override
  State<OwnMixForm> createState() => _OwnMixFormState();
}

class _OwnMixFormState extends State<OwnMixForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FeedService();
  bool _loading = false; bool _saving = false; String? _editId;
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_Ingredient> _ingredients = [];

  double get _totalWeight => _ingredients.fold(0, (s, i) => s + (double.tryParse(i.qty.text) ?? 0));
  double get _totalCost => _ingredients.fold(0, (s, i) => s + ((double.tryParse(i.qty.text) ?? 0) * (double.tryParse(i.price.text) ?? 0)));
  double get _costPerKg => _totalWeight > 0 ? _totalCost / _totalWeight : 0;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) { _editId = args; _loadEdit(); }
  }); }

  Future<void> _loadEdit() async {
    setState(() => _loading = true);
    try {
      final mix = await _service.getOwnFeedMixById(_editId!);
      _nameCtrl.text = mix['mixName'] ?? '';
      _notesCtrl.text = mix['notes'] ?? '';
      if (mix['ingredients'] is List) {
        for (final ing in mix['ingredients']) {
          _ingredients.add(_Ingredient(
            name: TextEditingController(text: ing['name'] ?? ''),
            qty: TextEditingController(text: '${ing['quantityKg'] ?? ''}'),
            price: TextEditingController(text: '${ing['pricePerKg'] ?? ''}'),
          ));
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_Ingredient(
      name: TextEditingController(), qty: TextEditingController(), price: TextEditingController(),
    )));
  }

  void _removeIngredient(int i) {
    _ingredients[i].dispose();
    setState(() => _ingredients.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one ingredient')));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'mixName': _nameCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'ingredients': _ingredients.map((i) => {
          'name': i.name.text.trim(),
          'quantityKg': double.tryParse(i.qty.text) ?? 0,
          'pricePerKg': double.tryParse(i.price.text) ?? 0,
        }).toList(),
      };
      if (_editId != null) { await _service.updateOwnFeedMix(_editId!, data); } else { await _service.createOwnFeedMix(data); }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _notesCtrl.dispose();
    for (final i in _ingredients) i.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Feed Mix' : 'New Feed Mix')),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Mix Name'), TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Layer Mix #1'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 20),

        // Ingredients section
        Row(children: [
          const Text('Ingredients', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(onPressed: _addIngredient, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
        ]),
        const SizedBox(height: 4),

        ..._ingredients.asMap().entries.map((e) {
          final idx = e.key; final ing = e.value;
          final ingCost = (double.tryParse(ing.qty.text) ?? 0) * (double.tryParse(ing.price.text) ?? 0);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextFormField(controller: ing.name, decoration: const InputDecoration(hintText: 'Ingredient name', isDense: true, fillColor: AppTheme.white),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.close, size: 18, color: AppTheme.error), onPressed: () => _removeIngredient(idx)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextFormField(controller: ing.qty, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'Qty (kg)', isDense: true, fillColor: AppTheme.white), onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: ing.price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: '\u20B9/kg', isDense: true, fillColor: AppTheme.white), onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                if (ingCost > 0) ...[const SizedBox(width: 8),
                  Text(Fmt.currencyDecimal(ingCost), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))],
              ]),
            ]),
          );
        }),

        // Cost summary
        if (_ingredients.isNotEmpty && _totalWeight > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.black, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _summaryRow('Total Weight', Fmt.kg(_totalWeight), AppTheme.white),
              const SizedBox(height: 6),
              _summaryRow('Total Cost', Fmt.currencyDecimal(_totalCost), AppTheme.white),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFF333333))),
              _summaryRow('Cost per kg', Fmt.currencyDecimal(_costPerKg), AppTheme.success),
            ]),
          ),
        ],
        const SizedBox(height: 16),

        _label('Notes'), TextFormField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Optional')),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white)) : Text(_editId != null ? 'Update Mix' : 'Save Mix'))),
      ]))),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)));
}

class _Ingredient {
  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController price;
  _Ingredient({required this.name, required this.qty, required this.price});
  void dispose() { name.dispose(); qty.dispose(); price.dispose(); }
}
