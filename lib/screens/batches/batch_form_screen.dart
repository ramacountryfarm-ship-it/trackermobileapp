import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/batch_service.dart';
import '../../services/location_service.dart';
import '../../services/bird_breed_service.dart';
import '../../services/vendor_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class BatchFormScreen extends StatefulWidget {
  const BatchFormScreen({super.key});

  @override
  State<BatchFormScreen> createState() => _BatchFormScreenState();
}

class _BatchFormScreenState extends State<BatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchService = BatchService();

  bool _loading = true;
  bool _saving = false;
  String? _editId;

  // Dropdown data
  List<dynamic> _locations = [];
  List<dynamic> _breeds = [];
  List<dynamic> _vendors = [];

  // Form fields
  final _nameCtrl = TextEditingController();
  String? _locationId;
  String? _breedId;
  String _gender = 'Female';
  DateTime _purchaseDate = DateTime.now();
  String? _vendorId;
  final _notesCtrl = TextEditingController();

  // Non-mixed fields
  final _countCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  // Mixed fields
  final _femaleCountCtrl = TextEditingController();
  final _femaleCostCtrl = TextEditingController();
  final _maleCountCtrl = TextEditingController();
  final _maleCostCtrl = TextEditingController();

  bool get _isMixed => _gender == 'Mixed';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) _editId = args;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        LocationService().getAll(),
        BirdBreedService().getAll(),
        VendorService().getAll(),
      ]);
      _locations = results[0];
      _breeds = results[1];
      _vendors = results[2];

      if (_editId != null) {
        final b = await _batchService.getById(_editId!);
        _nameCtrl.text = b['batchName'] ?? '';
        _locationId = b['location'] is Map ? b['location']['_id'] : b['location'];
        _breedId = b['breed'] is Map ? b['breed']['_id'] : b['breed'];
        _gender = b['gender'] ?? 'Female';
        _purchaseDate = DateTime.tryParse(b['purchaseDate'] ?? '') ?? DateTime.now();
        _vendorId = b['vendor'] is Map ? b['vendor']['_id'] : b['vendor'];
        _notesCtrl.text = b['notes'] ?? '';

        if (_isMixed) {
          _femaleCountCtrl.text = '${b['femaleCount'] ?? ''}';
          _femaleCostCtrl.text = '${b['femaleCostPerBird'] ?? ''}';
          _maleCountCtrl.text = '${b['maleCount'] ?? ''}';
          _maleCostCtrl.text = '${b['maleCostPerBird'] ?? ''}';
        } else {
          _countCtrl.text = '${b['initialBirdCount'] ?? ''}';
          _costCtrl.text = '${b['birdPurchasePrice'] ?? b['costPerBird'] ?? ''}';
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.black),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _purchaseDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'batchName': _nameCtrl.text.trim(),
      'locationId': _locationId,
      'breedId': _breedId,
      'gender': _gender,
      'purchaseDate': Fmt.dateApi(_purchaseDate),
      'vendorId': _vendorId,
      'notes': _notesCtrl.text.trim(),
      'livestockType': 'poultry',
    };

    if (_isMixed) {
      data['femaleCount'] = int.tryParse(_femaleCountCtrl.text) ?? 0;
      data['femaleCostPerBird'] = double.tryParse(_femaleCostCtrl.text) ?? 0;
      data['maleCount'] = int.tryParse(_maleCountCtrl.text) ?? 0;
      data['maleCostPerBird'] = double.tryParse(_maleCostCtrl.text) ?? 0;
      data['initialCount'] = data['femaleCount'] + data['maleCount'];
    } else {
      data['initialCount'] = int.tryParse(_countCtrl.text) ?? 0;
      data['costPerBird'] = double.tryParse(_costCtrl.text) ?? 0;
    }

    try {
      if (_editId != null) {
        await _batchService.update(_editId!, data);
      } else {
        await _batchService.create(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _countCtrl.dispose();
    _costCtrl.dispose();
    _femaleCountCtrl.dispose();
    _femaleCostCtrl.dispose();
    _maleCountCtrl.dispose();
    _maleCostCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editId != null ? 'Edit Batch' : 'New Batch')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch name
                    _label('Batch Name'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. Batch A-2024'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Location + Breed row
                    Row(
                      children: [
                        Expanded(child: _buildDropdown('Location', _locations, _locationId, 'name',
                            (v) => setState(() => _locationId = v), true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdown('Breed', _breeds, _breedId, 'breedName',
                            (v) => setState(() => _breedId = v), true)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender + Date row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Gender'),
                              DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: const InputDecoration(),
                                items: C.genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (v) => setState(() => _gender = v ?? 'Female'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Purchase Date'),
                              GestureDetector(
                                onTap: _pickDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      hintText: Fmt.dateShort(_purchaseDate),
                                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Vendor
                    _buildDropdown('Vendor (optional)', _vendors, _vendorId, 'name',
                        (v) => setState(() => _vendorId = v), false),
                    const SizedBox(height: 20),

                    // Bird count + cost section
                    if (!_isMixed) _buildSingleCount(),
                    if (_isMixed) _buildMixedCount(),
                    const SizedBox(height: 16),

                    // Notes
                    _label('Notes'),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Additional notes'),
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                            : Text(_editId != null ? 'Update Batch' : 'Create Batch'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Single gender: count + cost
  Widget _buildSingleCount() {
    final count = int.tryParse(_countCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    final total = count * cost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Bird Count'),
                  TextFormField(
                    controller: _countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '0'),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if ((int.tryParse(v) ?? 0) < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Cost / Bird'),
                  TextFormField(
                    controller: _costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: '0'),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          _summaryRow('Total Cost', Fmt.currencyDecimal(total)),
        ],
      ],
    );
  }

  // Mixed gender: female + male sections with grand total
  Widget _buildMixedCount() {
    final fc = int.tryParse(_femaleCountCtrl.text) ?? 0;
    final fCost = double.tryParse(_femaleCostCtrl.text) ?? 0;
    final mc = int.tryParse(_maleCountCtrl.text) ?? 0;
    final mCost = double.tryParse(_maleCostCtrl.text) ?? 0;
    final fTotal = fc * fCost;
    final mTotal = mc * mCost;
    final grandTotal = fTotal + mTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Female section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE4EC).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCE4EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Female Birds', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (fTotal > 0)
                    Text(Fmt.currencyDecimal(fTotal),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE91E63))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _femaleCountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Count', isDense: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _femaleCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'Cost/bird', isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Male section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3F2FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Male Birds', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (mTotal > 0)
                    Text(Fmt.currencyDecimal(mTotal),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maleCountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Count', isDense: true),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _maleCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'Cost/bird', isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Grand total summary
        if (grandTotal > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _summaryRow('Total Birds', '${fc + mc}'),
                const SizedBox(height: 6),
                _summaryRow('Female Cost', Fmt.currencyDecimal(fTotal)),
                const SizedBox(height: 6),
                _summaryRow('Male Cost', Fmt.currencyDecimal(mTotal)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(Fmt.currencyDecimal(grandTotal),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.darkGray)),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, String nameKey,
      ValueChanged<String?> onChanged, bool required) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(),
          hint: Text('Select', style: TextStyle(color: AppTheme.gray.withValues(alpha: 0.7), fontSize: 14)),
          items: [
            if (!required) const DropdownMenuItem<String>(value: null, child: Text('None')),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: item['_id'] as String?,
                  child: Text(item[nameKey] ?? '', style: const TextStyle(fontSize: 14)),
                )),
          ],
          onChanged: onChanged,
          validator: required ? (v) => v == null ? 'Required' : null : null,
        ),
      ],
    );
  }
}
