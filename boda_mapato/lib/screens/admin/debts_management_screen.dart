import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../../models/driver.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/debts_provider.dart';
import 'debt_records_list_screen.dart';

enum MonthFilter { mweziHuu, mweziUliopita, mwakaHuu, zote }

class DebtsManagementScreen extends StatefulWidget {
  const DebtsManagementScreen({super.key});

  @override
  State<DebtsManagementScreen> createState() => _DebtsManagementScreenState();
}

class _DebtsManagementScreenState extends State<DebtsManagementScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Driver> _drivers = <Driver>[];
  List<Driver> _filtered = <Driver>[];
  int _tabIndex = 0; // 0: Wanaodaiwa, 1: Wasiodaiwa, 2: Zote

  late final TabController _tabController;

  bool _listeningProvider = false;

  // Month/Year quick filter
  MonthFilter _monthFilter = MonthFilter.zote;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabIndex != _tabController.index) {
        setState(() => _tabIndex = _tabController.index);
        _applyFilter();
      }
    });
    _search.addListener(_applyFilter);
    _loadDrivers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listeningProvider) {
      _listeningProvider = true;
      final DebtsProvider dp = Provider.of<DebtsProvider>(context, listen: false);
      dp.addListener(() {
        if (dp.shouldRefresh) {
          _loadDrivers();
          dp.consume();
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final Map<String, dynamic> res = await _api.getDebtDrivers(page: 1, limit: 200);
      final List<dynamic> list = (res['data']?['drivers'] as List<dynamic>?) ?? <dynamic>[];
      _drivers = list
          .map((dynamic j) => Driver.fromJson(j as Map<String, dynamic>))
          .toList();
      _applyFilter();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final String q = _search.text.toLowerCase();
    List<Driver> base = _drivers;

    // Tab filters
    if (_tabIndex == 0) {
      base = base.where((Driver d) => d.totalDebt > 0).toList();
    } else if (_tabIndex == 1) {
      base = base.where((Driver d) => d.totalDebt <= 0).toList();
    }

    // Month/Year quick filter (applies to debtors)
    base = base.where((Driver d) {
      if (d.totalDebt <= 0) return true; // do not exclude non-debt in non-debt tab
      if (_monthFilter == MonthFilter.zote) return true;
      if (d.dueDates.isEmpty) return false;
      final String next = d.dueDates.first;
      DateTime? nd;
      try { nd = DateTime.tryParse(next); } catch (_) {}
      if (nd == null) return false;
      final DateTime now = DateTime.now();
      switch (_monthFilter) {
        case MonthFilter.mweziHuu:
          return nd.year == now.year && nd.month == now.month;
        case MonthFilter.mweziUliopita:
          final DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
          return nd.year == lastMonth.year && nd.month == lastMonth.month;
        case MonthFilter.mwakaHuu:
          return nd.year == now.year;
        case MonthFilter.zote:
          return true;
      }
    }).toList();

    // Search text filter
    _filtered = base.where((Driver d) {
      return d.name.toLowerCase().contains(q) ||
          d.phone.toLowerCase().contains(q) ||
          (d.vehicleNumber ?? '').toLowerCase().contains(q) ||
          (d.email).toLowerCase().contains(q);
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar('Rekodi Madeni', actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDrivers,
        ),
      ]),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: ThemeConstants.primaryBlue),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _search,
                        style: const TextStyle(color: ThemeConstants.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tafuta dereva kwa jina, simu au namba ya gari',
                          hintStyle: const TextStyle(color: ThemeConstants.textSecondary),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _openCreateForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Rekodi Deni'),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: ThemeConstants.primaryOrange,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const <Widget>[
                    Tab(text: 'Wanaodaiwa'),
                    Tab(text: 'Wasiodaiwa'),
                    Tab(text: 'Zote'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Month/Year quick filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    _buildFilterChip('Mwezi Huu', MonthFilter.mweziHuu),
                    _buildFilterChip('Uliopita', MonthFilter.mweziUliopita),
                    _buildFilterChip('Mwaka Huu', MonthFilter.mwakaHuu),
                    _buildFilterChip('Zote', MonthFilter.zote),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? ThemeConstants.buildLoadingWidget()
                    : _error != null
                        ? _buildError()
                        : _buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(_error ?? 'Hitilafu isiyojulikana',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDrivers,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Jaribu tena'),
            ),
          ],
        ),
      );

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.search_off, color: Colors.white54, size: 40),
            SizedBox(height: 8),
            Text('Hakuna matokeo', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    // Two-column grid layout to avoid overflow and improve readability
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: ThemeConstants.primaryBlue,
      onRefresh: _loadDrivers,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Provide enough vertical space for larger fonts and two rows of info boxes
          mainAxisExtent: 230,
        ),
        itemBuilder: (BuildContext context, int i) {
          final Driver d = _filtered[i];
          return _buildDriverTile(d);
        },
      ),
    );
  }

  Widget _buildDriverTile(Driver d) {
    final bool hasDebt = d.totalDebt > 0;
    return ThemeConstants.buildGlassCard(
      onTap: () => _openDriverRecords(d),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: ThemeConstants.cardColor,
                  child: Text(d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        d.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (hasDebt ? ThemeConstants.errorRed : ThemeConstants.successGreen).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hasDebt ? 'Ana deni' : 'Hana deni',
                          style: TextStyle(
                            color: hasDebt ? ThemeConstants.errorRed : ThemeConstants.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Two-column details inside the tile
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double colW = (c.maxWidth - 8) / 2; // spacing 8
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _infoBox(Icons.badge, 'Leseni: ${d.licenseNumber}', colW),
                    _infoBox(Icons.payments, 'Deni: ${d.totalDebt.toStringAsFixed(0)}', colW),
                    _infoBox(Icons.event_available,
                        hasDebt && d.dueDates.isNotEmpty ? 'Tarehe inayofuata: ${d.dueDates.first}' : 'Hakuna tarehe', colW),
                    _infoBox(Icons.event, hasDebt ? 'Siku za deni: ${d.unpaidDays}' : 'Hakuna deni', colW),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(IconData icon, String text, double width) => SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: ThemeConstants.primaryBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFilterChip(String text, MonthFilter value) => FilterChip(
        label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        selected: _monthFilter == value,
        onSelected: (bool v) {
          setState(() => _monthFilter = value);
          _applyFilter();
        },
        selectedColor: ThemeConstants.primaryBlue,
        backgroundColor: ThemeConstants.primaryBlue,
        checkmarkColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.25))),
      );

  Widget _chip(IconData icon, String text) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double screenW = MediaQuery.of(context).size.width;
          // Cap each chip width to 60% of screen to guarantee wrapping and prevent row overflow
          final double maxW = screenW * 0.6;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Icon(icon, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  void _openCreateForm() {
    _openDetailForm(null);
  }

  Future<void> _openDriverRecords(Driver d) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => DebtRecordsListScreen(driverId: d.id, driverName: d.name),
      ),
    );
  }

  Future<void> _openDetailForm(Driver? driver) async {
    final bool? changed = await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => DebtRecordFormScreen(driver: driver),
        fullscreenDialog: true,
      ),
    );
    if (changed == true) {
      await _loadDrivers();
    }
  }
}

