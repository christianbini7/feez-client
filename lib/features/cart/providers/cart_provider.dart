import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Mode de l'app ────────────────────────────────────────────────
enum AppMode { market, food }

final modeProvider = StateProvider<AppMode>((ref) => AppMode.market);

// ── Panier Market : {product_id: qty} ────────────────────────────
class MarketCartNotifier extends StateNotifier<Map<String, int>> {
  MarketCartNotifier() : super({});

  void add(String productId) {
    state = {...state, productId: (state[productId] ?? 0) + 1};
  }

  void remove(String productId) {
    if (!state.containsKey(productId)) return;
    final newQty = state[productId]! - 1;
    if (newQty <= 0) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId: newQty};
    }
  }

  void removeAll(String productId) {
    state = {...state}..remove(productId);
  }

  int getQty(String productId) => state[productId] ?? 0;

  int get totalItems => state.values.fold(0, (a, b) => a + b);

  void clear() => state = {};
}

final marketCartProvider = StateNotifierProvider<MarketCartNotifier, Map<String, int>>(
  (ref) => MarketCartNotifier(),
);

// ── Panier Food : {item_id: FoodCartItem} ────────────────────────
class FoodCartItem {
  final String id;
  final String name;
  final String restoName;
  final int price;
  final int qty;
  final String? imageUrl;  // ← ajouter ce champ

  const FoodCartItem({
    required this.id,
    required this.name,
    required this.restoName,
    required this.price,
    required this.qty,
    this.imageUrl,          // ← ajouter ici
  });

  FoodCartItem copyWith({int? qty}) => FoodCartItem(
    id: id, name: name, restoName: restoName,
    price: price, qty: qty ?? this.qty,
    imageUrl: imageUrl,     // ← ajouter ici
  );
}

class FoodCartNotifier extends StateNotifier<Map<String, FoodCartItem>> {
  FoodCartNotifier() : super({});

  void add(String key, FoodCartItem item) {
    final existing = state[key];
    if (existing != null) {
      state = {...state, key: existing.copyWith(qty: existing.qty + 1)};
    } else {
      state = {...state, key: item};
    }
  }

  void remove(String key) {
    final existing = state[key];
    if (existing == null) return;
    if (existing.qty <= 1) {
      state = {...state}..remove(key);
    } else {
      state = {...state, key: existing.copyWith(qty: existing.qty - 1)};
    }
  }

  int get totalItems => state.values.fold(0, (a, v) => a + v.qty);

  int get totalPrice => state.values.fold(0, (a, v) => a + v.price * v.qty);

  void clear() => state = {};
}

final foodCartProvider = StateNotifierProvider<FoodCartNotifier, Map<String, FoodCartItem>>(
  (ref) => FoodCartNotifier(),
);

// ── Helper: total Market ─────────────────────────────────────────
final marketTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(marketCartProvider).values.fold(0, (a, b) => a + b);
});

// ── Helper: total Food ─────────────────────────────────────────
final foodTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(foodCartProvider).values.fold(0, (a, v) => a + v.qty);
});

final foodTotalPriceProvider = Provider<int>((ref) {
  return ref.watch(foodCartProvider).values.fold(0, (a, v) => a + v.price * v.qty);
});