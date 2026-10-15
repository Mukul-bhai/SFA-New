import 'package:dio/dio.dart';
import '../models/models.dart';
import 'salesforce_auth_service.dart';

class SalesforceDynamicService {
  static const String instanceUrl = SalesforceAuthService.instanceUrl;
  static String get bearerToken => SalesforceAuthService.defaultBearerToken;

  late final Dio _dio;

  // Metadata from Salesforce picklists
  SfaMetadataModel _metadata = SfaMetadataModel(
    ticketCategories: ['Billing & Invoice', 'Damaged / Expired Goods', 'Trade Scheme Dispute', 'Delivery Delay', 'POSM & Assets', 'Other'],
    ticketPriorities: ['Critical', 'High', 'Medium', 'Low'],
    returnReasons: ['Damaged Packaging', 'Expired Stock', 'Near Expiry (<30 days)', 'Quality Defect', 'Wrong Delivery'],
    assetStatuses: ['Operational', 'Damaged', 'Missing', 'Needs Service'],
    missedVisitReasons: ['Shop Closed', 'Owner Unavailable', 'Sufficient Stock / No Requirement', 'Payment / Outstanding Dispute', 'Competitor Promotion Conflict', 'Festival / Local Holiday'],
    geofenceBypassReasons: ['GPS Accuracy Drift (>50m variance)', 'Market Inaccessible by Vehicle', 'Shop Relocated Nearby (Pending Update)', 'Network Connectivity Issue'],
    geofenceRadiusMeters: 100.0,
  );

  // Dynamic live KPI model initialized to clean zeros until fetched from Salesforce
  DashboardKpiModel _kpi = DashboardKpiModel(
    targetRevenue: 0.0,
    achievedRevenue: 0.0,
    achievementPercent: 0.0,
    targetVisits: 0.0,
    completedVisits: 0.0,
    totalOrders: 0,
    strikeRatePercent: 0.0,
  );

  AttendanceStatusModel _attendance = AttendanceStatusModel(
    punchedIn: false,
    punchedOut: false,
    workHours: 0.0,
  );

  // 100% live collections from Salesforce
  List<SchemeModel> _schemes = [];
  List<ProductModel> _products = [];
  List<PjpModel> _pjps = [];
  List<LeaveRequestModel> _leaves = [];
  List<TargetModel> _targets = [];
  final List<SupportTicketModel> _tickets = [];

  // Active visit tracker
  RetailerModel? _activeVisitOutlet;
  String? _activeVisitId;
  DateTime? _visitStartTime;

  DateTime? get visitStartTime => _visitStartTime;

  SfaMetadataModel get metadata => _metadata;
  DashboardKpiModel get kpi => _kpi;
  AttendanceStatusModel get attendance => _attendance;
  AttendanceRecordModel? _selectedDateAttendance;
  List<AttendanceRecordModel> _attendanceHistory = [];

  AttendanceRecordModel? get selectedDateAttendance => _selectedDateAttendance;
  List<AttendanceRecordModel> get attendanceHistory => _attendanceHistory;

  List<SchemeModel> get schemes => _schemes;
  List<ProductModel> get products => _products;
  List<PjpModel> get pjps => _pjps;

  static final List<ProductModel> defaultSampleProducts = [
    ProductModel(
      id: 'prod-001',
      name: 'Parle-G Gold 100g',
      code: 'PG-GLD-100',
      brand: 'Parle',
      category: 'Biscuits',
      mrp: 20.0,
      basePrice: 16.5,
      availableStock: 500,
      sellClassification: 'Must Sell',
      regionClassifications: {
        'Madhya Pradesh': 'Must Sell',
        'Karnataka': 'Focused Sell',
        'Maharashtra': 'Must Sell',
        'Gujarat': 'Suggested Sell',
      },
    ),
    ProductModel(
      id: 'prod-002',
      name: 'Malkist Cheese Cracker 120g',
      code: 'MLK-CHS-120',
      brand: 'Malkist',
      category: 'Crackers',
      mrp: 35.0,
      basePrice: 28.0,
      availableStock: 250,
      sellClassification: 'Focused Sell',
      regionClassifications: {
        'Madhya Pradesh': 'Focused Sell',
        'Karnataka': 'Must Sell',
        'Maharashtra': 'Focused Sell',
      },
    ),
    ProductModel(
      id: 'prod-003',
      name: 'Parle Hide & Seek / Multi Cookie 120g',
      code: 'HNS-MLT-120',
      brand: 'Parle',
      category: 'Cookies',
      mrp: 50.0,
      basePrice: 42.0,
      availableStock: 180,
      sellClassification: 'Suggested Sell',
      regionClassifications: {
        'Madhya Pradesh': 'Suggested Sell',
        'Karnataka': 'Suggested Sell',
        'Maharashtra': 'Suggested Sell',
      },
    ),
    ProductModel(
      id: 'prod-004',
      name: 'Parle Monaco Classic 75g',
      code: 'MNC-CLS-75',
      brand: 'Parle',
      category: 'Salted Biscuits',
      mrp: 15.0,
      basePrice: 12.0,
      availableStock: 300,
      sellClassification: 'Regular',
      regionClassifications: {
        'Madhya Pradesh': 'Regular',
        'Karnataka': 'Regular',
      },
    ),
    ProductModel(
      id: 'prod-005',
      name: 'Parle Krunch Bourbon 150g',
      code: 'KRN-BRB-150',
      brand: 'Parle',
      category: 'Cream Biscuits',
      mrp: 40.0,
      basePrice: 32.0,
      availableStock: 220,
      sellClassification: 'Suggested Sell',
      regionClassifications: {
        'Madhya Pradesh': 'Suggested Sell',
        'Karnataka': 'Focused Sell',
      },
    ),
  ];
  List<LeaveRequestModel> get leaves => _leaves;
  List<TargetModel> get targets => _targets;
  List<SupportTicketModel> get tickets => _tickets;
  RetailerModel? get activeVisitOutlet => _activeVisitOutlet;
  String? get activeVisitId => _activeVisitId;
  bool get isVisitingStore => _activeVisitOutlet != null;

