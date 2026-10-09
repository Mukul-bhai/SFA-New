import 'dart:math';

/// User & Employee Model
class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String employeeCode;
  final String designation;
  final String territoryId;
  final String territoryName;
  final bool hasPassword;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.employeeCode = 'EMP-0104',
    this.designation = 'Field Sales Executive',
    required this.territoryId,
    required this.territoryName,
    required this.hasPassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      employeeCode: json['employeeCode'] ?? json['code'] ?? 'EMP-0104',
      designation: json['designation'] ?? 'Field Sales Executive',
      territoryId: json['territoryId'] ?? '',
      territoryName: json['territoryName'] ?? json['territory'] ?? 'South Mumbai Territory',
      hasPassword: json['hasPassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'username': username,
    'employeeCode': employeeCode,
    'designation': designation,
    'territoryId': territoryId,
    'territoryName': territoryName,
    'hasPassword': hasPassword,
  };
}

/// Past Order for Shop 360 view
class PreviousOrderModel {
  final String id;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String status;

  PreviousOrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    this.status = 'Confirmed',
  });

  factory PreviousOrderModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['orderDate'] != null) {
      parsedDate = DateTime.tryParse(json['orderDate'].toString()) ?? DateTime.now();
    }
    return PreviousOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? json['orderNumber'] ?? 'ORD-000',
      orderDate: parsedDate,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Confirmed',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'orderDate': orderDate.toIso8601String(),
    'totalAmount': totalAmount,
    'status': status,
  };
}

/// Outlet / Retailer Model with 100m geofencing & credit check
class RetailerModel {
  final String id;
  final String code;
  final String name;
  final String shopName;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final double outstandingBalance;
  final double creditLimit;
  final bool creditHold;
  final String primaryDistributorId;
  final String primaryDistributorName;
  final String backupDistributorId;
  final bool allowBackupFulfillment;
  final String verificationStatus;
  final int sequenceOrder;
  final int totalOrders;
  final List<PreviousOrderModel> previousOrders;

  RetailerModel({
    required this.id,
    required this.code,
    required this.name,
    required this.shopName,
    required this.phone,
    this.address = 'Station Road, Mumbai',
    required this.latitude,
    required this.longitude,
    this.geofenceRadius = 100.0,
    required this.outstandingBalance,
    required this.creditLimit,
    required this.creditHold,
    required this.primaryDistributorId,
    this.primaryDistributorName = 'Apex FMCG Distributors',
    this.backupDistributorId = '',
    this.allowBackupFulfillment = false,
    this.verificationStatus = 'Verified',
    this.sequenceOrder = 1,
    this.totalOrders = 0,
    this.previousOrders = const [],
  });

  /// Check if user is blocked from taking orders due to outstanding balance
  bool get isOrderBlockedDueToCredit => outstandingBalance >= creditLimit;