class DebtRecordFormScreen extends StatefulWidget {
  const DebtRecordFormScreen({super.key, this.driver});
  final Driver? driver;

  @override
  State<DebtRecordFormScreen> createState() => _DebtRecordFormScreenState();
}

class _DebtRecordFormScreenState extends State<DebtRecordFormScreen> {
  final ApiService _api = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final List<DateTime> _selectedDates = <DateTime>[];
  final Map<DateTime, TextEditingController> _amountCtrls = <DateTime, TextEditingController>{};
  bool _promised = false;
  DateTime? _promiseDate;
  bool _submitting = false;

  // Driver selection state
  List<Driver> _allDrivers = <Driver>[];
  List<Driver> _filteredDrivers = <Driver>[];
  Driver? _selectedDriver;
  bool _loadingDrivers = false;
  String? _driverLoadError;
  final TextEditingController _driverSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDriver = widget.driver;
    if (_selectedDriver == null) {
      _fetchDrivers();
    }
    // Initialize search filtering
    _driverSearch.addListener(() {
      final String q = _driverSearch.text.toLowerCase().trim();
      setState(() {
        if (q.isEmpty) {
          _filteredDrivers = List<Driver>.from(_allDrivers);
        } else {
          _filteredDrivers = _allDrivers.where((Driver d) {
            final String name = d.name.toLowerCase();
            final String phone = d.phone.toLowerCase();
            final String vehicle = (d.vehicleNumber ?? '').toLowerCase();
            final String license = d.licenseNumber.toLowerCase();
            return name.contains(q) || phone.contains(q) || vehicle.contains(q) || license.contains(q);
          }).toList();
        }
      });
    });
  }

  Future<void> _fetchDrivers() async {
    try {
      setState(() {
        _loadingDrivers = true;
        _driverLoadError = null;
      });
      final Map<String, dynamic> res = await _api.getDebtDrivers(page: 1, limit: 200);
      final List<dynamic> list = (res['data']?['drivers'] as List<dynamic>?) ?? <dynamic>[];
      _allDrivers = list.map((dynamic j) => Driver.fromJson(j as Map<String, dynamic>)).toList();
      _filteredDrivers = List<Driver>.from(_allDrivers);
      // Do not auto-select to force explicit choice
    } catch (e) {
      setState(() => _driverLoadError = e.toString());
    } finally {
      setState(() => _loadingDrivers = false);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _driverSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.primaryBlue,
      appBar: ThemeConstants.buildAppBar('Rekodi Deni'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildDriverSelector(),
                    const SizedBox(height: 16),
                    _sectionTitle('Tarehe Deni Lilianza'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ..._selectedDates.map((DateTime d) => _dateChip(d)),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.4)),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.06),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Ongeza Tarehe'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Per-date amounts
                    ..._buildPerDateAmountFields(),
                    const SizedBox(height: 12),
                    _labelValue('Mwezi / Mwaka', _monthYearText()),
                    const SizedBox(height: 8),
                    // Subtotal row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('Jumla (tarehe x kiasi):', style: TextStyle(color: Colors.white70)),
                        Text(
                          _subtotalText(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notes,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecorationWithIcon('Maelezo ya Deni (hiari)', Icons.notes),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _promised,
                      onChanged: (bool v) => setState(() => _promised = v),
                      title: const Text('Je, ameahidi kulipa?', style: TextStyle(color: Colors.white)),
                      activeColor: ThemeConstants.primaryOrange,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_promised) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _labelValue(
                              'Tarehe ya ahadi kulipa',
                              _promiseDate == null ? 'Chagua tarehe' : _fmt(_promiseDate!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _pickPromiseDate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThemeConstants.primaryOrange,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.event),
                            label: const Text('Chagua'),
                          )
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_submitting ? 'Inahifadhi...' : 'Hifadhi Deni'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.primaryOrange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value.isEmpty ? '-' : value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          t,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _buildDriverSelector() {
    // If a driver is already selected (e.g., launched from a driver row), show the card and a change button
    if (_selectedDriver != null) {
      final Driver d = _selectedDriver!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildDriverCard(d),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedDriver = null),
              icon: const Icon(Icons.swap_horiz, color: Colors.white70, size: 18),
              label: const Text('Badilisha dereva', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      );
    }

    // Otherwise, show a dropdown to pick a driver
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _sectionTitle('Chagua Dereva'),
        const SizedBox(height: 8),
        if (_loadingDrivers)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: <Widget>[
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 8),
                Text('Inapakia madereva...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        else if (_driverLoadError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: <Widget>[
                const Icon(Icons.error_outline, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(child: Text(_driverLoadError!, style: const TextStyle(color: Colors.white))),
                TextButton(
                  onPressed: _fetchDrivers,
                  child: const Text('Jaribu tena', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        else ...<Widget>[
          // Search box
          TextField(
            controller: _driverSearch,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecorationWithIcon('Tafuta dereva kwa jina, simu, gari au leseni', Icons.search).copyWith(
              suffixIcon: _driverSearch.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                      onPressed: () {
                        _driverSearch.clear();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (_filteredDrivers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
              child: const Text('Hakuna matokeo ya utafutaji', style: TextStyle(color: Colors.white70)),
            )
          else
            DropdownButtonFormField<String>(
              value: null,
              isExpanded: true,
              decoration: _inputDecorationWithIcon('Chagua dereva', Icons.person),
              dropdownColor: ThemeConstants.primaryBlue,
              iconEnabledColor: Colors.white70,
              style: const TextStyle(color: Colors.white),
              items: _filteredDrivers.map((Driver d) {
                final String label = d.vehicleNumber != null && d.vehicleNumber!.isNotEmpty
                    ? '${d.name} • ${d.vehicleNumber}'
                    : d.name;
                return DropdownMenuItem<String>(
                  value: d.id,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (String? id) {
                setState(() {
                  _selectedDriver = _allDrivers.firstWhere((Driver d) => d.id == id);
                });
              },
              validator: (String? v) => (_selectedDriver == null) ? 'Chagua dereva' : null,
            ),
        ],
      ],
    );
  }

  Widget _buildDriverCard(Driver d) {
    final String name = d.name.isNotEmpty ? d.name : '-';
    final String license = d.licenseNumber.isNotEmpty ? d.licenseNumber : '-';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty && name != '-' ? name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Leseni: ${license.isNotEmpty ? license : '-'}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (license.isEmpty || license == '-') ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: const <Widget>[
                Icon(Icons.info_outline, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hakuna leseni iliyohifadhiwa kwenye wasifu kwa sasa.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ThemeConstants.primaryOrange, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  InputDecoration _inputDecorationWithIcon(String hint, IconData icon) {
    final base = _inputDecoration(hint);
    return base.copyWith(
      prefixIcon: Icon(icon, color: Colors.white70, size: 18),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
    );
  }

  String _monthYearText() {
    if (_selectedDates.isEmpty) return '-';
    final DateTime d = _selectedDates.first;
    return '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _dateChip(DateTime d) => Chip(
        label: Text(_fmt(d), style: const TextStyle(color: Colors.white)),
        backgroundColor: ThemeConstants.primaryBlue,
        shape: StadiumBorder(side: BorderSide(color: Colors.white.withOpacity(0.25))),
        deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        onDeleted: () {
          setState(() {
            _selectedDates.remove(d);
            _amountCtrls.remove(d)?.dispose();
          });
        },
      );

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ThemeConstants.primaryOrange,
            surface: ThemeConstants.primaryBlue,
            onPrimary: Colors.white,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (!_selectedDates.contains(picked)) {
          _selectedDates.add(picked);
          _amountCtrls[picked] = TextEditingController();
          _selectedDates.sort((DateTime a, DateTime b) => a.compareTo(b));
        }
      });
    }
  }

  Future<void> _pickPromiseDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _promiseDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ThemeConstants.primaryOrange,
            surface: ThemeConstants.primaryBlue,
            onPrimary: Colors.white,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _promiseDate = picked);
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
          .toString();

  String _subtotalText() {
    double total = 0;
    for (final DateTime d in _selectedDates) {
      final c = _amountCtrls[d];
      if (c == null) continue;
      final double? v = double.tryParse(c.text.trim());
      if (v != null && v > 0) total += v;
    }
    return total.toStringAsFixed(0);
  }

  List<Widget> _buildPerDateAmountFields() {
    return _selectedDates.map((DateTime d) {
      final TextEditingController ctrl = _amountCtrls[d] ??= TextEditingController();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_fmt(d), style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecorationWithIcon('Kiasi kwa tarehe hii', Icons.payments),
                onChanged: (_) => setState(() {}),
                validator: (String? v) {
                  final double? val = double.tryParse((v ?? '').trim());
                  if (val == null || val <= 0) return 'Weka kiasi sahihi';
                  return null;
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _submit() async {
    if (_selectedDates.isEmpty) {
      _showSnack('Ongeza angalau tarehe moja ya deni');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final String driverId = _selectedDriver?.id ?? widget.driver?.id ?? '';
    if (driverId.isEmpty) {
      _showSnack('Tafadhali chagua dereva kwanza');
      return;
    }

    try {
      setState(() => _submitting = true);
      // Build items payload
      final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
      for (final DateTime d in _selectedDates) {
        final TextEditingController? ctrl = _amountCtrls[d];
        final double? val = ctrl == null ? null : double.tryParse(ctrl.text.trim());
        if (val == null || val <= 0) {
          _showSnack('Weka kiasi sahihi kwa tarehe ${_fmt(d)}');
          setState(() => _submitting = false);
          return;
        }
        items.add(<String, dynamic>{'date': _fmt(d), 'amount': val});
      }
      await _api.createDebts(
        driverId: driverId,
        items: items,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        promisedToPay: _promised,
        promiseToPayAt: _promiseDate,
      );
      if (!mounted) return;
      // Notify other pages (e.g., Malipo and Debts list) to refresh
      try {
        Provider.of<DebtsProvider>(context, listen: false).markChanged();
      } catch (_) {}
      _showSnack('Madeni yamehifadhiwa kikamilifu', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Hitilafu: ${e.toString()}');
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String m, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: success ? ThemeConstants.successGreen : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
