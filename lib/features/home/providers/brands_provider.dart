import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand_model.dart';

final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  try {
    final res = await Supabase.instance.client
      .from('brands')
      .select()
      .eq('active', true)
      .order('sort_order', ascending: true);
    return (res as List).map((m) => BrandModel.fromMap(m as Map<String,dynamic>)).toList();
  } catch (e) {
    return [];
  }
});
