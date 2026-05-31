// lib/services/supabase_service.dart
// ══════════════════════════════════════════════════════════════
// Feez — Service Supabase central
// Toutes les requêtes BDD passent par ici
// ══════════════════════════════════════════════════════════════

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class SupabaseService {
  static final _sb = Supabase.instance.client;

  // ── Singleton ─────────────────────────────────────────────
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  // ── Auth ──────────────────────────────────────────────────

  /// Envoyer un code OTP par SMS
  static Future<void> sendOtp(String phone) async {
    await _sb.auth.signInWithOtp(phone: phone);
  }

  /// Vérifier le code OTP reçu par SMS
  static Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _sb.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Déconnexion
  static Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  /// Utilisateur courant
  static User? get currentUser => _sb.auth.currentUser;

  /// Stream de changements d'auth
  static Stream<AuthState> get authStream => _sb.auth.onAuthStateChange;

  // ── Profil utilisateur ────────────────────────────────────

  /// Créer ou mettre à jour le profil après connexion OTP
  static Future<void> upsertUserProfile({
    required String phone,
    String? firstName,
    String? lastName,
    String? email,
    String? fcmToken,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await _sb.from('users').upsert({
      'id':         user.id,
      'phone':      phone,
      'first_name': firstName,
      'last_name':  lastName,
      'email':      email,
      'fcm_token':  fcmToken,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Lire le profil de l'utilisateur courant
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final res = await _sb
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return res;
  }

  /// Sauvegarder une adresse
  static Future<void> saveAddress({
    required String address,
    required double lat,
    required double lng,
    String? label,
    String? zone,
    bool isDefault = false,
  }) async {
    final user = currentUser;
    if (user == null) return;

    // Si adresse par défaut → retirer le flag des autres
    if (isDefault) {
      await _sb
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', user.id);
    }

    await _sb.from('user_addresses').insert({
      'user_id':    user.id,
      'label':      label,
      'address':    address,
      'lat':        lat,
      'lng':        lng,
      'zone':       zone,
      'is_default': isDefault,
    });
  }

  /// Récupérer les adresses de l'utilisateur
  static Future<List<Map<String, dynamic>>> getUserAddresses() async {
    final user = currentUser;
    if (user == null) return [];

    final res = await _sb
        .from('user_addresses')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // ── Produits ──────────────────────────────────────────────

  /// Récupérer tous les produits disponibles avec leur stock
  static Future<List<ProductModel>> getProducts({String? categoryName}) async {
    String? categoryId;

    if (categoryName != null) {
      final catRes = await _sb
          .from('categories')
          .select('id')
          .eq('name', categoryName)
          .single();
      categoryId = catRes['id'] as String?;
    }

    var query = _sb
        .from('products')
        .select('''
          *,
          categories (id, name, display_name, icon),
          inventory (quantity, reserved, alert_threshold)
        ''')
        .eq('is_available', true);

    if (categoryId != null) {
      final data = await query.eq('category_id', categoryId).order('sort_order');
      return data.map((p) => ProductModel.fromJson(p)).toList();
    }

    final data = await query.order('sort_order');
    return data.map((p) => ProductModel.fromJson(p)).toList();
  }

  /// Récupérer les catégories actives
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await _sb
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    // Tri côté Dart : sort_order non-null d'abord (croissant), null en dernier
    final list = List<Map<String, dynamic>>.from(res);
    list.sort((a, b) {
      final aSO = a['sort_order'] as int?;
      final bSO = b['sort_order'] as int?;
      if (aSO == null && bSO == null) return 0;
      if (aSO == null) return 1;
      if (bSO == null) return -1;
      return aSO.compareTo(bSO);
    });
    return list;
  }

  /// Rechercher des produits
  static Future<List<ProductModel>> searchProducts(String query) async {
    final res = await _sb
        .from('products')
        .select('*, categories(name, display_name, icon), inventory(*)')
        .eq('is_available', true)
        .ilike('name', '%$query%');
    return res.map((p) => ProductModel.fromJson(p)).toList();
  }

  // ── Restaurants ───────────────────────────────────────────

  /// Récupérer les restaurants actifs
  static Future<List<Map<String, dynamic>>> getRestaurants() async {
    final res = await _sb
        .from('restaurants')
        .select()
        .eq('is_active', true)
        .order('rating', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Récupérer le menu d'un restaurant
  static Future<List<Map<String, dynamic>>> getMenuItems(String restaurantId) async {
    final res = await _sb
        .from('menu_items')
        .select('*, menu_categories(name)')
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(res);
  }

  // ── Commandes ─────────────────────────────────────────────

  /// Passer une commande Market
  static Future<Map<String, dynamic>> createMarketOrder({
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String deliveryZone,
    required String paymentMethod,
    String? promoCode,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Non connecté');

    final deliveryFee = 200;
    final discount = promoCode != null ? 0 : 0; // TODO: calculer promo
    final total = subtotal + deliveryFee - discount;

    final res = await _sb
        .from('orders')
        .insert({
          'type':             'market',
          'user_id':          user.id,
          'status':           'pending',
          'items':            items,
          'subtotal':         subtotal,
          'delivery_fee':     deliveryFee,
          'discount':         discount,
          'total':            total,
          'delivery_address': deliveryAddress,
          'delivery_lat':     deliveryLat,
          'delivery_lng':     deliveryLng,
          'delivery_zone':    deliveryZone,
          'payment_method':   paymentMethod,
          'payment_status':   'pending',
          'promo_code':       promoCode,
        })
        .select()
        .single();

    // Décrémenter le stock pour chaque article
    for (final item in items) {
      await _sb.rpc('decrement_stock', params: {
        'p_id': item['product_id'],
        'qty':  item['qty'],
      });
    }

    return res;
  }

  /// Passer une commande Food
  static Future<Map<String, dynamic>> createFoodOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required int subtotal,
    required String deliveryAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String paymentMethod,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Non connecté');

    final total = subtotal + 200;

    final res = await _sb
        .from('orders')
        .insert({
          'type':             'food',
          'user_id':          user.id,
          'restaurant_id':    restaurantId,
          'status':           'pending',
          'items':            items,
          'subtotal':         subtotal,
          'delivery_fee':     200,
          'total':            total,
          'delivery_address': deliveryAddress,
          'delivery_lat':     deliveryLat,
          'delivery_lng':     deliveryLng,
          'payment_method':   paymentMethod,
          'payment_status':   'pending',
        })
        .select()
        .single();

    return res;
  }

  /// Récupérer les commandes de l'utilisateur courant
  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    final user = currentUser;
    if (user == null) return [];

    final res = await _sb
        .from('orders')
        .select('*, riders(first_name, last_name), restaurants(name)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  /// Écouter les mises à jour d'une commande en temps réel
  static RealtimeChannel listenToOrder(
    String orderId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return _sb
        .channel('order_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Écouter la position GPS du livreur en temps réel
  static RealtimeChannel listenToRiderLocation(
    String riderId,
    void Function(double lat, double lng) onLocationUpdate,
  ) {
    return _sb
        .channel('rider_$riderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'riders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: riderId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data['lat'] != null && data['lng'] != null) {
              onLocationUpdate(data['lat'], data['lng']);
            }
          },
        )
        .subscribe();
  }

  // ── Promotions ────────────────────────────────────────────

  /// Vérifier un code promo
  static Future<Map<String, dynamic>?> checkPromoCode(
    String code,
    int orderTotal,
  ) async {
    final res = await _sb
        .from('promotions')
        .select()
        .eq('code', code.toUpperCase())
        .eq('is_active', true)
        .maybeSingle();

    if (res == null) return null;

    // Vérifier expiration
    if (res['expires_at'] != null) {
      final expiry = DateTime.parse(res['expires_at']);
      if (DateTime.now().isAfter(expiry)) return null;
    }

    // Vérifier commande minimum
    if (orderTotal < (res['min_order'] ?? 0)) return null;

    return res;
  }

  /// Calculer la réduction d'un code promo
  static int calculateDiscount(Map<String, dynamic> promo, int orderTotal) {
    switch (promo['type']) {
      case 'percent':
        final discount = (orderTotal * promo['value'] / 100).round();
        final maxDiscount = promo['max_discount'] as int?;
        return maxDiscount != null ? discount.clamp(0, maxDiscount) : discount;
      case 'fixed':
        return (promo['value'] as num).toInt();
      case 'free_delivery':
        return 200; // Frais de livraison offerts
      default:
        return 0;
    }
  }

  // ── Zones de livraison ────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDeliveryZones() async {
    final res = await _sb
        .from('delivery_zones')
        .select()
        .eq('is_active', true)
        .order('delivery_fee');
    return List<Map<String, dynamic>>.from(res);
  }
}
