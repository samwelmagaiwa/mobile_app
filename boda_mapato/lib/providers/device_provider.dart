import "package:flutter/foundation.dart";
import "../models/device.dart";
import "../services/api_service.dart";

class DeviceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Device> _devices = <Device>[];
  Device? _selectedDevice;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Device> get devices => _devices;
  Device? get selectedDevice => _selectedDevice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load devices from API
  Future<void> loadDevices() async {
    _setLoading(true);
    _clearError();

    try {
      final Map<String, dynamic> resp = await _api.getDevices();
      final data = resp["data"];
      List list = <dynamic>[];
      if (data is List) {
        list = data;
      } else if (data is Map && data["data"] is List) {
        // Handle paginated structure { data: { data: [...] } }
        list = data["data"];
      }
      _devices = list.map<Device>((final j) => Device.fromJson(j as Map<String, dynamic>)).toList();
      // Set first device as selected if none is selected
      if (_selectedDevice == null && _devices.isNotEmpty) {
        _selectedDevice = _devices.first;
      }
    } catch (e) {
      _setError("Failed to load devices: $e");
      // Use mock data for development
      _loadMockDevices();
    } finally {
      _setLoading(false);
    }
  }

  // Add new device
  Future<bool> addDevice(final Device device) async {
    try {
      final Map<String, dynamic> resp = await _api.createDevice(device.toJson());
      final Map<String, dynamic> createdJson = (resp["data"] ?? resp) as Map<String, dynamic>;
      final Device newDevice = Device.fromJson(createdJson);
      _devices.add(newDevice);
      
      // Set as selected if it"s the first device
      _selectedDevice ??= newDevice;
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Failed to add device: $e");
      // Add to local list for development
      _devices.add(device);
      _selectedDevice ??= device;
      notifyListeners();
      return false;
    }
  }

  // Update device
  Future<bool> updateDevice(final Device device) async {
    try {
      final Map<String, dynamic> resp = await _api.updateDevice(device.id, device.toJson());
      final Map<String, dynamic> updatedJson = (resp["data"] ?? resp) as Map<String, dynamic>;
      final Device updatedDevice = Device.fromJson(updatedJson);
      final int index = _devices.indexWhere((final Device d) => d.id == device.id);
      if (index != -1) {
        _devices[index] = updatedDevice;
        
        // Update selected device if it"s the same
        if (_selectedDevice?.id == device.id) {
          _selectedDevice = updatedDevice;
        }
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError("Failed to update device: $e");
      return false;
    }
  }

  // Delete device
  Future<bool> deleteDevice(final String id) async {
    try {
      await _api.deleteDevice(id);
      _devices.removeWhere((final Device d) => d.id == id);
      
      // Clear selected device if it was deleted
      if (_selectedDevice?.id == id) {
        _selectedDevice = _devices.isNotEmpty ? _devices.first : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError("Failed to delete device: $e");
      return false;
    }
  }

  // Select device
  void selectDevice(final Device device) {
    _selectedDevice = device;
    notifyListeners();
  }

  // Get devices by type
  List<Device> getDevicesByType(final DeviceType type) => _devices.where((final Device d) => d.type == type).toList();

  // Get active devices
  List<Device> getActiveDevices() => _devices.where((final Device d) => d.isActive).toList();

  // Get device by ID
  Device? getDeviceById(final String id) {
    try {
      return _devices.firstWhere((final Device d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get device statistics
  Map<String, dynamic> getDeviceStats() {
    final int totalDevices = _devices.length;
    final int activeDevices = _devices.where((final Device d) => d.isActive).length;
    final Map<DeviceType, int> devicesByType = <DeviceType, int>{};

    for (final Device device in _devices) {
      devicesByType[device.type] = (devicesByType[device.type] ?? 0) + 1;
    }

    return <String, dynamic>{
      "total": totalDevices,
      "active": activeDevices,
      "inactive": totalDevices - activeDevices,
      "byType": devicesByType,
    };
  }

  // Toggle device active status
  Future<bool> toggleDeviceStatus(final String id) async {
    final Device? device = getDeviceById(id);
    if (device == null) return false;

    final Device updatedDevice = device.copyWith(isActive: !device.isActive);
    return await updateDevice(updatedDevice);
  }

  // Search devices
  List<Device> searchDevices(final String query) {
    if (query.isEmpty) return _devices;

    return _devices.where((final Device device) => device.name.toLowerCase().contains(query.toLowerCase()) ||
          device.plateNumber.toLowerCase().contains(query.toLowerCase()) ||
          device.type.name.toLowerCase().contains(query.toLowerCase()),).toList();
  }

  // Sort devices
  void sortDevices(final String sortBy, {final bool ascending = true}) {
    switch (sortBy) {
      case "name":
        _devices.sort((final Device a, final Device b) => ascending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name),);
      case "type":
        _devices.sort((final Device a, final Device b) => ascending
            ? a.type.name.compareTo(b.type.name)
            : b.type.name.compareTo(a.type.name),);
      case "plateNumber":
        _devices.sort((final Device a, final Device b) => ascending
            ? a.plateNumber.compareTo(b.plateNumber)
            : b.plateNumber.compareTo(a.plateNumber),);
      case "createdAt":
        _devices.sort((final Device a, final Device b) => ascending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt),);
      default:
        break;
    }
    notifyListeners();
  }

  // Get device type distribution
  Map<DeviceType, double> getDeviceTypeDistribution() {
    final Map<DeviceType, int> counts = <DeviceType, int>{};
    final int total = _devices.length;

    if (total == 0) return <DeviceType, double>{};

    for (final Device device in _devices) {
      counts[device.type] = (counts[device.type] ?? 0) + 1;
    }

    return counts.map((final DeviceType type, final int count) => MapEntry(type, count / total * 100));
  }

  // Helper methods
  void _setLoading(final bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(final String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Load mock data for development
  void _loadMockDevices() {
    final DateTime now = DateTime.now();
    _devices = <Device>[
      Device(
        id: "device1",
        name: "Bajaji ya Kwanza",
        type: DeviceType.bajaji,
        plateNumber: "T123ABC",
        driverId: "driver1",
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
        description: "Bajaji ya kijani ya abiria",
      ),
      Device(
        id: "device2",
        name: "Pikipiki Haraka",
        type: DeviceType.pikipiki,
        plateNumber: "MC456DEF",
        driverId: "driver1",
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 2)),
        description: "Pikipiki ya nyekundu ya haraka",
      ),
      Device(
        id: "device3",
        name: "Gari la Mizigo",
        type: DeviceType.gari,
        plateNumber: "T789GHI",
        driverId: "driver1",
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 3)),
        description: "Gari la mizigo na abiria",
        isActive: false,
      ),
    ];

    // Set first device as selected
    if (_devices.isNotEmpty) {
      _selectedDevice = _devices.first;
    }

    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _devices.clear();
    _selectedDevice = null;
    _clearError();
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadDevices();
  }
}
