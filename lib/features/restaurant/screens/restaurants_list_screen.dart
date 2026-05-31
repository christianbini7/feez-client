import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../services/supabase_service.dart';

final restaurantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final list = await SupabaseService.getRestaurants();
  if (list.isNotEmpty) return list;
  // Données mock si la BDD est vide
  return _mockRestos;
});

const _mockRestos = [
  {'name': 'Le Flambe', 'cuisine_type': 'Grillades · Africain', 'rating': 4.8,
   'delivery_time': '25', 'delivery_fee': 500, 'image_url': null,
   'id': 'mock-1'},
  {'name': 'Pizza Palace', 'cuisine_type': 'Pizza · Italien', 'rating': 4.6,
   'delivery_time': '30', 'delivery_fee': 500, 'image_url': null,
   'id': 'mock-2'},
  {'name': 'Chez Mariam', 'cuisine_type': 'Attiéké · Ivoirien', 'rating': 4.9,
   'delivery_time': '20', 'delivery_fee': 300, 'image_url': null,
   'id': 'mock-3'},
  {'name': 'Wok Express', 'cuisine_type': 'Asiatique · Noodles', 'rating': 4.4,
   'delivery_time': '35', 'delivery_fee': 500, 'image_url': null,
   'id': 'mock-4'},
  {'name': 'Burger House', 'cuisine_type': 'Burger · Fast Food', 'rating': 4.5,
   'delivery_time': '22', 'delivery_fee': 400, 'image_url': null,
   'id': 'mock-5'},
  {'name': 'La Terrasse', 'cuisine_type': 'Cuisine Française', 'rating': 4.7,
   'delivery_time': '40', 'delivery_fee': 700, 'image_url': null,
   'id': 'mock-6'},
];

class RestaurantsListScreen extends ConsumerStatefulWidget {
  const RestaurantsListScreen({super.key});
  @override
  ConsumerState<RestaurantsListScreen> createState() => _RestaurantsListScreenState();
}

class _RestaurantsListScreenState extends ConsumerState<RestaurantsListScreen> {
  String _filter = 'all';

  static const _filters = [
    ('all',      '🔥 Tous'),
    ('burger',   '🍔 Burger'),
    ('pizza',    '🍕 Pizza'),
    ('africain', '🍲 Africain'),
    ('asiatique','🍜 Asiatique'),
    ('healthy',  '🥗 Healthy'),
  ];

  @override
  Widget build(BuildContext context) {
    final restos = ref.watch(restaurantsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: CustomScrollView(
        slivers: [

          // ── APP BAR ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'BarlowCondensed',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0D0D0D),
                                      letterSpacing: -0.5,
                                      height: 1,
                                    ),
                                    children: [
                                      TextSpan(text: 'Feez '),
                                      TextSpan(
                                        text: 'Food',
                                        style: TextStyle(color: FeezColors.food),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Les meilleures saveurs livrées chez toi',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 11.5,
                                    color: FeezColors.mid,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Search icon
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F3),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.search_rounded,
                              color: FeezColors.mid, size: 20),
                          ),
                        ],
                      ),
                    ),
                    // Filtres
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                        itemCount: _filters.length,
                        itemBuilder: (_, i) {
                          final (key, label) = _filters[i];
                          final active = _filter == key;
                          return GestureDetector(
                            onTap: () => setState(() => _filter = key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: active
                                    ? FeezColors.food
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active
                                      ? FeezColors.food
                                      : const Color(0xFFEEEEEE)),
                                boxShadow: active
                                    ? [BoxShadow(
                                        color: FeezColors.food.withValues(alpha: 0.30),
                                        blurRadius: 8, offset: const Offset(0, 3))]
                                    : [],
                              ),
                              child: Text(label,
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: active ? Colors.white : FeezColors.ink)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: const Color(0xFFF0F0F0)),
                  ],
                ),
              ),
            ),
          ),

          // ── PROMO BANNER ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: _PromoBanner(),
            ),
          ),

          // ── À LA UNE ────────────────────────────────────
          restos.maybeWhen(
            data: (list) {
              if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              final featured = list.take(4).toList();
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                      child: Text('À la une',
                        style: TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Color(0xFF0D0D0D), letterSpacing: -0.02)),
                    ),
                    SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: featured.length,
                        itemBuilder: (_, i) => _FeaturedCard(resto: featured[i]),
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ── TOUS LES RESTOS ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Row(children: [
                const Expanded(child: Text('Tous les restaurants',
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: Color(0xFF0D0D0D), letterSpacing: -0.02))),
                restos.maybeWhen(
                  data: (l) => Text('${l.length} restos',
                    style: const TextStyle(
                      fontFamily: 'DMSans', fontSize: 12,
                      color: FeezColors.mid, fontWeight: FontWeight.w500)),
                  orElse: () => const SizedBox.shrink()),
              ]),
            ),
          ),

          // ── LISTE ───────────────────────────────────────
          restos.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(
                    color: FeezColors.food, strokeWidth: 2)))),
            error: (e, _) => SliverToBoxAdapter(child: Center(
              child: Text('$e', style: const TextStyle(color: FeezColors.red)))),
            data: (list) {
              if (list.isEmpty) {
                return SliverToBoxAdapter(child: _empty());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RestoCard(resto: list[i]),
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 90, height: 90,
        decoration: BoxDecoration(
          color: FeezColors.food.withValues(alpha: 0.10),
          shape: BoxShape.circle),
        child: const Icon(Icons.restaurant_outlined,
          color: FeezColors.food, size: 44)),
      const SizedBox(height: 16),
      const Text('Bientôt disponible',
        style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 22,
          fontWeight: FontWeight.w900, color: FeezColors.ink)),
      const SizedBox(height: 6),
      const Text('Les restaurants ouvrent leurs portes bientôt',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
          color: FeezColors.mid, height: 1.4)),
    ]));
}

