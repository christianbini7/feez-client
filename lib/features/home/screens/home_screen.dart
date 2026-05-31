import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme.dart';
import '../providers/brands_provider.dart';
import '../providers/home_content_provider.dart';
import '../models/home_models.dart';
import '../../../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/product_card.dart';

// ═══════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _cat = 'all';
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(modeProvider.notifier).state = AppMode.market;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = ref.watch(marketTotalItemsProvider);
    final cats      = ref.watch(categoriesProvider);
    final prods     = ref.watch(productsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Logo + Search + Cart
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Row(
                        children: [
                          const Text(
                            'feez',
                            style: TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: FeezColors.red,
                              letterSpacing: -0.02,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showSearch(
                                context: context,
                                delegate: _SearchDelegate(ref),
                              ),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: const Row(
                                  children: [
                                    Icon(Icons.search_rounded,
                                        color: Color(0xFFAAAAAA), size: 17),
                                    SizedBox(width: 7),
                                    Text(
                                      'Épicerie, pharma, beauté…',
                                      style: TextStyle(
                                          fontSize: 13, color: Color(0xFFAAAAAA)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Bouton panier
                          GestureDetector(
                            onTap: () => context.push('/cart'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              height: 44,
                              constraints: const BoxConstraints(minWidth: 44),
                              padding: EdgeInsets.symmetric(
                                horizontal: cartTotal > 0 ? 10 : 11),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFE8192C), Color(0xFFBF0F1F)]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: FeezColors.red.withValues(alpha: 0.40),
                                    blurRadius: 0,
                                    offset: const Offset(2, 4)),
                                  BoxShadow(
                                    color: FeezColors.red.withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6)),
                                ]),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_cart_rounded,
                                    color: Colors.white, size: 20),
                                  if (cartTotal > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10)),
                                      child: Text('$cartTotal',
                                        style: const TextStyle(
                                          fontFamily: 'BarlowCondensed',
                                          fontSize: 13, fontWeight: FontWeight.w900,
                                          color: FeezColors.red, height: 1))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Catégories
                    _CategoryRow(
                      cats: cats,
                      selected: _cat,
                      onSelect: (c) => setState(() => _cat = c),
                    ),
                  ],
                ),
              ),

              // ── CONTENU SCROLLABLE ───────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: FeezColors.red,
                  onRefresh: () async {
                    ref.invalidate(productsProvider);
                    ref.invalidate(categoriesProvider);
                    ref.invalidate(brandsProvider);
                    ref.invalidate(promosProvider);
                    ref.invalidate(shortcutsProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 130),
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        child: Container(
                          color: FeezColors.red,
                          child: const _PromoCarousel(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ProductsSection(
                          prods: prods, selectedCat: _cat, ref: ref),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════════════
class _SecHeader extends StatelessWidget {
  final String title, action;
  final String? subtitle;
  final IconData? icon;
  const _SecHeader({
    required this.title,
    required this.action,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: FeezColors.red),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D0D0D),
                          letterSpacing: -0.02,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11.5,
                        color: FeezColors.mid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FeezColors.red,
                      letterSpacing: 0.02,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 12, color: FeezColors.red),
                ],
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  CATEGORY ROW
// ═══════════════════════════════════════════════════════════════
class _CategoryRow extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> cats;
  final String selected;
  final void Function(String) onSelect;
  const _CategoryRow({
    required this.cats,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => cats.when(
        loading: () => Column(
          children: [
            SizedBox(
              height: 78,
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFEEEEEE),
                highlightColor: const Color(0xFFF8F8F8),
                period: const Duration(milliseconds: 1400),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: 6,
                  itemBuilder: (_, i) => Container(
                    width: 68,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 40,
                          height: 9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(height: 1, color: const Color(0xFFF0F0F0)),
          ],
        ),
        error: (_, __) => const SizedBox(),
        data: (list) {
          // Si une catégorie 'all' existe en BDD, utiliser son image pour "Tous"
          final allEntry = list.where((c) => c['name'] == 'all').firstOrNull;
          final allImg   = allEntry?['image_url'] as String?;
          // Exclure l'entrée spéciale 'all' des catégories normales
          final filtered = list.where((c) => c['name'] != 'all').toList();

          final allCats = [
            {
              'name': 'all',
              'display_name': 'Tout',
              'icon': '',
              'image_url': allImg,
              '_isAll': true,
            },
            ...filtered,
          ];
          return Column(
            children: [
              SizedBox(
                height: 78,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: allCats.length,
                  itemBuilder: (_, i) {
                    final cat    = allCats[i];
                    final name   = cat['name'] as String;
                    final isAll  = cat['_isAll'] == true;
                    final active = selected == name;
                    return _CatChip(
                      name: name,
                      label: cat['display_name'] as String,
                      icon: cat['icon'] as String? ?? '📦',
                      imageUrl: cat['image_url'] as String?,
                      isAll: isAll,
                      active: active,
                      onTap: () => onSelect(name),
                    );
                  },
                ),
              ),
              Container(height: 1, color: const Color(0xFFF0F0F0)),
            ],
          );
        },
      );
}

// ═══════════════════════════════════════════════════════════════
//  CAT CHIP
// ═══════════════════════════════════════════════════════════════
class _CatChip extends StatelessWidget {
  final String name, label, icon;
  final String? imageUrl;
  final bool isAll, active;
  final VoidCallback onTap;
  const _CatChip({
    required this.name,
    required this.label,
    required this.icon,
    this.imageUrl,
    this.isAll = false,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 76,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: isAll
                      ? (imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.apps_rounded,
                                size: 28,
                                color: active
                                    ? FeezColors.red
                                    : const Color(0xFF555555),
                              ),
                            )
                          : Icon(Icons.apps_rounded,
                              size: 28,
                              color: active
                                  ? FeezColors.red
                                  : const Color(0xFF555555)))
                      : (imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(icon,
                                  style:
                                      const TextStyle(fontSize: 26)),
                            )
                          : Text(icon,
                              style: const TextStyle(fontSize: 26))),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11.5,
                  height: 1.15,
                  fontWeight:
                      active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? FeezColors.red
                      : const Color(0xFF777777),
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: active ? 24 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: FeezColors.red,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  PRODUCTS SECTION
// ═══════════════════════════════════════════════════════════════
class _ProductsSection extends ConsumerWidget {
  final AsyncValue<List<ProductModel>> prods;
  final String selectedCat;
  final WidgetRef ref;
  const _ProductsSection({
    required this.prods,
    required this.selectedCat,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => prods.when(
        loading: () => const _SkeletonGrid(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('$e',
              style: const TextStyle(color: FeezColors.red)),
        ),
        data: (list) {
          final f = selectedCat == 'all'
              ? list
              : list.where((p) => p.category == selectedCat).toList();
          final ep =
              f.where((p) => p.category == 'epicerie').toList();
          final ph =
              f.where((p) => p.category == 'pharmacie').toList();
          final au = f
              .where((p) =>
                  !['epicerie', 'pharmacie'].contains(p.category))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ShortcutCardsRow(),
              if (ep.isNotEmpty) ...[
                const _SecHeader(
                  title: 'Populaires',
                  subtitle: 'Les produits préférés des clients',
                  icon: Icons.local_fire_department_rounded,
                  action: 'Voir tout',
                ),
                _Grid(products: ep),
              ],
              const SizedBox(height: 12),
              const _BrandsSection(),
              if (ph.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _SecHeader(
                  title: 'Pharmacie',
                  subtitle: 'Santé et bien-être',
                  icon: Icons.medical_services_outlined,
                  action: 'Voir tout',
                ),
                _Grid(products: ph),
              ],
              const SizedBox(height: 12),
              const _FeezProCard(),
              if (au.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _SecHeader(
                  title: 'Plus pour toi',
                  subtitle: 'Une sélection variée',
                  icon: Icons.auto_awesome_rounded,
                  action: 'Voir tout',
                ),
                _Grid(products: au),
              ],
              const SizedBox(height: 16),
              const _HowItWorks(),
              const SizedBox(height: 24),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'feez · v1.0 · Abidjan 🇨🇮',
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ),
              if (f.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Aucun produit',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: Color(0xFF999999)),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

// ═══════════════════════════════════════════════════════════════
//  GRID
// ═══════════════════════════════════════════════════════════════
class _Grid extends ConsumerWidget {
  final List<ProductModel> products;
  const _Grid({required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.55,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p   = products[i];
            final qty = ref.watch(marketCartProvider)[p.id] ?? 0;
            return ProductCard(
              product: p,
              qty: qty,
              onAdd: () =>
                  ref.read(marketCartProvider.notifier).add(p.id),
              onRemove: () =>
                  ref.read(marketCartProvider.notifier).remove(p.id),
              onTap: () =>
                  ctx.push('/product/${p.id}', extra: p),
            );
          },
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  SEARCH DELEGATE
// ═══════════════════════════════════════════════════════════════
class _SearchDelegate extends SearchDelegate<ProductModel?> {
  final WidgetRef ref;
  _SearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Rechercher un produit…';

  @override
  List<Widget> buildActions(BuildContext c) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            ref.read(searchProvider.notifier).clear();
          },
        ),
      ];

  @override
  Widget buildLeading(BuildContext c) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => close(c, null),
      );

  @override
  Widget buildResults(BuildContext c) => _list(c);

  @override
  Widget buildSuggestions(BuildContext c) {
    if (query.isNotEmpty) ref.read(searchProvider.notifier).search(query);
    return _list(c);
  }

  Widget _list(BuildContext c) {
    final r = ref.watch(searchProvider);
    return r.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: FeezColors.red, strokeWidth: 2),
      ),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) => list.isEmpty
          ? Center(
              child: Text(
                query.isEmpty
                    ? 'Tape un produit…'
                    : 'Aucun résultat pour "$query"',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF999999)),
              ),
            )
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: p.hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              p.primaryImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_outlined,
                                      color: Color(0xFFCCCCCC)),
                            ),
                          )
                        : const Icon(Icons.image_outlined,
                            color: Color(0xFFCCCCCC)),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(p.unit,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999999))),
                  trailing: Text(
                    p.formattedPrice,
                    style: const TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: FeezColors.red,
                    ),
                  ),
                  onTap: () => close(c, p),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SKELETON GRID
