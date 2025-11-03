import "dart:ui";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../constants/theme_constants.dart";
import "../../models/communication.dart";
import "../../models/driver.dart";
import "../../services/api_service.dart";
import "../../services/localization_service.dart";
import "../../utils/responsive_helper.dart";

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _apiEndpointsAvailable = false;
  String _selectedFilterMode =
      "all"; // "all", "sms", "call", "whatsapp", "system_note"
  String _selectedFilterStatus = "all"; // "all", "answered", "unanswered"

  // Communication data
  List<Communication> _communications = [];
  List<Driver> _availableDrivers = [];
  CommunicationSummary? _summary;

  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadCommunicationsData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Custom glass card decoration for consistent blue background blending
  Widget _buildBlueBlendGlassCard({required Widget child}) {
    ResponsiveHelper.init(context);
    return Container(
      constraints: BoxConstraints(
        minHeight: ResponsiveHelper.cardMinHeight,
        maxWidth: ResponsiveHelper.maxCardWidth,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveHelper.elevation * 3,
            offset: Offset(0, ResponsiveHelper.elevation * 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ResponsiveHelper.isMobile ? 6 : 8,
            sigmaY: ResponsiveHelper.isMobile ? 6 : 8,
          ),
          child: Padding(
            padding: ResponsiveHelper.cardPadding,
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _loadCommunicationsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize API service
      await _apiService.initialize();

      // Load available drivers for form
      await _loadAvailableDrivers();

      // Load communications
      await _loadCommunications();

      // Load summary
      await _loadCommunicationSummary();
    } on Exception catch (e) {
      _showErrorSnackBar("Hitilafu katika kupakia data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableDrivers() async {
    try {
      // Check if driver endpoint exists
      bool useApiData = false;

      try {
        final bool isConnected = await _apiService.testConnectivity();
        if (!isConnected) {
          useApiData = false;
          setState(() {
            _apiEndpointsAvailable = false;
          });
        } else {
          final testResponse =
              await _apiService.get('/admin/drivers', requireAuth: false);
          useApiData = testResponse['status'] == 'success';
          setState(() {
            _apiEndpointsAvailable = useApiData;
          });
        }
      } on Exception catch (e) {
        useApiData = false;
        setState(() {
          _apiEndpointsAvailable = false;
        });
        debugPrint('Connectivity/driver endpoint check failed: $e');
      }

      if (useApiData) {
        try {
          final response = await _apiService.get('/admin/drivers');
          // Be robust to multiple response shapes
          final bool ok = (response['status'] == 'success') ||
              response.containsKey('data') ||
              response.containsKey('drivers');
          if (ok) {
            final dynamic data =
                response.containsKey('data') ? response['data'] : response;

            List<dynamic> driverData = <dynamic>[];
            if (data is List) {
              driverData = data;
            } else if (data is Map) {
              if (data['drivers'] is List) {
                driverData = data['drivers'] as List<dynamic>;
              } else if (data['data'] is List) {
                // Laravel-style pagination: { data: { data: [...] }}
                driverData = data['data'] as List<dynamic>;
              } else if (data['items'] is List) {
                driverData = data['items'] as List<dynamic>;
              } else if (data['results'] is List) {
                driverData = data['results'] as List<dynamic>;
              }
            }

            if (driverData.isNotEmpty) {
              _availableDrivers = driverData
                  .map((json) => Driver.fromJson(json as Map<String, dynamic>))
                  .toList();
            } else {
              // Could not recognize the driver list structure; fall back to mock
              debugPrint('Unexpected driver data format: '
                  '${data.runtimeType}${data is Map ? ' keys=${data.keys.toList()}' : ''}');
              _availableDrivers = _getMockDrivers();
            }
          } else {
            _availableDrivers = _getMockDrivers();
          }
        } on Exception catch (driverError) {
          debugPrint('Error parsing driver data: $driverError');
          _availableDrivers = _getMockDrivers();
        }
      } else {
        // Mock data for drivers
        _availableDrivers = _getMockDrivers();
      }
    } on Exception catch (e) {
      debugPrint('Failed to load drivers: $e');
      _availableDrivers = _getMockDrivers();
    }
  }

  Future<void> _loadCommunications() async {
    try {
      if (_apiEndpointsAvailable) {
        try {
          final response = await _apiService.get('/admin/communications');
          if (response['status'] == 'success' && response['data'] != null) {
final List<dynamic> commData = response['data'] as List<dynamic>;
            _communications = commData
                .map((json) => Communication.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            _communications = [];
          }
        } on Exception catch (apiError) {
          debugPrint('Communications API endpoints failed: $apiError');
          setState(() {
            _apiEndpointsAvailable = false;
          });
          _communications = _getMockCommunications();
        }
      } else {
        _communications = _getMockCommunications();
      }
    } on Exception catch (e) {
      debugPrint('Communications loading failed: $e');
      _communications = _getMockCommunications();
    }
  }

  Future<void> _loadCommunicationSummary() async {
    try {
      if (_apiEndpointsAvailable) {
        try {
          final response =
              await _apiService.get('/admin/communications/summary');
          if (response['status'] == 'success' && response['data'] != null) {
            _summary = CommunicationSummary.fromJson(response['data']);
          } else {
            _summary = _getMockSummary();
          }
        } on Exception catch (_) {
          _summary = _getMockSummary();
        }
      } else {
        _summary = _getMockSummary();
      }
    } on Exception catch (e) {
      debugPrint('Summary load failed: $e');
      _summary = _getMockSummary();
    }
  }

  List<Driver> _getMockDrivers() {
    return [
      Driver(
        id: "1",
        name: "Juma Mwalimu",
        email: "juma@example.com",
        phone: "+255712345678",
        licenseNumber: "LIC001",
        joinedDate: DateTime.now().subtract(const Duration(days: 120)),
        status: "active",
        totalPayments: 85000,
        rating: 4.5,
        tripsCompleted: 245,
        vehicleType: "Boda Boda",
        vehicleNumber: "BB001",
      ),
      Driver(
        id: "2",
        name: "Mary Kibwana",
        email: "mary@example.com",
        phone: "+255723456789",
        licenseNumber: "LIC002",
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
        status: "active",
        totalPayments: 67000,
        rating: 4.2,
        tripsCompleted: 198,
        vehicleType: "Boda Boda",
        vehicleNumber: "BB002",
      ),
      Driver(
        id: "3",
        name: "Hassan Mwangi",
        email: "hassan@example.com",
        phone: "+255734567890",
        licenseNumber: "LIC003",
        joinedDate: DateTime.now().subtract(const Duration(days: 60)),
        status: "active",
        totalPayments: 45000,
        rating: 4.7,
        tripsCompleted: 132,
        vehicleType: "Boda Boda",
        vehicleNumber: "BB003",
      ),
    ];
  }

  List<Communication> _getMockCommunications() {
    final DateTime now = DateTime.now();
    return [
      Communication(
        id: 1,
        driverId: "1",
        driverName: "Juma Mwalimu",
        messageDate: now.subtract(const Duration(days: 2)),
        messageContent:
            "Naomba kukujuza kuwa sitaweza kufika kazini kesho kwa sababu za dharura za familia. Naomba msamaha.",
        response:
            "Tumepokea ujumbe wako. Unahitaji siku ngapi za mapumziko? Tafadhali tupatie maelezo zaidi.",
        mode: CommunicationMode.sms,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Communication(
        id: 2,
        driverId: "2",
        driverName: "Mary Kibwana",
        messageDate: now.subtract(const Duration(days: 5)),
        messageContent:
            "Simu ya dereva imezima. Hatuwezi kumufikia kwa mazungumzo ya mapito ya malipo ya leo.",
        mode: CommunicationMode.systemNote,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Communication(
        id: 3,
        driverId: "1",
        driverName: "Juma Mwalimu",
        messageDate: now.subtract(const Duration(days: 7)),
        messageContent:
            "Kumradhi, naomba kujua ikiwa kuna uwezekano wa kupata mapito mazuri ya kuvuta abiria zaidi?",
        response:
            "Tunashiriki majeraha mapya wiki hii. Ngoja ujumbe mwingine kesho.",
        mode: CommunicationMode.whatsapp,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      Communication(
        id: 4,
        driverId: "3",
        driverName: "Hassan Mwangi",
        messageDate: now.subtract(const Duration(days: 10)),
        messageContent:
            "Mazungumzo ya simu kuhusu malipo ya deni la wiki iliyopita.",
        response: "Ameahidi kulipa sehemu ya malipo Jumatatu.",
        mode: CommunicationMode.call,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
      ),
    ];
  }

  CommunicationSummary _getMockSummary() {
    return CommunicationSummary(
      totalCommunications: 15,
      unansweredCommunications: 3,
      recentCommunications: 8,
      communicationsByMode: {
        CommunicationMode.sms: 4,
        CommunicationMode.call: 6,
        CommunicationMode.whatsapp: 3,
        CommunicationMode.systemNote: 2,
      },
      lastCommunicationDate: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  void _showErrorSnackBar(String message) {
    ThemeConstants.showErrorSnackBar(context, message);
  }

  void _showSuccessSnackBar(String message) {
    ThemeConstants.showSuccessSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        ResponsiveHelper.init(context);
        return ThemeConstants.buildResponsiveScaffold(
          context,
          title: localizationService.translate("communications_title"),
          body: _isLoading
              ? ThemeConstants.buildResponsiveLoadingWidget(context)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildCommunicationSummary(localizationService),
                      ResponsiveHelper.verticalSpace(1),
                      _buildFiltersSection(localizationService),
                      ResponsiveHelper.verticalSpace(1),
                      _buildCommunicationsTable(localizationService),
                      ResponsiveHelper.verticalSpace(1),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildCommunicationSummary(LocalizationService localizationService) {
    if (_summary == null) return const SizedBox.shrink();

    return _buildBlueBlendGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.chat,
                color: ThemeConstants.primaryOrange,
                size: 24,
              ),
              ResponsiveHelper.horizontalSpace(2),
              Text(
                localizationService.translate("communications_summary_title"),
                style: ThemeConstants.responsiveHeadingStyle(context),
              ),
            ],
          ),
          ResponsiveHelper.verticalSpace(1),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveHelper.isMobile ? 2 : 4,
            childAspectRatio: ResponsiveHelper.isMobile ? 1.5 : 1.2,
            mainAxisSpacing: ResponsiveHelper.spacingM,
            crossAxisSpacing: ResponsiveHelper.spacingM,
            children: <Widget>[
              _buildSummaryCard(
                localizationService.translate("total_communications"),
                _summary!.totalCommunications,
                Icons.chat_bubble_outline,
                ThemeConstants.primaryOrange,
              ),
              _buildSummaryCard(
                localizationService.translate("unanswered"),
                _summary!.unansweredCommunications,
                Icons.help_outline,
                ThemeConstants.errorRed,
              ),
              _buildSummaryCard(
                localizationService.translate("recent_7_days"),
                _summary!.recentCommunications,
                Icons.access_time,
                ThemeConstants.successGreen,
              ),
              _buildSummaryCard(
                localizationService.translate("response_rate"),
                (((_summary!.totalCommunications -
                                _summary!.unansweredCommunications) /
                            (_summary!.totalCommunications == 0
                                ? 1
                                : _summary!.totalCommunications)) *
                        100)
                    .round(),
                Icons.trending_up,
                ThemeConstants.warningAmber,
                suffix: "%",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int value, IconData icon, Color color,
      {String suffix = ""}) {
    return Container(
      padding: ResponsiveHelper.cardPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 28),
          ResponsiveHelper.verticalSpace(1),
          Text(
            title,
            style: ThemeConstants.responsiveCaptionStyle(context).copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          ResponsiveHelper.verticalSpace(0.5),
          Text(
            "$value$suffix",
            style: ThemeConstants.responsiveBodyStyle(context).copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(LocalizationService localizationService) {
    return _buildBlueBlendGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.filter_list,
                color: ThemeConstants.primaryOrange,
                size: 24,
              ),
              ResponsiveHelper.horizontalSpace(2),
              Text(
                localizationService.translate("filter_communications"),
                style: ThemeConstants.responsiveHeadingStyle(context),
              ),
              const Spacer(),
              ElevatedButton.icon(
onPressed: _showAddCommunicationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryOrange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  ResponsiveHelper.isMobile ? localizationService.translate("add") : localizationService.translate("add_communication"),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          ResponsiveHelper.verticalSpace(1),
          // Search field
          TextField(
            controller: _searchController,
            style: ThemeConstants.responsiveBodyStyle(context),
            decoration: InputDecoration(
              hintText: localizationService.translate("search_driver_content"),
              hintStyle: ThemeConstants.responsiveBodyStyle(context).copyWith(
                color: ThemeConstants.textSecondary,
              ),
              prefixIcon:
                  const Icon(Icons.search, color: ThemeConstants.textSecondary),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          ResponsiveHelper.verticalSpace(1),
          // Filter buttons
          if (ResponsiveHelper.isMobile)
            Column(
              children: <Widget>[
                _buildMobileFilterRow(localizationService.translate("type"), _buildModeFilters(localizationService)),
                ResponsiveHelper.verticalSpace(0.5),
                _buildMobileFilterRow(localizationService.translate("status"), _buildStatusFilters(localizationService)),
              ],
            )
          else
            Row(
              children: <Widget>[
                Text(
                  localizationService.translate("type"),
                  style: ThemeConstants.responsiveSubHeadingStyle(context),
                ),
                ResponsiveHelper.horizontalSpace(1),
                Expanded(child: _buildModeFilters(localizationService)),
                ResponsiveHelper.horizontalSpace(2),
                Text(
                  localizationService.translate("status"),
                  style: ThemeConstants.responsiveSubHeadingStyle(context),
                ),
                ResponsiveHelper.horizontalSpace(1),
                Expanded(child: _buildStatusFilters(localizationService)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterRow(String label, Widget filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: ThemeConstants.responsiveSubHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(0.5),
        filters,
      ],
    );
  }

  Widget _buildModeFilters(LocalizationService localizationService) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _buildFilterChip(localizationService.translate("all"), "all", _selectedFilterMode, (value) {
            setState(() {
              _selectedFilterMode = value;
            });
          }),
          ResponsiveHelper.horizontalSpace(1),
          _buildFilterChip("SMS", "sms", _selectedFilterMode, (value) {
            setState(() {
              _selectedFilterMode = value;
            });
          }),
          ResponsiveHelper.horizontalSpace(1),
          _buildFilterChip(localizationService.translate("call"), "call", _selectedFilterMode, (value) {
            setState(() {
              _selectedFilterMode = value;
            });
          }),
          ResponsiveHelper.horizontalSpace(1),
          _buildFilterChip("WhatsApp", "whatsapp", _selectedFilterMode,
              (value) {
            setState(() {
              _selectedFilterMode = value;
            });
          }),
          ResponsiveHelper.horizontalSpace(1),
          _buildFilterChip(localizationService.translate("note"), "system_note", _selectedFilterMode,
              (value) {
            setState(() {
              _selectedFilterMode = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(LocalizationService localizationService) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _buildFilterChip(localizationService.translate("all"), "all", _selectedFilterStatus, (value) {
            setState(() {
              _selectedFilterStatus = value;
            });
          }),
          ResponsiveHelper.horizontalSpace(1),
          _buildFilterChip(localizationService.translate("answered"), "answered", _selectedFilterStatus,
              (value) {
            setState(() {
              _selectedFilterStatus = value;
            });
          }),
          ResponsiveHelper.horizontalSpace(1),
          _buildFilterChip(localizationService.translate("unanswered"), "unanswered", _selectedFilterStatus,
              (value) {
            setState(() {
              _selectedFilterStatus = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue,
      Function(String) onSelected) {
    final bool isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeConstants.primaryOrange.withOpacity(0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ThemeConstants.primaryOrange
                : ThemeConstants.textSecondary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ThemeConstants.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunicationsTable(LocalizationService localizationService) {
    final List<Communication> filteredCommunications =
        _getFilteredCommunications();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "${localizationService.translate("communications")} (${filteredCommunications.length})",
          style: ThemeConstants.responsiveHeadingStyle(context),
        ),
        ResponsiveHelper.verticalSpace(1),
        _buildBlueBlendGlassCard(
          child: Column(
            children: <Widget>[
              // Table header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        flex: 2,
                        child: Text(localizationService.translate("date"),
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 2,
                        child: Text(localizationService.translate("driver"),
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 3,
                        child: Text(localizationService.translate("message"),
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        flex: 2,
                        child: Text(localizationService.translate("response"),
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                    Expanded(
                        child: Text(localizationService.translate("type"),
                            style: ThemeConstants.responsiveCaptionStyle(
                                context))),
                  ],
                ),
              ),
              ResponsiveHelper.verticalSpace(0.5),
              // Table rows
              if (filteredCommunications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: ThemeConstants.textSecondary,
                        ),
                        ResponsiveHelper.verticalSpace(1),
                        Text(
                          localizationService.translate("no_communications"),
                          style: ThemeConstants.responsiveBodyStyle(context),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCommunications.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: ThemeConstants.textSecondary,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final communication = filteredCommunications[index];
                    return _buildCommunicationRow(communication, localizationService);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicationRow(Communication communication, LocalizationService localizationService) {
    return GestureDetector(
onTap: () => _showCommunicationDetails(communication),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Text(
                communication.formattedMessageDate,
                style: ThemeConstants.responsiveBodyStyle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                communication.driverName,
                style: ThemeConstants.responsiveBodyStyle(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                communication.truncatedContent,
                style: ThemeConstants.responsiveBodyStyle(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                communication.truncatedResponse,
                style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                  color: communication.hasResponse
                      ? ThemeConstants.successGreen
                      : ThemeConstants.warningAmber,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCommunicationModeColor(communication.mode)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getCommunicationModeColor(communication.mode)
                        .withOpacity(0.5),
                  ),
                ),
                child: Text(
                  communication.mode.icon,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCommunicationModeColor(CommunicationMode mode) {
    switch (mode) {
      case CommunicationMode.sms:
        return ThemeConstants.primaryOrange;
      case CommunicationMode.call:
        return ThemeConstants.successGreen;
      case CommunicationMode.whatsapp:
        return const Color(0xFF25D366); // WhatsApp green
      case CommunicationMode.systemNote:
        return ThemeConstants.warningAmber;
    }
  }

  List<Communication> _getFilteredCommunications() {
    List<Communication> filtered = List.from(_communications);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((comm) {
        return comm.driverName.toLowerCase().contains(_searchQuery) ||
            comm.messageContent.toLowerCase().contains(_searchQuery) ||
            (comm.response?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply mode filter
    if (_selectedFilterMode != "all") {
      filtered = filtered.where((comm) {
        return comm.mode.value == _selectedFilterMode;
      }).toList();
    }

    // Apply status filter
    if (_selectedFilterStatus != "all") {
      if (_selectedFilterStatus == "answered") {
        filtered = filtered.where((comm) => comm.hasResponse).toList();
      } else if (_selectedFilterStatus == "unanswered") {
        filtered = filtered.where((comm) => !comm.hasResponse).toList();
      }
    }

    // Sort by message date (newest first)
    filtered.sort((a, b) => b.messageDate.compareTo(a.messageDate));

    return filtered;
  }

  void _showCommunicationDetails(Communication communication) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.9),
          title: Row(
            children: <Widget>[
              Text(
                communication.mode.icon,
                style: const TextStyle(fontSize: 24),
              ),
              ResponsiveHelper.horizontalSpace(1),
              Expanded(
                child: Text(
                  "Maelezo ya Mawasiliano",
                  style: ThemeConstants.responsiveHeadingStyle(context),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDetailRow("Dereva:", communication.driverName),
                _buildDetailRow("Tarehe:", communication.formattedDateTime),
                _buildDetailRow("Aina:", communication.mode.displayName),
                ResponsiveHelper.verticalSpace(1),
                Text(
                  "Ujumbe:",
                  style: ThemeConstants.responsiveSubHeadingStyle(context),
                ),
                ResponsiveHelper.verticalSpace(0.5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    communication.messageContent,
                    style: ThemeConstants.responsiveBodyStyle(context),
                  ),
                ),
                ResponsiveHelper.verticalSpace(1),
                Text(
                  "Jibu:",
                  style: ThemeConstants.responsiveSubHeadingStyle(context),
                ),
                ResponsiveHelper.verticalSpace(0.5),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    communication.response ?? "Hakuna jibu bado",
                    style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                      color: communication.hasResponse
                          ? ThemeConstants.textPrimary
                          : ThemeConstants.textSecondary,
                      fontStyle: communication.hasResponse
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            if (!communication.hasResponse)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddResponseDialog(communication);
                },
                child: Text(
                  "Ongeza Jibu",
                  style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                    color: ThemeConstants.primaryOrange,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Funga",
                style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                  color: ThemeConstants.primaryOrange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: ThemeConstants.responsiveSubHeadingStyle(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ThemeConstants.responsiveBodyStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCommunicationDialog() {
    final TextEditingController messageController = TextEditingController();
    Driver? selectedDriver;
    CommunicationMode selectedMode = CommunicationMode.systemNote;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.9),
              title: Row(
                children: <Widget>[
                  const Icon(
                    Icons.add_comment,
                    color: ThemeConstants.primaryOrange,
                    size: 24,
                  ),
                  ResponsiveHelper.horizontalSpace(1),
                  Text(
                    "Ongeza Mawasiliano",
                    style: ThemeConstants.responsiveHeadingStyle(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: ResponsiveHelper.isMobile ? double.maxFinite : 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Driver selection
                      Text(
                        "Chagua Dereva:",
                        style:
                            ThemeConstants.responsiveSubHeadingStyle(context),
                      ),
                      ResponsiveHelper.verticalSpace(0.5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Driver>(
                            value: selectedDriver,
                            hint: Text(
                              "Chagua dereva...",
                              style: ThemeConstants.responsiveBodyStyle(context)
                                  .copyWith(
                                color: ThemeConstants.textSecondary,
                              ),
                            ),
                            dropdownColor:
                                ThemeConstants.primaryBlue.withOpacity(0.9),
                            style: ThemeConstants.responsiveBodyStyle(context),
                            items: _availableDrivers.map((Driver driver) {
                              return DropdownMenuItem<Driver>(
                                value: driver,
                                child: Text(
                                  driver.name,
                                  style: ThemeConstants.responsiveBodyStyle(
                                      context),
                                ),
                              );
                            }).toList(),
                            onChanged: (Driver? value) {
                              setState(() {
                                selectedDriver = value;
                              });
                            },
                          ),
                        ),
                      ),
                      ResponsiveHelper.verticalSpace(1),

                      // Communication mode selection
                      Text(
                        "Aina ya Mawasiliano:",
                        style:
                            ThemeConstants.responsiveSubHeadingStyle(context),
                      ),
                      ResponsiveHelper.verticalSpace(0.5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CommunicationMode>(
                            value: selectedMode,
                            dropdownColor:
                                ThemeConstants.primaryBlue.withOpacity(0.9),
                            style: ThemeConstants.responsiveBodyStyle(context),
                            items: CommunicationMode.allModes
                                .map((CommunicationMode mode) {
                              return DropdownMenuItem<CommunicationMode>(
                                value: mode,
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      mode.icon,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    ResponsiveHelper.horizontalSpace(1),
                                    Text(
                                      mode.displayName,
                                      style: ThemeConstants.responsiveBodyStyle(
                                          context),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (CommunicationMode? value) {
                              setState(() {
                                selectedMode =
                                    value ?? CommunicationMode.systemNote;
                              });
                            },
                          ),
                        ),
                      ),
                      ResponsiveHelper.verticalSpace(1),

                      // Message content
                      Text(
                        "Ujumbe:",
                        style:
                            ThemeConstants.responsiveSubHeadingStyle(context),
                      ),
                      ResponsiveHelper.verticalSpace(0.5),
                      TextField(
                        controller: messageController,
                        style: ThemeConstants.responsiveBodyStyle(context),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Andika ujumbe hapa...",
                          hintStyle: ThemeConstants.responsiveBodyStyle(context)
                              .copyWith(
                            color: ThemeConstants.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    messageController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Ghairi",
                    style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDriver != null &&
                        messageController.text.trim().isNotEmpty) {
                      _saveCommunication(
                        selectedDriver!,
                        messageController.text.trim(),
                        selectedMode,
                      );
                      messageController.dispose();
                      Navigator.of(context).pop();
                    } else {
                      _showErrorSnackBar(
                          "Tafadhali jaza sehemu zote zinazohitajika");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "Hifadhi",
                    style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddResponseDialog(Communication communication) {
    final TextEditingController responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeConstants.primaryBlue.withOpacity(0.9),
          title: Row(
            children: <Widget>[
              const Icon(
                Icons.reply,
                color: ThemeConstants.primaryOrange,
                size: 24,
              ),
              ResponsiveHelper.horizontalSpace(1),
              Expanded(
                child: Text(
                  "Ongeza Jibu",
                  style: ThemeConstants.responsiveHeadingStyle(context),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: ResponsiveHelper.isMobile ? double.maxFinite : 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Original message
                  Text(
                    "Ujumbe wa Awali:",
                    style: ThemeConstants.responsiveSubHeadingStyle(context),
                  ),
                  ResponsiveHelper.verticalSpace(0.5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      communication.messageContent,
                      style:
                          ThemeConstants.responsiveBodyStyle(context).copyWith(
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(1),

                  // Response field
                  Text(
                    "Jibu Lako:",
                    style: ThemeConstants.responsiveSubHeadingStyle(context),
                  ),
                  ResponsiveHelper.verticalSpace(0.5),
                  TextField(
                    controller: responseController,
                    style: ThemeConstants.responsiveBodyStyle(context),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Andika jibu lako hapa...",
                      hintStyle:
                          ThemeConstants.responsiveBodyStyle(context).copyWith(
                        color: ThemeConstants.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                responseController.dispose();
                Navigator.of(context).pop();
              },
              child: Text(
                "Ghairi",
                style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                  color: ThemeConstants.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (responseController.text.trim().isNotEmpty) {
                  _saveResponse(communication, responseController.text.trim());
                  responseController.dispose();
                  Navigator.of(context).pop();
                } else {
                  _showErrorSnackBar("Tafadhali andika jibu");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: Text(
                "Tuma Jibu",
                style: ThemeConstants.responsiveBodyStyle(context).copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCommunication(
      Driver driver, String message, CommunicationMode mode) async {
    try {
      final DateTime now = DateTime.now();
      final Communication newCommunication = Communication(
        id: _communications.length + 1, // Mock ID
        driverId: driver.id,
        driverName: driver.name,
        messageDate: now,
        messageContent: message,
        mode: mode,
        createdAt: now,
        updatedAt: now,
      );

      if (_apiEndpointsAvailable) {
        // Try to save via API
        try {
          final response = await _apiService.post('/admin/communications', {
            'driver_id': driver.id,
            'driver_name': driver.name,
            'message_date': now.toIso8601String(),
            'message_content': message,
            'mode': mode.value,
          });

          if (response['status'] == 'success') {
            // Reload communications from API
            await _loadCommunications();
            await _loadCommunicationSummary();
            _showSuccessSnackBar("Mawasiliano yamehifadhiwa kikamilifu!");
            return;
          }
        } on Exception catch (apiError) {
          debugPrint('Failed to save via API: $apiError');
        }
      }

      // Fallback: Save locally (mock)
      setState(() {
        _communications.insert(0, newCommunication);
        // Update summary
        if (_summary != null) {
          _summary = CommunicationSummary(
            totalCommunications: _summary!.totalCommunications + 1,
            unansweredCommunications: _summary!.unansweredCommunications + 1,
            recentCommunications: _summary!.recentCommunications + 1,
            communicationsByMode: {
              ..._summary!.communicationsByMode,
              mode: (_summary!.communicationsByMode[mode] ?? 0) + 1,
            },
            lastCommunicationDate: now,
          );
        }
      });

      _showSuccessSnackBar("Mawasiliano yamehifadhiwa (mfano)!");
    } on Exception catch (e) {
      _showErrorSnackBar("Hitilafu katika kuhifadhi: $e");
    }
  }

  Future<void> _saveResponse(
      Communication communication, String response) async {
    try {
      if (_apiEndpointsAvailable) {
        // Try to save via API
        try {
          final apiResponse = await _apiService
              .put('/admin/communications/${communication.id}', {
            'response': response,
          });

          if (apiResponse['status'] == 'success') {
            // Reload communications from API
            await _loadCommunications();
            await _loadCommunicationSummary();
            _showSuccessSnackBar("Jibu limehifadhiwa kikamilifu!");
            return;
          }
        } on Exception catch (apiError) {
          debugPrint('Failed to save response via API: $apiError');
        }
      }

      // Fallback: Update locally (mock)
      setState(() {
        final int index =
            _communications.indexWhere((comm) => comm.id == communication.id);
        if (index != -1) {
          _communications[index] = communication.copyWith(
            response: response,
            updatedAt: DateTime.now(),
          );

          // Update summary
          if (_summary != null) {
            _summary = CommunicationSummary(
              totalCommunications: _summary!.totalCommunications,
              unansweredCommunications: _summary!.unansweredCommunications - 1,
              recentCommunications: _summary!.recentCommunications,
              communicationsByMode: _summary!.communicationsByMode,
              lastCommunicationDate: _summary!.lastCommunicationDate,
            );
          }
        }
      });

      _showSuccessSnackBar("Jibu limehifadhiwa (mfano)!");
    } on Exception catch (e) {
      _showErrorSnackBar("Hitilafu katika kuhifadhi jibu: $e");
    }
  }

}
