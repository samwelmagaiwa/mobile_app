import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../services/api_service.dart';
import '../../providers/debts_provider.dart';

class DebtRecordsListScreen extends StatefulWidget {
  const DebtRecordsListScreen({super.key, required this.driverId, required this.driverName});
  final String driverId;
  final String driverName;

  @override
  State<DebtRecordsListScreen> createState() => _DebtRecordsListScreenState();
}

class _DebtRecordsListScreenState extends State<DebtRecordsListScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];
  bool _unpaidOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final Map<String, dynamic> res = await _api.getDriverDebtRecords(widget.driverId, unpaidOnly: _unpaidOnly, limit: 500);
      final List<dynamic> items = (res['data']?['debt_records'] as List<dynamic>?) ?? <dynamic>[];
      _records = items.map((dynamic e) => e as Map<String, dynamic>).toList();
    } catch (e) { _error = e.toString(); }
    finally { if (mounted) setState(() { _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ThemeConstants.primaryBlue,
        appBar: ThemeConstants.buildAppBar('Madeni - ${widget.driverName}', actions: <Widget>[
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ]),
        body: SafeArea(
          child: _loading
              ? ThemeConstants.buildLoadingWidget()
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
                  : Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: <Widget>[
                              FilterChip(
                                label: const Text('Bila Kulipwa', style: TextStyle(color: Colors.white)),
                                selected: _unpaidOnly,
                                onSelected: (bool v) { setState(() => _unpaidOnly = v); _load(); },
                                selectedColor: ThemeConstants.primaryOrange.withOpacity(0.2),
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.white.withOpacity(0.08),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            color: Colors.white,
                            backgroundColor: ThemeConstants.primaryBlue,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _records.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (BuildContext context, int i) {
                                final Map<String, dynamic> r = _records[i];
                                final bool isPaid = (r['is_paid'] as bool? ?? false);
                                return ThemeConstants.buildGlassCard(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    title: Text('Tarehe: ${r['formatted_date']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: <Widget>[
                                          _chip(Icons.payments, 'Kiasi: ${r['expected_amount']}'),
                                          if ((r['license_number']?.toString().isNotEmpty ?? false))
                                            _chip(Icons.badge, 'Leseni: ${r['license_number']}'),
                                          _chip(isPaid ? Icons.check_circle : Icons.error_outline, isPaid ? 'Imelipwa' : 'Haijalipwa',
                                              color: isPaid ? ThemeConstants.successGreen : ThemeConstants.errorRed),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                                          onPressed: isPaid ? null : () async {
                                            final bool? changed = await Navigator.push(
                                              context,
                                              MaterialPageRoute<bool>(
                                                builder: (BuildContext context) => _EditDebtRecordScreen(record: r),
                                                fullscreenDialog: true,
                                              ),
                                            );
                                            if (changed == true) { await _load(); Provider.of<DebtsProvider>(context, listen: false).markChanged(); }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
                                          onPressed: isPaid ? null : () => _confirmDelete(r['id'].toString()),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      );

  Widget _chip(IconData icon, String text, {Color color = Colors.white70}) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ]),
      );

  Future<void> _confirmDelete(String id) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: ThemeConstants.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Futa Deni', style: TextStyle(color: Colors.white)),
        content: const Text('Je, una uhakika unataka kufuta deni hili?', style: TextStyle(color: Colors.white70)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hapana', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ndio', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      await _api.deleteDebtRecord(id);
      if (!mounted) return;
      Provider.of<DebtsProvider>(context, listen: false).markChanged();
      _load();
    }
  }
}

class _EditDebtRecordScreen extends StatefulWidget {
  const _EditDebtRecordScreen({required this.record});
  final Map<String, dynamic> record;

  @override
  State<_EditDebtRecordScreen> createState() => _EditDebtRecordScreenState();
}

class _EditDebtRecordScreenState extends State<_EditDebtRecordScreen> {
  final ApiService _api = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _amount;
  late TextEditingController _notes;
  DateTime _date = DateTime.now();
  bool _promised = false;
  DateTime? _promiseDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: (widget.record['expected_amount'] ?? '').toString());
    _notes = TextEditingController(text: (widget.record['notes'] ?? '').toString());
    final String? ds = widget.record['date']?.toString();
    if (ds != null && ds.isNotEmpty) _date = DateTime.tryParse(ds) ?? _date;
    _promised = (widget.record['promised_to_pay'] as bool?) ?? false;
    final String? ps = widget.record['promise_to_pay_at']?.toString();
    if (ps != null && ps.isNotEmpty) _promiseDate = DateTime.tryParse(ps);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ThemeConstants.primaryBlue,
        appBar: ThemeConstants.buildAppBar('Hariri Deni'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                _label('Tarehe ya Deni'),
                const SizedBox(height: 6),
                Row(children: <Widget>[
                  Expanded(child: _value(_fmt(_date))),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event), label: const Text('Chagua'),
                      style: ElevatedButton.styleFrom(backgroundColor: ThemeConstants.primaryOrange, foregroundColor: Colors.white)),
                ]),
                const SizedBox(height: 12),
                _label('Kiasi cha Deni (Tsh)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  style: const TextStyle(color: Colors.white),
                  decoration: _input('Ingiza kiasi'),
                  validator: (String? v) {
                    final double? a = double.tryParse((v ?? '').trim());
                    if (a == null || a <= 0) return 'Weka kiasi sahihi'; return null;
                  },
                ),
                const SizedBox(height: 12),
                _label('Maelezo (hiari)'),
                const SizedBox(height: 6),
                TextFormField(controller: _notes, minLines: 2, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: _input('Andika maelezo...')),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _promised,
                  onChanged: (bool? v) => setState(() => _promised = v ?? false),
                  title: const Text('Je, ameahidi kulipa?', style: TextStyle(color: Colors.white)),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: ThemeConstants.primaryOrange,
                ),
                if (_promised) ...<Widget>[
                  Row(children: <Widget>[
                    Expanded(child: _value(_promiseDate == null ? 'Chagua tarehe' : _fmt(_promiseDate!))),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: _pickPromiseDate, icon: const Icon(Icons.event), label: const Text('Chagua'),
                        style: ElevatedButton.styleFrom(backgroundColor: ThemeConstants.primaryOrange, foregroundColor: Colors.white)),
                  ]),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                    label: Text(_saving ? 'Inahifadhi...' : 'Hifadhi Mabadiliko'),
                    style: ElevatedButton.styleFrom(backgroundColor: ThemeConstants.primaryOrange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (BuildContext context, Widget? child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: ThemeConstants.primaryOrange, surface: ThemeConstants.primaryBlue, onPrimary: Colors.white, onSurface: Colors.white)), child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPromiseDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _promiseDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (BuildContext context, Widget? child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: ThemeConstants.primaryOrange, surface: ThemeConstants.primaryBlue, onPrimary: Colors.white, onSurface: Colors.white)), child: child!),
    );
    if (picked != null) setState(() => _promiseDate = picked);
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _label(String t) => Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12));
  Widget _value(String t) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Text(t, style: const TextStyle(color: Colors.white)));
  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _api.updateDebtRecord(
        debtId: (widget.record['id']).toString(),
        earningDate: _fmt(_date),
        expectedAmount: double.tryParse(_amount.text.trim()),
        notes: _notes.text.trim(),
        promisedToPay: _promised,
        promiseToPayAt: _promiseDate,
      );
      if (!mounted) return;
      Provider.of<DebtsProvider>(context, listen: false).markChanged();
      Navigator.pop(context, true);
    } finally { if (mounted) setState(() => _saving = false); }
  }
}
