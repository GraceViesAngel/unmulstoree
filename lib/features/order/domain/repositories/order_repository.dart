import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pab/features/order/data/models/order_model.dart';
import 'package:pab/features/order/data/models/cart_item_model.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  Future<List<OrderModel>> getUserOrders({
    bool? isRental,
    String? status,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId);

      if (isRental != null) {
        if (isRental) {
          query = query.eq('is_rental', true);
        } else {
          query = query.or('is_rental.is.null,is_rental.eq.false');
        }
      }

      final response = await query.order('created_at', ascending: false);
      var orders = (response as List)
          .map((e) => OrderModel.fromMap(e))
          .toList();

      if (status != null && status != 'Semua') {
        if (status == 'Dikirim') {
          orders = orders
              .where((o) => o.status == 'Dikirim' || o.status == 'Siap Diambil')
              .toList();
        } else if (status == 'Ditolak_Gabungan') {
          orders = orders
              .where(
                (o) =>
                    o.status == 'Ditolak' || o.status == 'Menunggu Pembatalan',
              )
              .toList();
        } else {
          orders = orders.where((o) => o.status == status).toList();
        }
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<OrderModel> createOrder({
    required String productId,
    required String productTitle,
    required String? imagePath,
    required int quantity,
    required int price,
    required bool isRental,
    required String variation,
    required String paymentMethod,
    int deposit = 0,
    int rentalDuration = 0,
    int lateFee = 0,
    int shippingCost = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final orderIdDisplay =
          'ORD-${now.millisecondsSinceEpoch.toString().substring(5)}';

      final orderData = {
        'user_id': userId,
        'order_id_display': orderIdDisplay,
        'status': 'Menunggu Verifikasi',
        'total_price': (price * quantity) + deposit + shippingCost,
        'is_rental': isRental,
        'payment_method': paymentMethod,
        'deposit': deposit,
        'rental_duration': rentalDuration,
        'late_fee': lateFee,
        'shipping_cost': shippingCost,
      };

      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': productId,
        'product_title': productTitle,
        'image_path': imagePath,
        'variation': variation,
        'quantity': quantity,
        'price': price,
      });

      return OrderModel.fromMap(orderResponse);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<OrderModel> createOrderFromCart({
    required List<CartItemModel> items,
    required bool isRental,
    required String paymentMethod,
    int deposit = 0,
    int rentalDuration = 0,
    int lateFee = 0,
    int shippingCost = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      if (items.isEmpty) throw Exception('No items to order');

      final now = DateTime.now();
      final orderIdDisplay =
          'ORD-${now.millisecondsSinceEpoch.toString().substring(5)}';

      final totalPrice = items.fold<int>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      final orderData = {
        'user_id': userId,
        'order_id_display': orderIdDisplay,
        'status': 'Menunggu Verifikasi',
        'total_price': totalPrice + deposit + shippingCost,
        'is_rental': isRental,
        'payment_method': paymentMethod,
        'deposit': deposit,
        'rental_duration': rentalDuration,
        'late_fee': lateFee,
        'shipping_cost': shippingCost,
      };

      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      for (var item in items) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.productId,
          'product_title': item.product?.title ?? '',
          'image_path': item.product?.imagePath,
          'variation': item.variation,
          'quantity': item.quantity,
          'price': item.product?.price ?? 0,
        });
      }

      return OrderModel.fromMap(orderResponse);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    await _supabase.from('orders').delete().eq('id', orderId);
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();
      return OrderModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<void> markAsDelivered(String orderId, int durationDays) async {
    try {
      final now = DateTime.now();
      final deadline = now.add(Duration(days: durationDays));
      
      await _supabase
          .from('orders')
          .update({
            'status': 'Dalam Masa Sewa',
            'delivered_at': now.toIso8601String(),
            'return_deadline': deadline.toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to mark as delivered: $e');
    }
  }

  Future<void> submitReturnResi(String orderId, String resi) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'Dikirim Balik',
            'return_resi': resi,
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to submit return resi: $e');
    }
  }

  Future<void> requestCancellation(
    String orderId, {
    required String reason,
  }) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'Menunggu Pembatalan',
            'cancellation_reason': reason,
            'cancellation_requested_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to request cancellation: $e');
    }
  }
}
