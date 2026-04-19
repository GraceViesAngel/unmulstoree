import '../../../home/data/models/product_model.dart';

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final String? variation;
  final ProductModel? product;
  bool isSelected;
  final bool isRental;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.variation,
    this.product,
    this.isSelected = false,
    this.isRental = false,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id'] ?? '',
      productId: map['product_id'] ?? '',
      quantity: map['quantity'] ?? 1,
      variation: map['variation'],
      product: map['products'] != null
          ? ProductModel.fromMap(map['products'])
          : null,
      isRental: map['is_rental'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'variation': variation,
      'is_rental': isRental,
    };
  }

  int get totalPrice {
    if (isRental && product != null) {
      return product!.price + (product!.deposit * quantity);
    }
    return (product?.price ?? 0) * quantity;
  }
}
