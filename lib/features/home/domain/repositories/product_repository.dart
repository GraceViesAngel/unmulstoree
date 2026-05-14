import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pab/features/home/data/models/product_model.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;

  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      var query = _supabase.from('products').select();

      if (category == 'Sewa') {
        query = query.eq('is_rentable', true);
      } else if (category == 'Beli') {
        query = query.eq('is_rentable', false);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  Future<List<ProductModel>> getProductsFiltered({
    String? category,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from('products').select();

      if (category == 'Sewa') {
        query = query.eq('is_rentable', true);
      } else if (category == 'Beli') {
        query = query.eq('is_rentable', false);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }
}
