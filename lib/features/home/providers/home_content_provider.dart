import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/home_models.dart';

final promosProvider = FutureProvider<List<PromoModel>>((ref) async {
  try {
    final res = await Supabase.instance.client
      .from('promos')
      .select()
      .eq('active', true)
      .order('sort_order', ascending: true);
    final now = DateTime.now();
    return (res as List)
      .map((m) => PromoModel.fromMap(m as Map<String, dynamic>))
      .where((p) => p.expiresAt == null || p.expiresAt!.isAfter(now))
      .toList();
  } catch (_) {
    return [];
  }
});

final shortcutsProvider = FutureProvider<List<ShortcutModel>>((ref) async {
  try {
    final res = await Supabase.instance.client
      .from('shortcuts')
      .select()
      .eq('active', true)
      .order('sort_order', ascending: true);
    return (res as List)
      .map((m) => ShortcutModel.fromMap(m as Map<String, dynamic>))
      .toList();
  } catch (_) {
    return [];
  }
});