// ── Promo Banner ───────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 110,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B00), Color(0xFFFF3D00)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
          blurRadius: 20, offset: const Offset(0, 8)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(children: [
        // Dots pattern
        Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
        // Cercle décoratif
        Positioned(right: -20, top: -30,
          child: Container(width: 130, height: 130,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle))),
        Positioned(right: 40, bottom: -40,
          child: Container(width: 90, height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle))),
        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6)),
                  child: const Text('OFFRE DU JOUR',
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 0.5))),
                const SizedBox(height: 6),
                const Text('Livraison offerte\npour ta 1ère commande',
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 20, fontWeight: FontWeight.w900,
                    color: Colors.white, height: 1.1,
                    letterSpacing: -0.02)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Commander',
                      style: TextStyle(
                        fontFamily: 'BarlowCondensed', fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF6B00))),
                    const SizedBox(width: 4),
                    Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B00),
                        shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 10)),
                  ])),
              ])),
            const Text('🍔', style: TextStyle(fontSize: 56)),
            const SizedBox(width: 8),
          ]),
        ),
      ]),
    ),
  );
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    const s = 12.0;
    for (double y = s; y < size.height; y += s * 2) {
      for (double x = s; x < size.width; x += s * 2) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Featured Card (horizontal scroll) ─────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Map<String, dynamic> resto;
  const _FeaturedCard({required this.resto});

  @override
  Widget build(BuildContext context) {
    final name     = resto['name']?.toString() ?? 'Restaurant';
    final imageUrl = resto['image_url']?.toString();
    final cuisine  = resto['cuisine_type']?.toString() ?? '';
    final rating   = (resto['rating'] ?? 4.5).toString();
    final delivery = resto['delivery_time']?.toString() ?? '25';

    return GestureDetector(
      onTap: () => context.push('/resto', extra: resto),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            const BoxShadow(color: Color(0x12000000),
              blurRadius: 0, offset: Offset(3, 5)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 120, width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                Container(color: const Color(0xFFF5F0EB)),
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🍽️', style: TextStyle(fontSize: 40)))),
                // Gradient overlay bas
                Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ])))),
                // Rating badge
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F8B3F),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                        size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(rating,
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                    ]))),
                // Time badge bas-gauche
                Positioned(bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.access_time_rounded,
                        size: 10, color: FeezColors.food),
                      const SizedBox(width: 2),
                      Text('$delivery min',
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D0D0D))),
                    ]))),
              ]),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed', fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D0D0D), letterSpacing: -0.02)),
              const SizedBox(height: 2),
              Text(cuisine,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'DMSans', fontSize: 11,
                  color: FeezColors.mid)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Main Resto Card (vertical list) ───────────────────────────
class _RestoCard extends StatelessWidget {
  final Map<String, dynamic> resto;
  const _RestoCard({required this.resto});

  @override
  Widget build(BuildContext context) {
    final name     = resto['name']?.toString() ?? 'Restaurant';
    final imageUrl = resto['image_url']?.toString();
    final cuisine  = resto['cuisine_type']?.toString() ?? 'Cuisine';
    final rating   = (resto['rating'] ?? 4.5).toString();
    final delivery = resto['delivery_time']?.toString() ?? '20-30';
    final fee      = resto['delivery_fee'];

    return GestureDetector(
      onTap: () => context.push('/resto', extra: resto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(color: Color(0x10000000),
              blurRadius: 0, offset: Offset(3, 5)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 158,
              child: Stack(fit: StackFit.expand, children: [
                Container(
                  color: const Color(0xFFF5F0EB),
                  child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('🍽️',
                            style: TextStyle(fontSize: 52))))
                    : const Center(child: Text('🍽️',
                        style: TextStyle(fontSize: 52)))),
                // Gradient overlay
                Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ])))),
                // Livraison badge
                Positioned(top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6, offset: const Offset(0, 2))]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.access_time_rounded,
                        size: 12, color: FeezColors.food),
                      const SizedBox(width: 4),
                      Text('$delivery min',
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D0D0D))),
                    ]))),
                // Rating badge
                Positioned(top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F8B3F),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF1F8B3F).withValues(alpha: 0.35),
                        blurRadius: 6, offset: const Offset(0, 2))]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                        size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(rating,
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                    ]))),
              ]),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'BarlowCondensed', fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D0D0D), letterSpacing: -0.02)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(cuisine,
                      style: const TextStyle(fontFamily: 'DMSans',
                        fontSize: 12, color: FeezColors.mid)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·',
                        style: TextStyle(color: FeezColors.low))),
                    Icon(Icons.delivery_dining_rounded,
                      size: 13, color: FeezColors.food),
                    const SizedBox(width: 3),
                    Text(
                      fee != null ? '$fee F' : 'Livraison 500 F',
                      style: const TextStyle(
                        fontFamily: 'DMSans', fontSize: 12,
                        color: FeezColors.mid,
                        fontWeight: FontWeight.w600)),
                  ]),
                ])),
              // CTA arrow
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: FeezColors.food.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_rounded,
                  color: FeezColors.food, size: 18)),
            ]),
          ),
        ]),
      ),
    );
  }
}