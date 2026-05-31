import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../core/theme.dart';

class BasketBar extends ConsumerWidget {
  const BasketBar({super.key});

  static String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final total = ref.watch(marketTotalItemsProvider);

    if (mode != AppMode.market || total == 0) return const SizedBox.shrink();

    final cart = ref.watch(marketCartProvider);
    final prodsAsync = ref.watch(productsProvider);

    final price = prodsAsync.maybeWhen(
      data: (products) {
        final map = {for (final p in products) p.id: p};
        return cart.entries
            .where((e) => map.containsKey(e.key))
            .fold<int>(0, (a, e) => a + map[e.key]!.price * e.value);
      },
      orElse: () => 0,
    );

    final thumbs = prodsAsync.maybeWhen(
      data: (products) {
        final map = {for (final p in products) p.id: p};
        return cart.keys
            .where((id) => map.containsKey(id) && map[id]!.hasImage)
            .take(3)
            .map((id) => map[id]!.primaryImage!)
            .toList();
      },
      orElse: () => <String>[],
    );

    return Positioned(
      bottom: 100,
      left: 12,
      right: 12,
      child: AnimatedSlide(
        offset: Offset.zero,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: () => context.push('/cart'),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: FeezColors.red.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Bande rouge gauche ──────────────────────────
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE8192C), Color(0xFFBF0F1F)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Thumbnails ou icône ─────────────────────────
                thumbs.isNotEmpty
                    ? _ThumbStack(urls: thumbs)
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: FeezColors.red,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                const SizedBox(width: 12),

                // ── Articles + prix ─────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total article${total > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (price > 0) ...[
                        const SizedBox(height: 1),
                        Text(
                          '${_fmt(price)} F',
                          style: const TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Bouton Commander ────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8192C), Color(0xFFBF0F1F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: FeezColors.red.withValues(alpha: 0.40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Commander',
                          style: TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.02,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Thumbnails empilés ─────────────────────────────────────────
class _ThumbStack extends StatelessWidget {
  final List<String> urls;
  const _ThumbStack({required this.urls});

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const overlap = 10.0;
    final total = size + (urls.length - 1) * (size - overlap);
    return SizedBox(
      width: total,
      height: size,
      child: Stack(
        children: List.generate(
          urls.length,
          (i) => Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: const Color(0xFF111111),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  urls[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF555555),
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