  /// Calculate distance in meters using Haversine formula
  double distanceInMetersTo(double userLat, double userLon) {
    const double earthRadius = 6371000; // meters
    final dLat = (userLat - latitude) * (pi / 180.0);
    final dLon = (userLon - longitude) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latitude * (pi / 180.0)) *
            cos(userLat * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  factory RetailerModel.fromJson(Map<String, dynamic> json) {
    final prevOrdersList = json['previousOrders'] as List? ?? [];
    return RetailerModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      shopName: json['shopName'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '+91 98765 43210',
      address: json['address'] ?? 'Mumbai, MH',
      latitude: (json['latitude'] ?? 19.0760).toDouble(),
      longitude: (json['longitude'] ?? 72.8777).toDouble(),
      geofenceRadius: (json['geofenceRadius'] ?? 100.0).toDouble(),
      outstandingBalance: (json['outstandingBalance'] ?? 0.0).toDouble(),
      creditLimit: (json['creditLimit'] ?? 50000.0).toDouble(),
      creditHold: json['creditHold'] ?? false,
      primaryDistributorId: json['primaryDistributorId'] ?? '',
      primaryDistributorName: json['primaryDistributorName'] ?? 'Apex FMCG Distributors',
      totalOrders: (json['totalOrders'] ?? prevOrdersList.length).toInt(),
      previousOrders: prevOrdersList.map((e) => PreviousOrderModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'shopName': shopName,
    'phone': phone,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'geofenceRadius': geofenceRadius,
    'outstandingBalance': outstandingBalance,
    'creditLimit': creditLimit,
    'creditHold': creditHold,
    'primaryDistributorId': primaryDistributorId,
    'primaryDistributorName': primaryDistributorName,
    'totalOrders': totalOrders,
    'previousOrders': previousOrders.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetailerModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Beat Model
class BeatModel {
  final String id;
  final String name;
  final String code;
  final String dayOfWeek;
  final String? routeDate;
  final String pjpId;
  final List<RetailerModel> retailers;

  BeatModel({
    required this.id,
    required this.name,
    required this.code,
    required this.dayOfWeek,
    this.routeDate,
    this.pjpId = '',
    required this.retailers,
  });

  factory BeatModel.fromJson(Map<String, dynamic> json) {
    final list = json['outlets'] as List? ?? json['retailers'] as List? ?? [];
    return BeatModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      routeDate: json['routeDate'] ?? json['beatDate'],
      pjpId: json['pjpId'] ?? '',
      retailers: list.map((e) => RetailerModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'dayOfWeek': dayOfWeek,
    'routeDate': routeDate,
    'pjpId': pjpId,
    'retailers': retailers.map((r) => r.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeatModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Permanent Journey Plan (PJP) Model
class PjpModel {
  final String id;
  final String name;
  final String code;
  final String month;
  final int year;
  final String status;
  final int totalBeats;
  final int totalOutlets;
  final List<BeatModel> beats;

  PjpModel({
    required this.id,
    required this.name,
    required this.code,
    required this.month,
    required this.year,
    required this.status,
    this.totalBeats = 0,
    this.totalOutlets = 0,
    required this.beats,
  });

  factory PjpModel.fromJson(Map<String, dynamic> json) {
    final beatList = json['beats'] as List? ?? [];
    final parsedBeats = beatList.map((e) => BeatModel.fromJson(e)).toList();
    int outletsCount = 0;
    for (var b in parsedBeats) {
      outletsCount += b.retailers.length;
    }

    return PjpModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      month: json['month'] ?? 'October',
      year: json['year'] is num
          ? (json['year'] as num).toInt()
          : (int.tryParse(json['year']?.toString() ?? '2026') ?? 2026),
      status: json['status'] ?? 'Approved',
      totalBeats: json['totalBeats'] is num
          ? (json['totalBeats'] as num).toInt()
          : (int.tryParse(json['totalBeats']?.toString() ?? '0') ?? parsedBeats.length),
      totalOutlets: json['totalOutlets'] is num
          ? (json['totalOutlets'] as num).toInt()
          : (int.tryParse(json['totalOutlets']?.toString() ?? '0') ?? outletsCount),
      beats: parsedBeats,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'month': month,
    'year': year,
    'status': status,
    'totalBeats': totalBeats,
    'totalOutlets': totalOutlets,
    'beats': beats.map((b) => b.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PjpModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Product Model
class ProductModel {
  final String id;
  final String name;
  final String code;
  final String brand;
  final String category;
  final String subCategory;
  final String packSize;
  final String uom;
  final double mrp;
  final double basePrice;
  final double gstRate;
  final String barcode;
  final double availableStock;

  ProductModel({
    required this.id,
    required this.name,
    required this.code,
    required this.brand,
    required this.category,
    this.subCategory = '',
    this.packSize = 'Standard',
    this.uom = 'Pieces',
    required this.mrp,
    required this.basePrice,
    this.gstRate = 18.0,
    this.barcode = '',
    this.availableStock = 100.0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? json['productCode'] ?? '',
      brand: json['brand'] ?? 'Parle',
      category: json['category'] ?? 'Biscuits',
      subCategory: json['subCategory'] ?? '',
      packSize: json['packSize'] ?? 'Standard',
      uom: json['uom'] ?? 'Pieces',
      mrp: (json['mrp'] ?? 150.0).toDouble(),
      basePrice: (json['basePrice'] ?? json['unitPrice'] ?? 120.0).toDouble(),
      gstRate: (json['gstRate'] ?? 18.0).toDouble(),
      barcode: json['barcode'] ?? '',
      availableStock: (json['availableStock'] ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'brand': brand,
    'category': category,
    'subCategory': subCategory,
    'packSize': packSize,
    'uom': uom,
    'mrp': mrp,
    'basePrice': basePrice,
    'gstRate': gstRate,
    'barcode': barcode,
    'availableStock': availableStock,
  };
}

/// Scheme Slab Model
class SchemeSlabModel {
  final double minQuantity;
  final double maxQuantity;
  final double discountPercentage;
  final double freeQuantity;

  SchemeSlabModel({
    required this.minQuantity,
    required this.maxQuantity,
    required this.discountPercentage,
    required this.freeQuantity,
  });

  factory SchemeSlabModel.fromJson(Map<String, dynamic> json) {
    return SchemeSlabModel(
      minQuantity: (json['minQuantity'] ?? 0.0).toDouble(),
      maxQuantity: (json['maxQuantity'] ?? 999999.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? json['discountPct'] ?? 0.0).toDouble(),
      freeQuantity: (json['freeQuantity'] ?? json['freeQty'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'minQuantity': minQuantity,
    'maxQuantity': maxQuantity,
    'discountPercentage': discountPercentage,
    'freeQuantity': freeQuantity,
  };
}

/// Scheme Model with Flashcard Visual Info
class SchemeModel {
  final String id;
  final String name;
  final String code;
  final String type;
  final String description;
  final String validFrom;
  final String validTo;
  final String applicableProductId;
  final String freeProductId;
  final String freeProductCode;
  final double buyQuantity;
  final double getQuantity;
  final double discountPercentage;
  final double bundlePrice;
  final List<SchemeSlabModel> slabs;

  SchemeModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.description = '',
    this.validFrom = '',
    this.validTo = '',
    this.applicableProductId = '',
    this.freeProductId = '',
    this.freeProductCode = '',
    this.buyQuantity = 0.0,
    this.getQuantity = 0.0,
    this.discountPercentage = 0.0,
    this.bundlePrice = 0.0,
    this.slabs = const [],
  });

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    final slabList = json['slabs'] as List? ?? [];
    return SchemeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'DISCOUNT',
      description: json['description'] ?? '',
      validFrom: json['validFrom'] ?? '',
      validTo: json['validTo'] ?? '',
      applicableProductId: json['applicableProductId'] ?? '',
      freeProductId: json['freeProductId'] ?? '',
      freeProductCode: json['freeProductCode'] ?? '',
      buyQuantity: (json['buyQuantity'] ?? json['buyQty'] ?? 0.0).toDouble(),
      getQuantity: (json['getQuantity'] ?? json['freeQty'] ?? 0.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? json['discountPct'] ?? 0.0).toDouble(),
      bundlePrice: (json['bundlePrice'] ?? 0.0).toDouble(),
      slabs: slabList.map((s) => SchemeSlabModel.fromJson(s)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'type': type,
    'description': description,
    'validFrom': validFrom,
    'validTo': validTo,
    'applicableProductId': applicableProductId,
    'freeProductId': freeProductId,
    'freeProductCode': freeProductCode,
    'buyQuantity': buyQuantity,
    'getQuantity': getQuantity,
    'discountPercentage': discountPercentage,
    'bundlePrice': bundlePrice,
    'slabs': slabs.map((s) => s.toJson()).toList(),
  };
}

/// Dashboard KPI Model
class DashboardKpiModel {
  final double targetRevenue;
  final double achievedRevenue;
  final double achievementPercent;
  final double targetVisits;
  final double completedVisits;
  final int totalOrders;
  final double strikeRatePercent;

  DashboardKpiModel({
    required this.targetRevenue,
    required this.achievedRevenue,
    required this.achievementPercent,
    required this.targetVisits,
    required this.completedVisits,
    required this.totalOrders,
    required this.strikeRatePercent,
  });

  factory DashboardKpiModel.fromJson(Map<String, dynamic> json) {
    return DashboardKpiModel(
      targetRevenue: (json['targetRevenue'] ?? 400000.0).toDouble(),
      achievedRevenue: (json['achievedRevenue'] ?? 250000.0).toDouble(),
      achievementPercent: (json['achievementPercent'] ?? 62.5).toDouble(),
      targetVisits: (json['targetVisits'] ?? 20.0).toDouble(),
      completedVisits: (json['completedVisits'] ?? 14.0).toDouble(),
      totalOrders: (json['totalOrders'] ?? 9).toInt(),
      strikeRatePercent: (json['strikeRatePercent'] ?? 70.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'targetRevenue': targetRevenue,
    'achievedRevenue': achievedRevenue,
    'achievementPercent': achievementPercent,
    'targetVisits': targetVisits,
    'completedVisits': completedVisits,
    'totalOrders': totalOrders,
    'strikeRatePercent': strikeRatePercent,
  };
}

/// Attendance Status Model
class AttendanceStatusModel {
  final bool punchedIn;
  final bool punchedOut;
  final String? checkInTime;
  final String? checkOutTime;
  final double durationHours;
  final double workHours;

  AttendanceStatusModel({
    required this.punchedIn,
    required this.punchedOut,
    this.checkInTime,
    this.checkOutTime,
    this.durationHours = 0.0,
    this.workHours = 8.0,
  });

  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusModel(
      punchedIn: json['punchedIn'] ?? false,
      punchedOut: json['punchedOut'] ?? false,
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      durationHours: (json['durationHours'] ?? 0.0).toDouble(),
      workHours: (json['workHours'] ?? 8.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'punchedIn': punchedIn,
    'punchedOut': punchedOut,
    'checkInTime': checkInTime,
    'checkOutTime': checkOutTime,
    'durationHours': durationHours,
    'workHours': workHours,
  };
}

/// SFA Dynamic Metadata Model (Picklists & Configs)
class SfaMetadataModel {
  final List<String> ticketCategories;
  final List<String> ticketPriorities;
  final List<String> returnReasons;
  final List<String> assetStatuses;
  final List<String> missedVisitReasons;
  final List<String> geofenceBypassReasons;
  final List<String> leaveCategories;
  final List<String> leaveTypes;
  final double geofenceRadiusMeters;

  SfaMetadataModel({
    required this.ticketCategories,
    required this.ticketPriorities,
    required this.returnReasons,
    required this.assetStatuses,
    required this.missedVisitReasons,
    required this.geofenceBypassReasons,
    this.leaveCategories = const ['Sales Executive Leave', 'Customer / Retailer Leave'],
    this.leaveTypes = const ['Casual Leave', 'Sick Leave', 'Annual Leave', 'Half Day', 'Customer / Shop Closed', 'Retailer Vacation', 'Shop Renovation', 'Festival / Holiday', 'Other'],
    this.geofenceRadiusMeters = 100.0,
  });

  factory SfaMetadataModel.fromJson(Map<String, dynamic> json) {
    List<String> listFrom(dynamic src, List<String> def) {
      if (src is List) {
        return src.map((e) => e.toString()).toList();
      }
      return def;
    }

    return SfaMetadataModel(
      ticketCategories: listFrom(json['ticketCategories'], [
        'Billing & Invoice',
        'Damaged / Expired Goods',
        'Trade Scheme Dispute',
        'Delivery Delay',
        'POSM & Assets',
        'Other'
      ]),
      ticketPriorities: listFrom(json['ticketPriorities'], ['Critical', 'High', 'Medium', 'Low']),
      returnReasons: listFrom(json['returnReasons'], [
        'Damaged Packaging',
        'Expired Stock',
        'Near Expiry (<30 days)',
        'Quality Defect',
        'Wrong Delivery'
      ]),
      assetStatuses: listFrom(json['assetStatuses'], ['Operational', 'Damaged', 'Missing', 'Needs Service']),
      missedVisitReasons: listFrom(json['missedVisitReasons'], [
        'Shop Closed',
        'Owner Unavailable',
        'Sufficient Stock / No Requirement',
        'Payment / Outstanding Dispute',
        'Competitor Promotion Conflict',
        'Festival / Local Holiday'
      ]),
      geofenceBypassReasons: listFrom(json['geofenceBypassReasons'], [
        'GPS Accuracy Drift (>50m variance)',
        'Market Inaccessible by Vehicle',
        'Shop Relocated Nearby (Pending Update)',
        'Network Connectivity Issue'
      ]),
      leaveCategories: listFrom(json['leaveCategories'], [
        'Sales Executive Leave',
        'Customer / Retailer Leave'
      ]),
      leaveTypes: listFrom(json['leaveTypes'], [
        'Casual Leave',
        'Sick Leave',
        'Annual Leave',
        'Half Day',
        'Customer / Shop Closed',
        'Retailer Vacation',
        'Shop Renovation',
        'Festival / Holiday',
        'Other'
      ]),
      geofenceRadiusMeters: (json['geofenceRadiusMeters'] ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ticketCategories': ticketCategories,
    'ticketPriorities': ticketPriorities,
    'returnReasons': returnReasons,
    'assetStatuses': assetStatuses,
    'missedVisitReasons': missedVisitReasons,
    'geofenceBypassReasons': geofenceBypassReasons,
    'leaveCategories': leaveCategories,
    'leaveTypes': leaveTypes,
    'geofenceRadiusMeters': geofenceRadiusMeters,
  };
}

/// Leave Request Model (Sales Executive & Customer Closure)
class LeaveRequestModel {
  final String id;
  final String name;
  final String leaveCategory;
  final String leaveType;
  final String? outletId;
  final String? outletName;
  final String? beatId;
  final String? beatName;
  final String? employeeId;
  final String? employeeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalDays;
  final String status;
  final String reason;
  final DateTime createdDate;

  LeaveRequestModel({
    required this.id,
    required this.name,
    required this.leaveCategory,
    required this.leaveType,
    this.outletId,
    this.outletName,
    this.beatId,
    this.beatName,
    this.employeeId,
    this.employeeName,
    this.startDate,
    this.endDate,
    this.totalDays = 1.0,
    this.status = 'Pending Approval',
    this.reason = '',
    required this.createdDate,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      leaveCategory: json['leaveCategory'] ?? 'Sales Executive Leave',
      leaveType: json['leaveType'] ?? 'Casual Leave',
      outletId: json['outletId'],
      outletName: json['outletName'],
      beatId: json['beatId'],
      beatName: json['beatName'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      totalDays: (json['totalDays'] as num?)?.toDouble() ?? 1.0,
      status: json['status'] ?? 'Pending Approval',
      reason: json['reason'] ?? '',
      createdDate: json['createdDate'] != null ? DateTime.tryParse(json['createdDate']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'leaveCategory': leaveCategory,
    'leaveType': leaveType,
    'outletId': outletId,
    'outletName': outletName,
    'beatId': beatId,
    'beatName': beatName,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'totalDays': totalDays,
    'status': status,
    'reason': reason,
    'createdDate': createdDate.toIso8601String(),
  };
}

/// Order Line Item Model
class OrderItemModel {
  final String productId;
  final String productName;
  final String productCode;
  int quantity;
  int freeQuantity;
  final double unitPrice;
  double discountPercent;
  double totalAmount;
  String? appliedSchemeId;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    this.freeQuantity = 0,
    required this.unitPrice,
    this.discountPercent = 0.0,
    required this.totalAmount,
    this.appliedSchemeId,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productCode: json['productCode'] ?? '',
      quantity: (json['quantity'] ?? 0).toInt(),
      freeQuantity: (json['freeQuantity'] ?? 0).toInt(),
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      discountPercent: (json['discountPercent'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      appliedSchemeId: json['appliedSchemeId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productCode': productCode,
    'quantity': quantity,
    'freeQuantity': freeQuantity,
    'unitPrice': unitPrice,
    'discountPercent': discountPercent,
    'totalAmount': totalAmount,
  };
}

/// Local Order Model
class LocalOrderModel {
  final String localId;
  final String retailerId;
  final String retailerName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double gstAmount;
  final double totalAmount;
  final String distributorId;
  final DateTime orderDate;
  String syncStatus;
  String? serverOrderId;
  String? syncMessage;

  LocalOrderModel({
    required this.localId,
    required this.retailerId,
    required this.retailerName,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.gstAmount,
    required this.totalAmount,
    this.distributorId = '',
    required this.orderDate,
    this.syncStatus = 'QUEUED',
    this.serverOrderId,
    this.syncMessage,
  });

  factory LocalOrderModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return LocalOrderModel(
      localId: json['localId'] ?? '',
      retailerId: json['retailerId'] ?? '',
      retailerName: json['retailerName'] ?? '',
      items: list.map((i) => OrderItemModel.fromJson(i)).toList(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      gstAmount: (json['gstAmount'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      distributorId: json['distributorId'] ?? '',
      orderDate: json['orderDate'] != null ? DateTime.tryParse(json['orderDate']) ?? DateTime.now() : DateTime.now(),
      syncStatus: json['syncStatus'] ?? 'QUEUED',
      serverOrderId: json['serverOrderId'],
      syncMessage: json['syncMessage'],
    );
  }

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'retailerId': retailerId,
    'retailerName': retailerName,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'discountAmount': discountAmount,
    'gstAmount': gstAmount,
    'totalAmount': totalAmount,
    'distributorId': distributorId,
    'orderDate': orderDate.toIso8601String(),
    'syncStatus': syncStatus,
    'serverOrderId': serverOrderId,
    'syncMessage': syncMessage,
  };
}

/// Visit Model
class VisitModel {
  final String retailerId;
  final String retailerName;
  final DateTime checkInTime;
  DateTime? checkOutTime;
  bool isCompleted;
  bool isSkipped;
  String skipReason;
  String? serverVisitId;

  VisitModel({
    required this.retailerId,
    required this.retailerName,
    required this.checkInTime,
    this.checkOutTime,
    this.isCompleted = false,
    this.isSkipped = false,
    this.skipReason = '',
    this.serverVisitId,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      retailerId: json['retailerId'] ?? '',
      retailerName: json['retailerName'] ?? '',
      checkInTime: DateTime.tryParse(json['checkInTime'] ?? '') ?? DateTime.now(),
      checkOutTime: json['checkOutTime'] != null ? DateTime.tryParse(json['checkOutTime']) : null,
      isCompleted: json['isCompleted'] ?? false,
      isSkipped: json['isSkipped'] ?? false,
      skipReason: json['skipReason'] ?? '',
      serverVisitId: json['serverVisitId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'retailerId': retailerId,
    'retailerName': retailerName,
    'checkInTime': checkInTime.toIso8601String(),
    'checkOutTime': checkOutTime?.toIso8601String(),
    'isCompleted': isCompleted,
    'isSkipped': isSkipped,
    'skipReason': skipReason,
    'serverVisitId': serverVisitId,
  };
}

/// Support Ticket Model
class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String outletId;
  final String outletName;
  final String beatName;
  final String category;
  final String priority;
  final String subject;
  final String description;
  final String status;
  final DateTime createdDate;

  SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.outletId,
    required this.outletName,
    required this.beatName,
    required this.category,
    required this.priority,
    required this.subject,
    required this.description,
    this.status = 'Open',
    required this.createdDate,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      outletId: json['outletId'] ?? '',
      outletName: json['outletName'] ?? '',
      beatName: json['beatName'] ?? '',
      category: json['category'] ?? 'Billing & Invoice',
      priority: json['priority'] ?? 'Medium',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Open',
      createdDate: json['createdDate'] != null ? DateTime.tryParse(json['createdDate']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketNumber': ticketNumber,
    'outletId': outletId,
    'outletName': outletName,
    'beatName': beatName,
    'category': category,
    'priority': priority,
    'subject': subject,
    'description': description,
    'status': status,
    'createdDate': createdDate.toIso8601String(),
  };
}

/// Competitor Activity Model
class CompetitorActivityModel {
  final String brandName;
  final String productName;
  final double mrp;
  final String promoScheme;
  final double shelfSharePercent;
  final String notes;

  CompetitorActivityModel({
    required this.brandName,
    required this.productName,
    required this.mrp,
    required this.promoScheme,
    required this.shelfSharePercent,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'brandName': brandName,
    'productName': productName,
    'mrp': mrp,
    'promoScheme': promoScheme,
    'shelfSharePercent': shelfSharePercent,
    'notes': notes,
  };
}

/// Product Return Item Model
class ProductReturnModel {
  final String productId;
  final String productName;
  final int quantity;
  final String reason;
  final String batchNumber;
  final double creditAmount;

  ProductReturnModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
    required this.batchNumber,
    required this.creditAmount,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'reason': reason,
    'batchNumber': batchNumber,
    'creditAmount': creditAmount,
  };
}

class TargetModel {
  final String id;
  final String name;
  final String type; // 'Monthly', 'Daywise', 'Outlet Type'
  final String period;
  final double targetRevenue;
  final double achievedRevenue;
  final double targetVolume;
  final double achievedVolume;
  final double targetVisits;
  final double achievedVisits;
  final double achievementPercent;

  TargetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.period,
    required this.targetRevenue,
    required this.achievedRevenue,
    required this.targetVolume,
    required this.achievedVolume,
    required this.targetVisits,
    required this.achievedVisits,
    required this.achievementPercent,
  });

  factory TargetModel.fromJson(Map<String, dynamic> json) {
    return TargetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Monthly',
      period: json['period'] ?? '',
      targetRevenue: (json['targetRevenue'] ?? 0.0).toDouble(),
      achievedRevenue: (json['achievedRevenue'] ?? 0.0).toDouble(),
      targetVolume: (json['targetVolume'] ?? 0.0).toDouble(),
      achievedVolume: (json['achievedVolume'] ?? 0.0).toDouble(),
      targetVisits: (json['targetVisits'] ?? 0.0).toDouble(),
      achievedVisits: (json['achievedVisits'] ?? 0.0).toDouble(),
      achievementPercent: (json['achievementPercent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'period': period,
    'targetRevenue': targetRevenue,
    'achievedRevenue': achievedRevenue,
    'targetVolume': targetVolume,
    'achievedVolume': achievedVolume,
    'targetVisits': targetVisits,
    'achievedVisits': achievedVisits,
    'achievementPercent': achievementPercent,
  };
}

class AttendanceModel {
  final String id;
  final String dayType; // 'FULL_DAY', 'HALF_DAY'
  final DateTime punchInTime;
  final DateTime? punchOutTime;
  final String status;
  final double totalDistanceKm;
  final int batteryLevel;

  AttendanceModel({
    required this.id,
    this.dayType = 'FULL_DAY',
    required this.punchInTime,
    this.punchOutTime,
    this.status = 'PRESENT',
    this.totalDistanceKm = 0.0,
    this.batteryLevel = 90,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      dayType: json['dayType'] ?? 'FULL_DAY',
      punchInTime: json['punchInTime'] != null
          ? DateTime.tryParse(json['punchInTime']) ?? DateTime.now()
          : DateTime.now(),
      punchOutTime: json['punchOutTime'] != null
          ? DateTime.tryParse(json['punchOutTime'])
          : null,
      status: json['status'] ?? 'PRESENT',
      totalDistanceKm: (json['totalDistanceKm'] ?? 0.0).toDouble(),
      batteryLevel: json['batteryLevel'] ?? 90,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayType': dayType,
    'punchInTime': punchInTime.toIso8601String(),
    'punchOutTime': punchOutTime?.toIso8601String(),
    'status': status,
    'totalDistanceKm': totalDistanceKm,
    'batteryLevel': batteryLevel,
  };
}

/// Live Attendance Record for a specific date from Salesforce
class AttendanceRecordModel {
  final String id;
  final String date;
  final String? startTime;
  final String? endTime;
  final String status;
  final double workHours;
  final String? geoLocation;
  final bool isDayActive;
  final String? employeeName;

  AttendanceRecordModel({
    required this.id,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    this.workHours = 0.0,
    this.geoLocation,
    this.isDayActive = false,
    this.employeeName,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? '',
      date: json['attendanceDate'] ?? '',
      startTime: json['startTime'],
      endTime: json['endTime'],
      status: json['status'] ?? 'Not Marked',
      workHours: (json['totalWorkingHours'] as num?)?.toDouble() ?? 0.0,
      geoLocation: json['geoLocation'],
      isDayActive: json['isDayActive'] ?? false,
      employeeName: json['employeeName'],
    );
  }
}

class ExpenseModel {
  final String id;
  final DateTime date;
  final double distanceKm;
  final double travelAllowance;
  final double dailyAllowance;
  final double totalAmount;
  final String dayType;
  final String status; // 'SUBMITTED', 'APPROVED'

  ExpenseModel({
    required this.id,
    required this.date,
    required this.distanceKm,
    required this.travelAllowance,
    required this.dailyAllowance,
    required this.totalAmount,
    this.dayType = 'FULL_DAY',
    this.status = 'SUBMITTED',
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
      travelAllowance: (json['travelAllowance'] ?? 0.0).toDouble(),
      dailyAllowance: (json['dailyAllowance'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      dayType: json['dayType'] ?? 'FULL_DAY',
      status: json['status'] ?? 'SUBMITTED',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'distanceKm': distanceKm,
    'travelAllowance': travelAllowance,
    'dailyAllowance': dailyAllowance,
    'totalAmount': totalAmount,
    'dayType': dayType,
    'status': status,
  };
}