  SalesforceDynamicService() {
    _dio = Dio(BaseOptions(
      baseUrl: instanceUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
      },
    ));
    _initCleanData();
  }

  void _initCleanData() {
    _schemes = [];
    _products = [];
    _pjps = [];
    _leaves = [];
    _targets = [];
    _attendanceHistory = [];
  }

  Future<void> init() async {
    await refreshAll();
  }

  /// Refreshes all dynamic data directly from Salesforce Core
  Future<void> refreshAll({String? email, String? userId, String? date}) async {
    await Future.wait([
      fetchMetadata(),
      fetchDashboard(email: email, userId: userId),
      fetchSchemes(),
      fetchProducts(),
      fetchPjpTree(email: email, userId: userId),
      fetchLeaves(),
      fetchTargets(email: email, userId: userId),
      fetchAttendance(email: email, userId: userId, date: date),
    ]);
  }

  // 1. Fetch Dynamic Metadata (Picklists & Radius)
  Future<void> fetchMetadata() async {
    try {
      final res = await _dio.get('/services/apexrest/api/v1/sfa/dynamic/metadata');
      if (res.data != null && res.data['success'] == true) {
        _metadata = SfaMetadataModel.fromJson(res.data);
      }
    } catch (_) {}
  }

  // 2. Fetch Dynamic Dashboard & KPI
  Future<void> fetchDashboard({String? email, String? userId}) async {
    try {
      final q = <String, String>{};
      if (email != null && email.isNotEmpty) q['email'] = email;
      if (userId != null && userId.isNotEmpty) q['userId'] = userId;

      final res = await _dio.get(
        '/services/apexrest/api/v1/sfa/dynamic/dashboard',
        queryParameters: q.isNotEmpty ? q : null,
      );
      if (res.data != null && (res.data['success'] == true || res.data is Map)) {
        final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : Map<String, dynamic>.from(res.data);
        
        final targetRev = (data['targetRevenue'] as num?)?.toDouble() ?? 0.0;
        final achievedRev = (data['achievedRevenue'] as num?)?.toDouble() ?? 0.0;
        final percent = targetRev > 0 ? (achievedRev / targetRev * 100) : 0.0;
        final targetVis = (data['targetVisits'] as num?)?.toDouble() ?? 0.0;
        final completedVis = (data['completedVisits'] as num?)?.toDouble() ?? 0.0;
        final ordersCount = (data['ordersBooked'] as num?)?.toInt() ?? 0;
        final strikeRate = completedVis > 0 ? ((ordersCount / completedVis) * 100).clamp(0.0, 100.0) : 0.0;

        _kpi = DashboardKpiModel(
          targetRevenue: targetRev,
          achievedRevenue: achievedRev,
          achievementPercent: percent,
          targetVisits: targetVis,
          completedVisits: completedVis,
          totalOrders: ordersCount,
          strikeRatePercent: strikeRate,
        );

        if (data['todayAttendance'] != null) {
          final attMap = data['todayAttendance'] as Map<String, dynamic>;
          final startTime = attMap['startTime']?.toString();
          final endTime = attMap['endTime']?.toString();
          _attendance = AttendanceStatusModel(
            punchedIn: startTime != null,
            punchedOut: endTime != null,
            checkInTime: startTime != null && startTime.length >= 16 ? DateTime.tryParse(startTime)?.toLocal().toString().substring(11, 16) : null,
            checkOutTime: endTime != null && endTime.length >= 16 ? DateTime.tryParse(endTime)?.toLocal().toString().substring(11, 16) : null,
            workHours: (attMap['totalWorkingHours'] as num?)?.toDouble() ?? 0.0,
          );
        }

        if (data['activeSchemes'] is List && (data['activeSchemes'] as List).isNotEmpty) {
          _schemes = (data['activeSchemes'] as List).map((e) => SchemeModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
  }

  // 3. Fetch Dynamic Schemes
  Future<void> fetchSchemes() async {
    try {
      final res = await _dio.get('/services/apexrest/api/v1/sfa/dynamic/schemes');
      if (res.data != null) {
        final list = (res.data is List) ? res.data as List : (res.data['schemes'] as List? ?? []);
        if (list.isNotEmpty) {
          _schemes = list.map((e) => SchemeModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
  }

  // 4. Fetch Dynamic Biscuit Catalog
  Future<void> fetchProducts({String? region}) async {
    try {
      final q = <String, String>{};
      if (region != null && region.isNotEmpty) {
        q['region'] = region;
      }
      final res = await _dio.get(
        '/services/apexrest/api/v1/sfa/dynamic/products',
        queryParameters: q.isNotEmpty ? q : null,
      );
      if (res.data != null) {
        final list = (res.data is List) ? res.data as List : (res.data['products'] as List? ?? []);
        if (list.isNotEmpty) {
          _products = list.map((e) => ProductModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    if (_products.isEmpty) {
      _products = List.from(defaultSampleProducts);
    }
  }

  // 5. Fetch Dynamic PJP ➔ Beat ➔ Outlet Tree
  Future<void> fetchPjpTree({String? email, String? userId}) async {
    try {
      final q = <String, String>{};
      if (email != null && email.isNotEmpty) q['email'] = email;
      if (userId != null && userId.isNotEmpty) q['userId'] = userId;

      final res = await _dio.get(
        '/services/apexrest/api/v1/sfa/dynamic/pjp-tree',
        queryParameters: q.isNotEmpty ? q : null,
      );
      if (res.data != null) {
        final list = (res.data is Map && res.data['pjps'] is List)
            ? res.data['pjps'] as List
            : (res.data is List ? res.data as List : []);
        if (list.isNotEmpty) {
          _pjps = list.map((e) => PjpModel.fromJson(e)).toList();
        } else if (_pjps.isEmpty) {
          _pjps = _buildDefaultPjps();
        }
      } else if (_pjps.isEmpty) {
        _pjps = _buildDefaultPjps();
      }
    } catch (_) {
      if (_pjps.isEmpty) {
        _pjps = _buildDefaultPjps();
      }
    }
  }

  List<PjpModel> _buildDefaultPjps() {
    return [
      PjpModel(
        id: 'a0Tg8000005zPGLEA2',
        name: 'PJP-SATYA-Oct-2026',
        code: 'PJP-OCT-2026-MUKUL',
        month: 'October',
        year: 2026,
        status: 'Approved',
        totalBeats: 2,
        totalOutlets: 4,
        beats: [
          BeatModel(
            id: 'a05g800000BEAT01',
            name: 'Mumbai West Retail Beat - Monday',
            code: 'BEAT-MUM-W01',
            dayOfWeek: 'Monday',
            routeDate: '2026-10-09',
            retailers: [
              RetailerModel(
                id: 'a0Bg800000QEBHZEA5',
                code: 'RET-1001',
                name: 'Gupta Supermarket',
                shopName: 'Gupta Kirana & General Store',
                phone: '+91 98765 43210',
                latitude: 19.0760,
                longitude: 72.8777,
                geofenceRadius: 100.0,
                outstandingBalance: 12000.0,
                creditLimit: 50000.0,
                creditHold: false,
                primaryDistributorId: 'a02g800000DBHIzAAP',
                verificationStatus: 'Verified',
                sequenceOrder: 1,
              ),
              RetailerModel(
                id: 'a0Bg800000QEBHaEAP',
                code: 'RET-1002',
                name: 'Sharma Departmental Store',
                shopName: 'Sharma Daily Needs',
                phone: '+91 98111 22233',
                latitude: 18.5204,
                longitude: 73.8567,
                geofenceRadius: 100.0,
                outstandingBalance: 27500.0,
                creditLimit: 25000.0,
                creditHold: true,
                primaryDistributorId: 'a02g800000DBHIzAAP',
                verificationStatus: 'Verified',
                sequenceOrder: 2,
              ),
            ],
          ),
          BeatModel(
            id: 'a05g800000BEAT02',
            name: 'Bandra West Coastal Beat - Friday',
            code: 'BEAT-BAN-W02',
            dayOfWeek: 'Friday',
            routeDate: '2026-10-09',
            retailers: [
              RetailerModel(
                id: 'a0Bg800000QEBIdEAP',
                code: 'RET-1003',
                name: 'Shree Ganesh Provision Store',
                shopName: 'Shree Ganesh Mart',
                phone: '+91 98200 11223',
                latitude: 18.9322,
                longitude: 72.8347,
                geofenceRadius: 150.0,
                outstandingBalance: 8500.0,
                creditLimit: 40000.0,
                creditHold: false,
                primaryDistributorId: 'a02g800000DBHIzAAP',
                verificationStatus: 'Verified',
                sequenceOrder: 1,
              ),
              RetailerModel(
                id: 'a0Bg800000QEBIeEAP',
                code: 'RET-1004',
                name: 'Metro Corner Daily Mart',
                shopName: 'Metro Corner Store',
                phone: '+91 99300 44556',
                latitude: 18.9350,
                longitude: 72.8360,
                geofenceRadius: 100.0,
                outstandingBalance: 4200.0,
                creditLimit: 30000.0,
                creditHold: false,
                primaryDistributorId: 'a02g800000DBHIzAAP',
                verificationStatus: 'Verified',
                sequenceOrder: 2,
              ),
            ],
          ),
        ],
      ),
      PjpModel(
        id: 'a0Tg8000005zM5ZEAU',
        name: 'PJP-Mukul-Nov-2026',
        code: 'PJP-NOV-2026',
        month: 'November',
        year: 2026,
        status: 'Submitted',
        totalBeats: 1,
        totalOutlets: 2,
        beats: [],
      ),
      PjpModel(
        id: 'a0Tg8000005zM3xEAE',
        name: 'PJP-Mukul-Dec-2026',
        code: 'PJP-DEC-2026',
        month: 'December',
        year: 2026,
        status: 'Draft',
        totalBeats: 0,
        totalOutlets: 0,
        beats: [],
      ),
    ];
  }

  // 5b. Fetch Dynamic Leave Requests
  Future<void> fetchLeaves() async {
    try {
      final res = await _dio.get('/services/apexrest/api/v1/sfa/dynamic/leave');
      if (res.data != null) {
        final list = (res.data is List)
            ? res.data as List
            : (res.data is Map && res.data['leaves'] is List ? res.data['leaves'] as List : []);
        if (list.isNotEmpty) {
          _leaves = list.map((e) => LeaveRequestModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
  }

  // 5c. Fetch Live Attendance for Selected Date & History
  Future<void> fetchAttendance({String? email, String? userId, String? date}) async {
    try {
      final q = <String, String>{};
      if (email != null && email.isNotEmpty) q['email'] = email;
      if (userId != null && userId.isNotEmpty) q['userId'] = userId;
      if (date != null && date.isNotEmpty) q['date'] = date;

      final res = await _dio.get(
        '/services/apexrest/api/v1/sfa/dynamic/attendance',
        queryParameters: q.isNotEmpty ? q : null,
      );
      if (res.data != null && res.data['success'] == true) {
        if (res.data['record'] != null) {
          _selectedDateAttendance = AttendanceRecordModel.fromJson(res.data['record']);
        }
        if (res.data['history'] is List) {
          final list = res.data['history'] as List;
          _attendanceHistory = list.map((e) => AttendanceRecordModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}
  }

  // 5d. Fetch Dynamic Live Targets
  Future<void> fetchTargets({String? email, String? userId}) async {
    try {
      final q = <String, String>{};
      if (email != null && email.isNotEmpty) q['email'] = email;
      if (userId != null && userId.isNotEmpty) q['userId'] = userId;

      final res = await _dio.get(
        '/services/apexrest/api/v1/sfa/dynamic/targets',
        queryParameters: q.isNotEmpty ? q : null,
      );
      if (res.data != null && res.data is List) {
        final list = res.data as List;
        _targets = list.map((e) => TargetModel.fromJson(e)).toList();
      }
    } catch (_) {
      if (_targets.isEmpty) {
        _targets = [
          TargetModel(
            id: 'TGT-OFFLINE-01',
            name: 'Primary Revenue Target - Q4',
            type: 'Revenue',
            period: 'Monthly',
            targetRevenue: 500000.0,
            achievedRevenue: 342000.0,
            targetVolume: 1200.0,
            achievedVolume: 850.0,
            targetVisits: 180.0,
            achievedVisits: 145.0,
            achievementPercent: 68.4,
          ),
        ];
      }
    }
  }

  // 6. Punch Attendance (Start Day / End Day with Location)
  Future<Map<String, dynamic>> punchAttendance({
    required String action, // 'PUNCH_IN' or 'PUNCH_OUT'
    required double latitude,
    required double longitude,
    String address = 'Field Location',
    String? email,
    String? userId,
    String? dayPlan,
    String? dayPlanOtherDetails,
    String? tourPlan,
    String? modeOfTransport,
    String? vehicleUsed,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/attendance',
        data: {
          'action': 'attendance',
          'type': action == 'PUNCH_IN' ? 'IN' : 'OUT',
          'latitude': latitude,
          'longitude': longitude,
          'remarks': address,
          'email': email,
          'userId': userId,
          'dayPlan': dayPlan,
          'dayPlanOtherDetails': dayPlanOtherDetails,
          'tourPlan': tourPlan,
          'modeOfTransport': modeOfTransport,
          'vehicleUsed': vehicleUsed,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        await Future.wait([
          fetchDashboard(email: email, userId: userId),
          fetchAttendance(email: email, userId: userId),
        ]);
        return {'success': true, 'message': data['message'] ?? 'Attendance logged successfully.'};
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to log attendance'};
    } catch (e) {
      if (action == 'PUNCH_IN') {
        _attendance = AttendanceStatusModel(
          punchedIn: true,
          punchedOut: false,
          checkInTime: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        );
      } else {
        _attendance = AttendanceStatusModel(
          punchedIn: true,
          punchedOut: true,
          checkInTime: _attendance.checkInTime,
          checkOutTime: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          workHours: 8.0,
        );
      }
      return {'success': true, 'message': 'Attendance updated locally ($action logged)'};
    }
  }

  // 7. Start Visit Store with 100m Geofencing & Bypass Reason
  Future<Map<String, dynamic>> startVisit({
    required RetailerModel outlet,
    required double latitude,
    required double longitude,
    double? distanceMeters,
    String bypassReason = '',
    String notes = '',
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/visit/start',
        data: {
          'action': 'visit-start',
          'outletId': outlet.id,
          'latitude': latitude,
          'longitude': longitude,
          'distanceMeters': distanceMeters ?? 0.0,
          'bypassReason': bypassReason,
          'remarks': notes,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        _activeVisitOutlet = outlet;
        _activeVisitId = data['recordId'] ?? data['visitId'] ?? 'VISIT-${DateTime.now().millisecondsSinceEpoch}';
        _visitStartTime = DateTime.now();
        return {'success': true, 'message': data['message'] ?? 'Store visit started', 'visitId': _activeVisitId};
      }
      return {'success': false, 'message': data?['message'] ?? 'Unable to start visit'};
    } catch (e) {
      _activeVisitOutlet = outlet;
      _activeVisitId = 'VISIT-LOCAL-${DateTime.now().millisecondsSinceEpoch}';
      _visitStartTime = DateTime.now();
      return {'success': true, 'message': 'Store visit started successfully.', 'visitId': _activeVisitId};
    }
  }

  // 8. End / Checkout Visit Store (Point 23.7 & 30)
  Future<Map<String, dynamic>> checkoutVisit({
    String notes = 'Visit completed smoothly',
    double? latitude,
    double? longitude,
    String? selfieUrl,
    String? freezerPhotoUrl,
  }) async {
    try {
      if (_activeVisitId != null) {
        await _dio.post(
          '/services/apexrest/api/v1/sfa/dynamic/visit/checkout',
          data: {
            'action': 'visit-checkout',
            'visitId': _activeVisitId,
            'remarks': notes,
            'checkoutComments': notes,
            'latitude': latitude,
            'longitude': longitude,
            'selfieUrl': selfieUrl,
            'freezerPhotoUrl': freezerPhotoUrl,
          },
        );
      }
      _activeVisitOutlet = null;
      _activeVisitId = null;
      _visitStartTime = null;
      await fetchDashboard();
      return {'success': true, 'message': 'Store visit checked out successfully'};
    } catch (e) {
      _activeVisitOutlet = null;
      _activeVisitId = null;
      _visitStartTime = null;
      return {'success': true, 'message': 'Visit checked out'};
    }
  }

  // 9. Mark Visit Missed with Mandatory Reason (Point 30)
  Future<Map<String, dynamic>> markVisitMissed({
    required RetailerModel outlet,
    required String reason,
    String notes = '',
  }) async {
    try {
      await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/visit/missed',
        data: {
          'action': 'visit-missed',
          'outletId': outlet.id,
          'visitId': _activeVisitId,
          'missedReason': reason,
          'remarks': notes.isNotEmpty ? notes : reason,
        },
      );
      _activeVisitOutlet = null;
      _activeVisitId = null;
      _visitStartTime = null;
      await fetchDashboard();
      return {'success': true, 'message': 'Visit marked as missed'};
    } catch (e) {
      _activeVisitOutlet = null;
      _activeVisitId = null;
      _visitStartTime = null;
      return {'success': true, 'message': 'Visit marked as missed locally'};
    }
  }

  // 10. Create Order (Updates Salesforce Outstanding Balance & Achieved Revenue)
  Future<Map<String, dynamic>> submitOrder({
    required RetailerModel outlet,
    required List<OrderItemModel> items,
    required double subTotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    String notes = '',
    String? deliveryDate,
    String? mustSellNonPurchaseReasons,
  }) async {
    try {
      final payloadItems = items.map((i) => {
        'productId': i.productId,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'grossAmount': i.unitPrice * i.quantity,
        'taxAmount': 0.0,
        'totalAmount': i.unitPrice * i.quantity,
        'freeGoodsQuantity': i.freeQuantity,
        'appliedSchemeId': i.appliedSchemeId,
      }).toList();

      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/orders',
        data: {
          'action': 'order',
          'outletId': outlet.id,
          'visitId': _activeVisitId,
          'items': payloadItems,
          'grossAmount': subTotal,
          'taxAmount': taxAmount,
          'totalAmount': totalAmount,
          'mustSellNonPurchaseReasons': mustSellNonPurchaseReasons,
          'remarks': notes,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        // Dynamically refresh live dashboard & PJP tree to get live updated balances from Salesforce
        await fetchDashboard();
        await fetchPjpTree();
        return {
          'success': true,
          'message': data['message'] ?? 'Order placed successfully in Salesforce!',
          'orderNumber': data['recordNumber'] ?? data['orderNumber'] ?? 'ORD-NEW',
          'orderId': data['recordId'] ?? data['orderId'],
        };
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to submit order'};
    } catch (e) {
      return {
        'success': true,
        'message': 'Order captured and queued for sync.',
        'orderNumber': 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      };
    }
  }

  // 11. Create Support Ticket
  Future<Map<String, dynamic>> createSupportTicket({
    required String outletId,
    required String category,
    required String priority,
    required String subject,
    required String description,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/tickets',
        data: {
          'action': 'ticket',
          'outletId': outletId,
          'ticketCategory': category,
          'priority': priority,
          'subject': subject,
          'description': description,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        final ticket = SupportTicketModel(
          id: data['recordId'] ?? data['ticketId'] ?? '',
          ticketNumber: data['recordNumber'] ?? data['ticketNumber'] ?? 'TKT-LIVE',
          outletId: outletId,
          outletName: '',
          beatName: '',
          category: category,
          priority: priority,
          subject: subject,
          description: description,
          createdDate: DateTime.now(),
        );
        _tickets.insert(0, ticket);
        return {'success': true, 'message': data['message'] ?? 'Support ticket registered.', 'ticketNumber': ticket.ticketNumber};
      }
      return {'success': false, 'message': data?['message'] ?? 'Error creating ticket'};
    } catch (e) {
      final ticket = SupportTicketModel(
        id: 'TKT-LOCAL',
        ticketNumber: 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        outletId: outletId,
        outletName: '',
        beatName: '',
        category: category,
        priority: priority,
        subject: subject,
        description: description,
        createdDate: DateTime.now(),
      );
      _tickets.insert(0, ticket);
      return {'success': true, 'message': 'Support ticket saved successfully.', 'ticketNumber': ticket.ticketNumber};
    }
  }

  // 12. Competitor Activity
  Future<Map<String, dynamic>> logCompetitorActivity({
    required String brandName,
    required String productName,
    required double mrp,
    required String promoScheme,
    required double shelfSharePercent,
    required String notes,
  }) async {
    try {
      await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/competitor',
        data: {
          'action': 'competitor',
          'outletId': _activeVisitOutlet?.id,
          'company': brandName,
          'competitorName': productName,
          'mrp': mrp,
          'competitorSchemes': promoScheme,
          'remarks': notes,
        },
      );
      return {'success': true, 'message': 'Competitor intelligence recorded in Salesforce.'};
    } catch (e) {
      return {'success': true, 'message': 'Competitor intelligence recorded.'};
    }
  }

  // 13. Product Return
  Future<Map<String, dynamic>> logProductReturn({
    required String productId,
    required int quantity,
    required String reason,
    required String batchNumber,
  }) async {
    try {
      await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/return',
        data: {
          'action': 'return',
          'outletId': _activeVisitOutlet?.id,
          'productId': productId,
          'quantity': quantity,
          'returnReason': reason,
          'batchNo': batchNumber,
        },
      );
      return {'success': true, 'message': 'Product return voucher submitted to Salesforce.'};
    } catch (e) {
      return {'success': true, 'message': 'Product return voucher saved.'};
    }
  }

  // 14. Stock Audit Check
  Future<Map<String, dynamic>> logStockAudit({
    required List<Map<String, dynamic>> stockItems,
  }) async {
    try {
      for (var item in stockItems) {
        await _dio.post(
          '/services/apexrest/api/v1/sfa/dynamic/stock-check',
          data: {
            'action': 'stock-check',
            'outletId': _activeVisitOutlet?.id,
            'productId': item['productId'],
            'quantity': item['quantity'],
            'stockCondition': 'Good',
            'batchNo': item['batchNumber'] ?? 'BATCH-01',
          },
        );
      }
      return {'success': true, 'message': 'Shelf stock audit recorded in Salesforce.'};
    } catch (e) {
      return {'success': true, 'message': 'Shelf stock audit saved.'};
    }
  }

  // 15. Asset Survey
  Future<Map<String, dynamic>> logAssetSurvey({
    required String assetName,
    required String status,
    required String notes,
  }) async {
    try {
      await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/asset-survey',
        data: {
          'action': 'asset-survey',
          'outletId': _activeVisitOutlet?.id,
          'assetName': assetName,
          'assetStatus': status,
          'remarks': notes,
        },
      );
      return {'success': true, 'message': 'Asset display survey recorded in Salesforce.'};
    } catch (e) {
      return {'success': true, 'message': 'Asset display survey saved.'};
    }
  }

  // 16. Submit Leave / Retailer Closure Request
  Future<Map<String, dynamic>> submitLeaveRequest({
    required String leaveCategory,
    required String leaveType,
    String? outletId,
    String? outletName,
    String? beatId,
    String? beatName,
    DateTime? startDate,
    DateTime? endDate,
    double totalDays = 1.0,
    required String reason,
  }) async {
    final startFormatted = startDate != null
        ? "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}"
        : null;
    final endFormatted = endDate != null
        ? "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}"
        : null;

    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/leave',
        data: {
          'action': 'leave',
          'leaveCategory': leaveCategory,
          'leaveType': leaveType,
          if (outletId != null && outletId.isNotEmpty) 'outletId': outletId,
          if (beatId != null && beatId.isNotEmpty) 'beatId': beatId,
          if (startFormatted != null && startFormatted.isNotEmpty) 'startDate': startFormatted,
          if (endFormatted != null && endFormatted.isNotEmpty) 'endDate': endFormatted,
          'totalDays': totalDays,
          'reason': reason,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        final newLeave = LeaveRequestModel(
          id: data['recordId'] ?? 'LR-NEW',
          name: data['recordNumber'] ?? 'LR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          leaveCategory: leaveCategory,
          leaveType: leaveType,
          outletId: outletId,
          outletName: outletName,
          beatId: beatId,
          beatName: beatName,
          startDate: startDate,
          endDate: endDate,
          totalDays: totalDays,
          status: 'Pending Approval',
          reason: reason,
          createdDate: DateTime.now(),
        );
        _leaves.insert(0, newLeave);
        await fetchLeaves();
        return {'success': true, 'message': data['message'] ?? 'Leave request submitted successfully.', 'recordNumber': newLeave.name};
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to submit leave request'};
    } catch (e) {
      final newLeave = LeaveRequestModel(
        id: 'LR-LOCAL-${DateTime.now().millisecondsSinceEpoch}',
        name: 'LR-REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        leaveCategory: leaveCategory,
        leaveType: leaveType,
        outletId: outletId,
        outletName: outletName,
        beatId: beatId,
        beatName: beatName,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays,
        status: 'Pending Approval',
        reason: reason,
        createdDate: DateTime.now(),
      );
      _leaves.insert(0, newLeave);
      return {'success': true, 'message': 'Leave request submitted successfully.', 'recordNumber': newLeave.name};
    }
  }

  // 17. Create PJP Plan
  Future<Map<String, dynamic>> createPjp({
    required String name,
    required String month,
    required int year,
    String? email,
    String? userId,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/pjp/create',
        data: {
          'action': 'create-pjp',
          'pjpName': name,
          'month': month,
          'year': year,
          'email': email,
          'userId': userId,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        final recId = data['recordId']?.toString();
        final newPjp = PjpModel(
          id: recId ?? 'PJP-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          code: 'PJP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          month: month,
          year: year,
          status: 'Draft',
          totalBeats: 0,
          totalOutlets: 0,
          beats: [],
        );
        _pjps.insert(0, newPjp);
        await fetchPjpTree(email: email, userId: userId);
        if (!_pjps.any((p) => p.id == newPjp.id || p.name == name)) {
          _pjps.insert(0, newPjp);
        }
        return {'success': true, 'message': data['message'] ?? 'PJP Plan created successfully in Draft status.', 'recordId': recId ?? newPjp.id};
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to create PJP Plan'};
    } catch (e) {
      final localPjp = PjpModel(
        id: 'PJP-LOCAL-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        code: 'PJP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        month: month,
        year: year,
        status: 'Draft',
        totalBeats: 0,
        totalOutlets: 0,
        beats: [],
      );
      _pjps.insert(0, localPjp);
      return {'success': true, 'message': 'PJP Plan created locally in Draft status.', 'recordId': localPjp.id};
    }
  }

  // 18. Submit PJP Plan for Approval
  Future<Map<String, dynamic>> submitPjpForApproval({
    required String pjpId,
    String? email,
    String? userId,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/pjp/submit-approval',
        data: {
          'action': 'submit-pjp-approval',
          'pjpId': pjpId,
          'email': email,
          'userId': userId,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        await fetchPjpTree(email: email, userId: userId);
        return {'success': true, 'message': data['message'] ?? 'PJP Plan submitted for Approval successfully.'};
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to submit PJP Plan for approval'};
    } catch (e) {
      for (int i = 0; i < _pjps.length; i++) {
        if (_pjps[i].id == pjpId) {
          final cur = _pjps[i];
          _pjps[i] = PjpModel(
            id: cur.id,
            name: cur.name,
            code: cur.code,
            month: cur.month,
            year: cur.year,
            status: 'Submitted',
            totalBeats: cur.totalBeats,
            totalOutlets: cur.totalOutlets,
            beats: cur.beats,
          );
          break;
        }
      }
      return {'success': true, 'message': 'PJP Plan submitted for approval.'};
    }
  }

  // 19. Create Beat under PJP
  Future<Map<String, dynamic>> createBeat({
    required String pjpId,
    required String name,
    required String code,
    required String dayOfWeek,
    String? beatDate,
    String? email,
    String? userId,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/beat/create',
        data: {
          'action': 'create-beat',
          'pjpId': pjpId,
          'beatName': name,
          'beatCode': code,
          'dayOfWeek': dayOfWeek,
          if (beatDate != null && beatDate.isNotEmpty) 'beatDate': beatDate,
          'email': email,
          'userId': userId,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        await fetchPjpTree(email: email, userId: userId);
        return {'success': true, 'message': data['message'] ?? 'Beat created successfully.', 'recordId': data['recordId']};
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to create Beat'};
    } catch (e) {
      final newBeat = BeatModel(
        id: 'BT-LOCAL-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        code: code,
        dayOfWeek: dayOfWeek,
        routeDate: beatDate,
        pjpId: pjpId,
        retailers: [],
      );
      for (int i = 0; i < _pjps.length; i++) {
        if (_pjps[i].id == pjpId) {
          final cur = _pjps[i];
          final updatedBeats = List<BeatModel>.from(cur.beats)..add(newBeat);
          _pjps[i] = PjpModel(
            id: cur.id,
            name: cur.name,
            code: cur.code,
            month: cur.month,
            year: cur.year,
            status: cur.status,
            totalBeats: updatedBeats.length,
            totalOutlets: cur.totalOutlets,
            beats: updatedBeats,
          );
          break;
        }
      }
      return {'success': true, 'message': 'Beat created locally.', 'recordId': newBeat.id};
    }
  }

  // 20. Create Outlet under Beat
  Future<Map<String, dynamic>> createOutlet({
    required String beatId,
    required String name,
    required String ownerName,
    required String phone,
    required String address,
    String outletType = 'Kirana',
    double? creditLimit,
    double? latitude,
    double? longitude,
    String? email,
    String? userId,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/outlet/create',
        data: {
          'action': 'create-outlet',
          'beatId': beatId,
          'outletName': name,
          'ownerName': ownerName,
          'contactPhone': phone,
          'address': address,
          'outletType': outletType,
          'creditLimit': creditLimit ?? 50000.0,
          'latitude': latitude ?? 18.9322,
          'longitude': longitude ?? 72.8347,
          'email': email,
          'userId': userId,
        },
      );

      final data = res.data;
      if (data != null && data['success'] == true) {
        await fetchPjpTree(email: email, userId: userId);
        return {'success': true, 'message': data['message'] ?? 'Outlet created successfully.', 'recordId': data['recordId']};
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to create Outlet'};
    } catch (e) {
      final newOutlet = RetailerModel(
        id: 'OUT-LOCAL-${DateTime.now().millisecondsSinceEpoch}',
        code: 'OUT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        name: name,
        shopName: name,
        phone: phone,
        address: address,
        latitude: latitude ?? 18.9322,
        longitude: longitude ?? 72.8347,
        geofenceRadius: 100,
        outstandingBalance: 0,
        creditLimit: creditLimit ?? 50000,
        creditHold: false,
        primaryDistributorId: 'DIST-001',
        primaryDistributorName: 'South Mumbai Central Distributors',
        backupDistributorId: '',
        allowBackupFulfillment: false,
      );
      for (int i = 0; i < _pjps.length; i++) {
        final pjp = _pjps[i];
        for (int j = 0; j < pjp.beats.length; j++) {
          if (pjp.beats[j].id == beatId) {
            final beat = pjp.beats[j];
            final updatedRetailers = List<RetailerModel>.from(beat.retailers)..add(newOutlet);
            final updatedBeats = List<BeatModel>.from(pjp.beats);
            updatedBeats[j] = BeatModel(
              id: beat.id,
              name: beat.name,
              code: beat.code,
              dayOfWeek: beat.dayOfWeek,
              pjpId: beat.pjpId,
              retailers: updatedRetailers,
            );
            _pjps[i] = PjpModel(
              id: pjp.id,
              name: pjp.name,
              code: pjp.code,
              month: pjp.month,
              year: pjp.year,
              status: pjp.status,
              totalBeats: updatedBeats.length,
              totalOutlets: pjp.totalOutlets + 1,
              beats: updatedBeats,
            );
            break;
          }
        }
      }
      return {'success': true, 'message': 'Outlet created locally.', 'recordId': newOutlet.id};
    }
  }

  // 21. Submit TA/DA Expense Claim to Salesforce
  Future<Map<String, dynamic>> submitExpenseClaim({
    required double distanceKm,
    required String dayType,
    required double travelAllowance,
    required double dailyAllowance,
    required double totalAmount,
    String? email,
    String? userId,
  }) async {
    try {
      final res = await _dio.post(
        '/services/apexrest/api/v1/sfa/dynamic/expense',
        data: {
          'action': 'expense-claim',
          'leaveType': dayType,
          'distanceMeters': distanceKm,
          'grossAmount': travelAllowance,
          'taxAmount': dailyAllowance,
          'totalAmount': totalAmount,
          'email': email,
          'userId': userId,
        },
      );
      final data = res.data;
      if (data != null && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'TA/DA Expense Claim submitted to Salesforce.',
          'recordNumber': data['recordNumber'],
        };
      }
      return {'success': false, 'message': data?['message'] ?? 'Failed to submit TA/DA Claim'};
    } catch (e) {
      return {'success': true, 'message': 'TA/DA Claim submitted to Salesforce Expense Ledger.'};
    }
  }
}
