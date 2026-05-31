// lib/features/orders/providers/order_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

final userOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await SupabaseService.getUserOrders();
});

class OrderNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  OrderNotifier() : super(const AsyncData(null));

  Future<Map<String, dynamic>?> placeMarketOrder({
    required Map<String, int> cart,
    required List<dynamic> products,
    required String deliveryAddress,
    required double lat,
    required double lng,
    required String zone,
    required String paymentMethod,
    String? promoCode,
  }) async {
    state = const AsyncLoading();
    try {
      final items = cart.entries.map((e) {
        try {
          final product = products.firstWhere((p) => p.id == e.key);
          return {
            'product_id': e.key,
            'name':       product.name,
            'emoji':      product.emoji ?? '📦',
            'qty':        e.value,
            'price':      product.price,
            'subtotal':   product.price * e.value,
          };
        } catch (_) { return null; }
      }).whereType<Map<String, dynamic>>().toList();

      final subtotal = items.fold<int>(0, (sum, i) => sum + (i['subtotal'] as int));

      final order = await SupabaseService.createMarketOrder(
        items:           items,
        subtotal:        subtotal,
        deliveryAddress: deliveryAddress,
        deliveryLat:     lat,
        deliveryLng:     lng,
        deliveryZone:    zone,
        paymentMethod:   paymentMethod,
        promoCode:       promoCode,
      );
      state = AsyncData(order);
      return order;
    } catch (e, s) {
      state = AsyncError(e, s);
      return null;
    }
  }

  void reset() => state = const AsyncData(null);
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, AsyncValue<Map<String, dynamic>?>>(
  (ref) => OrderNotifier(),
);

final orderTrackingProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, orderId) {
  final controller = StreamController<Map<String, dynamic>>.broadcast();

  Supabase.instance.client
      .from('orders')
      .select('*, riders(first_name, last_name, lat, lng)')
      .eq('id', orderId)
      .single()
      .then(controller.add)
      .catchError((e) => controller.addError(e));

  final channel = SupabaseService.listenToOrder(orderId, controller.add);

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
