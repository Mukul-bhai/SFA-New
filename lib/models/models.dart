
class RetailerModel {
  final String id;
  final String code;
  final String name;
  final String shopName;
  final String phone;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final double outstandingBalance;
  final double creditLimit;
  final bool creditHold;
  final String primaryDistributorId;

  RetailerModel({
    required this.id,
    required this.code,
    required this.name,
    required this.shopName,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    required this.outstandingBalance,
    required this.creditLimit,
    required this.creditHold,
    required this.primaryDistributorId,
  });

  factory RetailerModel.fromJson(Map<String, dynamic> json) {
    return RetailerModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      shopName: json['shopName'] ?? '',
      phone: json['phone'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      geofenceRadius: (json['geofenceRadius'] ?? 100.0).toDouble(),
      outstandingBalance: (json['outstandingBalance'] ?? 0.0).toDouble(),
      creditLimit: (json['creditLimit'] ?? 10000.0).toDouble(),
      creditHold: json['creditHold'] ?? false,
      primaryDistributorId: json['primaryDistributorId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'shopName': shopName,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
    'geofenceRadius': geofenceRadius,
    'outstandingBalance': outstandingBalance,
    'creditLimit': creditLimit,
    'creditHold': creditHold,
    'primaryDistributorId': primaryDistributorId,
  };
}

class BeatModel {
  final String id;
  final String name;
  final String dayOfWeek;
  final List<String> retailerIds;

  BeatModel({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.retailerIds,
  });

  factory BeatModel.fromJson(Map<String, dynamic> json) {
    return BeatModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      retailerIds: List<String>.from(json['retailerIds'] ?? []),
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String productCode;
  final String description;
  final double unitPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.productCode,
    required this.description,
    this.unitPrice = 120.0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      productCode: json['productCode'] ?? '',
      description: json['description'] ?? '',
      unitPrice: (json['unitPrice'] ?? 120.0).toDouble(),
    );
  }
}

class LocalOrderModel {
  final String localId; // UUID
  final String retailerId;
  final String retailerName;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final DateTime orderDate;
  String syncStatus; // 'QUEUED', 'SYNCED', 'FAILED'
  String? serverOrderId;
  String? syncMessage;

  LocalOrderModel({
    required this.localId,
    required this.retailerId,
    required this.retailerName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.orderDate,
    this.syncStatus = 'QUEUED',
    this.serverOrderId,
    this.syncMessage,
  });

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'retailerId': retailerId,
    'retailerName': retailerName,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalAmount': totalAmount,
    'orderDate': orderDate.toIso8601String(),
    'syncStatus': syncStatus,
    'serverOrderId': serverOrderId,
    'syncMessage': syncMessage,
  };

  factory LocalOrderModel.fromJson(Map<String, dynamic> json) => LocalOrderModel(
    localId: json['localId'],
    retailerId: json['retailerId'],
    retailerName: json['retailerName'],
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    unitPrice: json['unitPrice'].toDouble(),
    totalAmount: json['totalAmount'].toDouble(),
    orderDate: DateTime.parse(json['orderDate']),
    syncStatus: json['syncStatus'],
    serverOrderId: json['serverOrderId'],
    syncMessage: json['syncMessage'],
  );
}