// ═══════════════════════════════════════════════════════════════
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFEEEEEE),
        highlightColor: const Color(0xFFF8F8F8),
        period: const Duration(milliseconds: 1400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.53,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (_, i) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 118,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  SHORTCUT CARDS ROW
// ═══════════════════════════════════════════════════════════════
class _ShortcutCardsRow extends ConsumerWidget {
  const _ShortcutCardsRow();

  static const _fallback = [
    {'title': 'Frais & Bio',        'emoji': '🥑'},
    {'title': 'Beauté Soin',        'emoji': '💄'},
    {'title': 'Maison & Nettoyage', 'emoji': '🧴'},
    {'title': 'Bébé & Enfants',     'emoji': '🧸'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scAsync = ref.watch(shortcutsProvider);
    return scAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (shortcuts) {
        final useFallback = shortcuts.isEmpty;
        final count = useFallback ? _fallback.length : shortcuts.length;
        if (count == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header sans fond
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 17, color: FeezColors.red),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Besoin de quelque chose ?',
                          style: TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: Color(0xFF0D0D0D),
                            letterSpacing: -0.02, height: 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Trouve ce dont tu as besoin',
                    style: TextStyle(
                      fontFamily: 'DMSans', fontSize: 11.5,
                      color: FeezColors.mid,
                      fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            SizedBox(
              height: 128,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                itemCount: count,
                  itemBuilder: (ctx, i) {
                    final String title;
                    final String? imageUrl;
                    final String emoji;
                    final Map<String, dynamic> extra;

                    if (useFallback) {
                      final s = _fallback[i];
                      title    = s['title']! as String;
                      imageUrl = null;
                      emoji    = s['emoji']! as String;
                      extra    = {
                        'title': title,
                        'image_url': null,
                        'emoji': emoji,
                        'category_id': null,
                        'target_route': null,
                      };
                    } else {
                      final s  = shortcuts[i];
                      title    = s.title;
                      imageUrl = s.imageUrl;
                      emoji    = s.emoji ?? '📦';
                      extra    = {
                        'title': s.title,
                        'image_url': s.imageUrl,
                        'emoji': s.emoji,
                        'category_id': s.categoryId,
                        'target_route': s.targetRoute,
                      };
                    }

                    final displayTitle = title.replaceAll('\n', ' ');
                    final hasImg = imageUrl != null && imageUrl.isNotEmpty;

                    return Container(
                      width: 88,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Card plate, sans fond, sans ombre, sans arrondi
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => ctx.push(
                                    '/shortcut',
                                    extra: extra),
                                splashColor: Colors.black
                                    .withValues(alpha: 0.08),
                                highlightColor: Colors.black
                                    .withValues(alpha: 0.04),
                                child: hasImg
                                    ? Image.network(
                                        imageUrl!,
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          color: const Color(0xFFF5F5F5),
                                          child: Center(
                                            child: Text(emoji,
                                                style: const TextStyle(
                                                    fontSize: 40)),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFF5F5F5),
                                        child: Center(
                                          child: Text(emoji,
                                              style: const TextStyle(
                                                  fontSize: 40)),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          // Titre sous la card
                          Text(
                            displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2A2A2A),
                              letterSpacing: -0.02,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PROMO CAROUSEL
// ═══════════════════════════════════════════════════════════════
class _PromoCarousel extends ConsumerStatefulWidget {
  const _PromoCarousel();
  @override
  ConsumerState<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<_PromoCarousel> {
  final _ctrl = PageController();
  int _current = 0;
  Timer? _timer;

  static final _fallbacks = [
    PromoModel(
      id: 'fb1',
      badge: 'OFFRE FLASH',
      title: '-30% sur ta\npremière commande',
      ctaLabel: 'Acheter maintenant',
      emoji: '🛍️',
      colorStart: '#E8192C',
      colorEnd: '#B81020',
    ),
  ];

  void _setupTimer(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Color _hex(String h) =>
      Color(int.parse('0xFF${h.replaceFirst('#', '')}'));

  @override
  Widget build(BuildContext context) {
    final promosAsync = ref.watch(promosProvider);
    return promosAsync.when(
      loading: () => const SizedBox(height: 170),
      error:   (_, __) => const SizedBox(height: 0),
      data: (promos) {
        final list = promos.isEmpty ? _fallbacks : promos;
        if (_timer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _setupTimer(list.length);
          });
        }
        return SizedBox(
          height: 170,
          child: Stack(
            children: [
              PageView.builder(
                controller: _ctrl,
                itemCount: 10000,
                onPageChanged: (i) =>
                    setState(() => _current = i % list.length),
                itemBuilder: (_, i) {
                  final p = list[i % list.length];
                  return _PromoSlide(
                    badge:    p.badge,
                    title:    p.title,
                    cta:      p.ctaLabel,
                    emoji:    p.emoji ?? '🛍️',
                    imageUrl: p.imageUrl,
                    colors: [
                      _hex(p.colorStart),
                      _hex(p.colorEnd),
                    ],
                  );
                },
              ),
              if (list.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      list.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _current == i ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _current == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PromoSlide extends StatelessWidget {
  final String badge, title, cta, emoji;
  final String? imageUrl;
  final List<Color> colors;
  const _PromoSlide({
    required this.badge,
    required this.title,
    required this.cta,
    required this.emoji,
    this.imageUrl,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PromoPainter())),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 0,
              bottom: 0,
              child: Center(
                child: hasImg
                    ? Image.network(
                        imageUrl!,
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          emoji,
                          style: const TextStyle(fontSize: 64),
                        ),
                      )
                    : Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 64,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 72),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -0.02,
                        shadows: [
                          Shadow(
                            color: Color(0x40000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cta,
                            style: TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: colors[0],
                              letterSpacing: 0.02,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colors[0],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    const spacing = 14.0;
    const radius  = 1.2;
    for (double y = 6; y < size.height; y += spacing) {
      for (double x = 6; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  BRANDS SECTION
// ═══════════════════════════════════════════════════════════════
class _BrandsSection extends ConsumerWidget {
  const _BrandsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);
    return brandsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (brands) {
        if (brands.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SecHeader(
              title: 'Marques partenaires',
              subtitle: 'Nos enseignes de confiance',
              icon: Icons.verified_rounded,
              action: 'Voir tout',
            ),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: brands.length,
                itemBuilder: (_, i) {
                  final b = brands[i];
                  final c = b.color != null
                      ? Color(int.parse(
                          b.color!.replaceFirst('#', '0xFF')))
                      : FeezColors.red;
                  return Container(
                    width: 84,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: b.logoUrl != null &&
                                  b.logoUrl!.isNotEmpty
                              ? Image.network(
                                  b.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      Center(
                                    child: Icon(
                                        Icons.storefront_rounded,
                                        color: c,
                                        size: 32),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                      Icons.storefront_rounded,
                                      color: c,
                                      size: 32),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FEEZ PRO CARD
// ═══════════════════════════════════════════════════════════════
class _FeezProCard extends StatelessWidget {
  const _FeezProCard();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA000),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 11, color: Color(0xFF1A1A1A)),
                          SizedBox(width: 3),
                          Text(
                            'FEEZ PRO',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 0.10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Livraison gratuite illimitée',
                      style: TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '+ 10% sur tous tes achats',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11.5,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA000),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Devenir Pro',
                              style: TextStyle(
                                fontFamily: 'BarlowCondensed',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: Color(0xFF1A1A1A)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('👑',
                      style: TextStyle(fontSize: 38)),
                ),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  HOW IT WORKS
// ═══════════════════════════════════════════════════════════════
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 18, color: FeezColors.red),
                  SizedBox(width: 6),
                  Text(
                    'Comment ça marche',
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: FeezColors.ink,
                      letterSpacing: -0.02,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Recevoir tes courses en 15 min, 3 étapes',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11.5,
                  color: FeezColors.mid,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _step(1, '🛒', 'Choisis', 'tes produits'),
                  _connector(),
                  _step(2, '💳', 'Paie', 'en 1 clic'),
                  _connector(),
                  _step(3, '🚀', 'Reçois', 'en 15 min'),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _step(int n, String emoji, String title, String sub) =>
      Expanded(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFEEEEEE), width: 1),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: FeezColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$n',
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'BarlowCondensed',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: FeezColors.ink,
              ),
            ),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10.5,
                color: FeezColors.mid,
              ),
            ),
          ],
        ),
      );

  Widget _connector() => Container(
        width: 16,
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: const Color(0xFFDDDDDD),
      );
}