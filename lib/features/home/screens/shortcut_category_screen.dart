import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme.dart';
import '../providers/home_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../widgets/product_card.dart';

class ShortcutCategoryScreen extends ConsumerWidget {
  final Map<String, dynamic> shortcut;
  const ShortcutCategoryScreen({super.key, required this.shortcut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String  title      = (shortcut['title'] as String? ?? '')
        .replaceAll('\n', ' ');
    final String? imageUrl   = shortcut['image_url'] as String?;
    final String  emoji      = shortcut['emoji'] as String? ?? '📦';
    final String? categoryId = shortcut['category_id'] as String?;

    final prods   = ref.watch(productsProvider);
    final cartMap = ref.watch(marketCartProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        body: Column(
          children: [

            // ── HERO ─────────────────────────────────────────────
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _GradientBg(emoji: emoji))
                        : _GradientBg(emoji: emoji),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0xCC000000)],
                        ),
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: kToolbarHeight - 8,
                    left: 14,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/home'),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                  // Titre + compteur
                  Positioned(
                    bottom: 18, left: 18, right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                          style: const TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontSize: 30, fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.02, height: 1.0,
                            shadows: [Shadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 2), blurRadius: 6)],
                          )),
                        const SizedBox(height: 4),
                        prods.maybeWhen(
                          data: (list) {
                            final count = categoryId != null
                                ? list.where((p) =>
                                    p.categoryId == categoryId ||
                                    p.category   == categoryId).length
                                : list.length;
                            return Text(
                              '$count produit${count > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontFamily: 'DMSans', fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500));
                          },
                          orElse: () => const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── PRODUITS ─────────────────────────────────────────
            Expanded(
              child: prods.when(
                loading: () => const _ShortcutSkeleton(),
                error: (e, _) => Center(
                  child: Text('$e',
                    style: const TextStyle(color: FeezColors.red))),
                data: (list) {
                  final filtered = categoryId != null
                      ? list.where((p) =>
                          p.categoryId == categoryId ||
                          p.category   == categoryId).toList()
                      : list;

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji,
                            style: const TextStyle(fontSize: 52)),
                          const SizedBox(height: 16),
                          const Text('Aucun produit disponible',
                            style: TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: FeezColors.mid)),
                          const SizedBox(height: 8),
                          const Text('Reviens bientôt !',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13, color: FeezColors.low)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 120),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p   = filtered[i];
                      final qty = cartMap[p.id] ?? 0;
                      return ProductCard(
                        product: p, qty: qty,
                        onAdd:    () => ref
                            .read(marketCartProvider.notifier).add(p.id),
                        onRemove: () => ref
                            .read(marketCartProvider.notifier).remove(p.id),
                        onTap:    () => ctx.push(
                            '/product/${p.id}', extra: p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fond dégradé rouge (fallback sans image) ──────────────────
class _GradientBg extends StatelessWidget {
  final String emoji;
  const _GradientBg({required this.emoji});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8192C), Color(0xFF8B0010)],
          ),
        ),
        child: Center(
          child: Text(emoji,
            style: const TextStyle(
              fontSize: 72,
              shadows: [Shadow(
                color: Color(0x44000000),
                offset: Offset(0, 4), blurRadius: 12)],
            )),
        ),
      );
}

// ── Skeleton loader local (pas d'import de classe privée) ─────
class _ShortcutSkeleton extends StatelessWidget {
  const _ShortcutSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFEEEEEE),
        highlightColor: const Color(0xFFF8F8F8),
        period: const Duration(milliseconds: 1400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
}