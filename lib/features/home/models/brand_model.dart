class BrandModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String? color;
  final int sortOrder;
  final bool active;

  BrandModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.color,
    this.sortOrder = 0,
    this.active = true,
  });

  factory BrandModel.fromMap(Map<String, dynamic> m) => BrandModel(
    id:        m['id']?.toString() ?? '',
    name:      m['name']?.toString() ?? '',
    logoUrl:   m['logo_url']?.toString(),
    color:     m['color']?.toString(),
    sortOrder: (m['sort_order'] as int?) ?? 0,
    active:    (m['active'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'id':         id,
    'name':       name,
    'logo_url':   logoUrl,
    'color':      color,
    'sort_order': sortOrder,
    'active':     active,
  };
}
