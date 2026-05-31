class PromoModel {
  final String id;
  final String badge;
  final String title;
  final String? subtitle;
  final String ctaLabel;
  final String? ctaTarget;
  final String? emoji;
  final String? imageUrl;
  final String colorStart;
  final String colorEnd;
  final int sortOrder;
  final bool active;
  final DateTime? expiresAt;

  PromoModel({
    required this.id,
    required this.badge,
    required this.title,
    this.subtitle,
    required this.ctaLabel,
    this.ctaTarget,
    this.emoji,
    this.imageUrl,
    this.colorStart = '#E8192C',
    this.colorEnd = '#B81020',
    this.sortOrder = 0,
    this.active = true,
    this.expiresAt,
  });

  factory PromoModel.fromMap(Map<String, dynamic> m) => PromoModel(
    id:         m['id']?.toString() ?? '',
    badge:      m['badge']?.toString() ?? '',
    title:      m['title']?.toString() ?? '',
    subtitle:   m['subtitle']?.toString(),
    ctaLabel:   m['cta_label']?.toString() ?? 'Voir',
    ctaTarget:  m['cta_target']?.toString(),
    emoji:      m['emoji']?.toString(),
    imageUrl:   m['image_url']?.toString(),
    colorStart: m['color_start']?.toString() ?? '#E8192C',
    colorEnd:   m['color_end']?.toString() ?? '#B81020',
    sortOrder:  (m['sort_order'] as int?) ?? 0,
    active:     (m['active'] as bool?) ?? true,
    expiresAt:  m['expires_at'] != null
      ? DateTime.tryParse(m['expires_at'].toString())
      : null,
  );
}

class ShortcutModel {
  final String id;
  final String title;
  final String? emoji;
  final String? imageUrl;
  final String color;
  final String? targetRoute;
  final String? categoryId;
  final int sortOrder;
  final bool active;

  ShortcutModel({
    required this.id,
    required this.title,
    this.emoji,
    this.imageUrl,
    this.color = '#2E7D32',
    this.targetRoute,
    this.categoryId,
    this.sortOrder = 0,
    this.active = true,
  });

  factory ShortcutModel.fromMap(Map<String, dynamic> m) => ShortcutModel(
    id:          m['id']?.toString() ?? '',
    title:       m['title']?.toString() ?? '',
    emoji:       m['emoji']?.toString(),
    imageUrl:    m['image_url']?.toString(),
    color:       m['color']?.toString() ?? '#2E7D32',
    targetRoute: m['target_route']?.toString(),
    categoryId:  m['category_id']?.toString(),
    sortOrder:   (m['sort_order'] as int?) ?? 0,
    active:      (m['active'] as bool?) ?? true,
  );
}
