class OrderModel {
  final String id;
  final String userId;
  final String orderIdDisplay;
  final String status;
  final String? statusColor;
  final String? statusTextColor;
  final int totalPrice;
  final bool isRental;
  final String paymentMethod;
  final String? resi;
  final int deposit;
  final int rentalDuration;
  final DateTime? deliveredAt;
  final DateTime? returnDeadline;
  final String? returnResi;
  final int lateFee;
  final int shippingCost;
  final DateTime createdAt;
  final List<OrderItemModel>? items;
  /// Alasan penolakan verifikasi oleh admin (status Ditolak).
  final String? rejectionReason;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderIdDisplay,
    required this.status,
    this.statusColor,
    this.statusTextColor,
    required this.totalPrice,
    required this.isRental,
    this.paymentMethod = 'COD',
    this.resi,
    this.deposit = 0,
    this.rentalDuration = 0,
    this.deliveredAt,
    this.returnDeadline,
    this.returnResi,
    this.lateFee = 0,
    this.shippingCost = 0,
    required this.createdAt,
    this.items,
    this.rejectionReason,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id'] ?? '',
      orderIdDisplay: map['order_id_display'] ?? '',
      status: map['status'] ?? 'Menunggu Verifikasi',
      statusColor: map['status_color'],
      statusTextColor: map['status_text_color'],
      totalPrice: map['total_price'] ?? 0,
      isRental: map['is_rental'] ?? false,
      paymentMethod: map['payment_method'] ?? 'COD',
      resi: map['resi'],
      deposit: map['deposit'] ?? 0,
      rentalDuration: map['rental_duration'] ?? 0,
      deliveredAt: map['delivered_at'] != null ? DateTime.parse(map['delivered_at']) : null,
      returnDeadline: map['return_deadline'] != null ? DateTime.parse(map['return_deadline']) : null,
      returnResi: map['return_resi'],
      lateFee: map['late_fee'] ?? 0,
      shippingCost: map['shipping_cost'] ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      items: map['order_items'] != null
          ? (map['order_items'] as List)
                .map((e) => OrderItemModel.fromMap(e))
                .toList()
          : null,
      rejectionReason: map['rejection_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'order_id_display': orderIdDisplay,
      'status': status,
      'total_price': totalPrice,
      'is_rental': isRental,
      'payment_method': paymentMethod,
      'resi': resi,
      'deposit': deposit,
      'rental_duration': rentalDuration,
      'delivered_at': deliveredAt?.toIso8601String(),
      'return_deadline': returnDeadline?.toIso8601String(),
      'return_resi': returnResi,
      'late_fee': lateFee,
      'shipping_cost': shippingCost,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String? productId;
  final String productTitle;
  final String? imagePath;
  final String? variation;
  final int quantity;
  final int price;

  OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productTitle,
    this.imagePath,
    this.variation,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id'] ?? '',
      productId: map['product_id'],
      productTitle: map['product_title'] ?? '',
      imagePath: map['image_path'],
      variation: map['variation'],
      quantity: map['quantity'] ?? 1,
      price: map['price'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_title': productTitle,
      'image_path': imagePath,
      'variation': variation,
      'quantity': quantity,
      'price': price,
    };
  }
}
