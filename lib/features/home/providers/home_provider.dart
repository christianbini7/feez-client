// lib/features/home/providers/home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../services/supabase_service.dart';

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return await SupabaseService.getProducts();
});

final productsByCategoryProvider = FutureProvider.family<List<ProductModel>, String>(
  (ref, categoryName) async => await SupabaseService.getProducts(categoryName: categoryName),
);

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await SupabaseService.getCategories();
});

final restaurantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await SupabaseService.getRestaurants();
});

class SearchNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  SearchNotifier() : super(const AsyncData([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) { state = const AsyncData([]); return; }
    state = const AsyncLoading();
    try {
      final results = await SupabaseService.searchProducts(query);
      state = AsyncData(results);
    } catch (e, s) { state = AsyncError(e, s); }
  }

  void clear() => state = const AsyncData([]);
}

final searchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<ProductModel>>>(
  (ref) => SearchNotifier(),
);
