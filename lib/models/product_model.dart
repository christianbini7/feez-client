// lib/models/product_model.dart

class ProductModel {
  final String id;
  final String name;
  final String category;
  final String? categoryId;   // UUID Supabase
  final int    price;
  final int?   oldPrice;
  final int    stock;
  final String emoji;
  final String? imageUrl;    // Première image (URL Supabase Storage)
  final List<String> images; // Toutes les images
  final String unit;
  final String? tag;
  final String? description;
  final bool   isAvailable;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    this.categoryId,
    required this.price,
    this.oldPrice,
    required this.stock,
    required this.emoji,
    this.imageUrl,
    this.images = const [],
    required this.unit,
    this.tag,
    this.description,
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Construire la liste d'images
    final rawImages = json['images'];
    List<String> imgList = [];
    if (rawImages is List) {
      imgList = rawImages.map((e) => e.toString()).toList();
    }

    // image_url seul → l'ajouter en première position si pas déjà dans images
    final singleUrl = json['image_url'] as String?;
    if (singleUrl != null && singleUrl.isNotEmpty && !imgList.contains(singleUrl)) {
      imgList.insert(0, singleUrl);
    }

    // Première image = imageUrl principal
    final primaryImage = imgList.isNotEmpty ? imgList[0] : null;

    // Catégorie depuis le join ou direct
    String cat = '';
    if (json['categories'] is Map) {
      cat = (json['categories'] as Map)['name'] ?? '';
    } else {
      cat = json['category'] ?? '';
    }

    return ProductModel(
      id:          json['id'] ?? '',
      name:        json['name'] ?? '',
      category:    cat,
      categoryId:  json['category_id'] as String?,
      price:       json['price'] ?? 0,
      oldPrice:    json['old_price'],
      stock:       (json['inventory'] is Map)
                     ? ((json['inventory'] as Map)['quantity'] ?? 0)
                     : (json['stock'] ?? 0),
      emoji:       json['emoji'] ?? '📦',
      imageUrl:    primaryImage ?? singleUrl,
      images:      imgList,
      unit:        json['unit'] ?? '',
      tag:         json['tag'],
      description: json['description'],
      isAvailable: json['is_available'] ?? true,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  /// Première image disponible
  String? get primaryImage => images.isNotEmpty ? images[0] : imageUrl;

  /// A une vraie image (pas juste un emoji)
  bool get hasImage => primaryImage != null && primaryImage!.isNotEmpty;

  /// Pourcentage de réduction
  int? get discountPct {
    if (oldPrice == null || oldPrice! <= price) return null;
    return ((1 - price / oldPrice!) * 100).round();
  }

  /// Prix formaté : "350 F"
  String get formattedPrice =>
    '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  String? get formattedOldPrice => oldPrice != null
    ? '${oldPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F'
    : null;
}