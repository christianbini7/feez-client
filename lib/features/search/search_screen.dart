import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/product_model.dart';
import '../cart/providers/cart_provider.dart';
import '../../services/supabase_service.dart';

// ── Providers ─────────────────────────────────────────────────
final _queryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final _resultsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>(
  (ref, q) async {
    if (q.trim().length < 2) return [];
    await Future.delayed(const Duration(milliseconds: 300));
    return SupabaseService.searchProducts(q);
  },
);

final _recentProvider = StateProvider<List<String>>((ref) => []);

// ── Données statiques ─────────────────────────────────────────
const _trends = [
  'Riz parfumé', 'Huile de palme', 'Tomate fraîche', 'Attiéké',
  'Sardines Maeva', 'Eau Awa', 'Lait Carnation', 'Sucre cristal',
  'Farine Dinor', 'Poulet congelé',
];

const _cats = [
  ['Épicerie', '🛒'], ['Pharmacie', '💊'], ['Beauté', '💄'],
  ['Boissons', '🧃'], ['Boulangerie', '🍞'], ['Boucherie', '🥩'],
];

// ── Screen ────────────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl  = TextEditingController();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setQuery(String v) =>
      ref.read(_queryProvider.notifier).state = v;

  void _pick(String v) {
    _ctrl.text = v;
    _setQuery(v);
    _focus.unfocus();
    final list = ref.read(_recentProvider);
    if (!list.contains(v)) {
      ref.read(_recentProvider.notifier).state =
          [v, ...list].take(6).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q       = ref.watch(_queryProvider);
    final recents = ref.watch(_recentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────
          _SearchHeader(
            q: q,
            ctrl: _ctrl,
            focus: _focus,
            onChanged: _setQuery,
            onSubmitted: _pick,
            onClear: () { _ctrl.clear(); _setQuery(''); },
            onCancel: () => context.pop(),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // ── Contenu ────────────────────────────────────
          Expanded(
            child: q.isEmpty
                ? _HomeState(
                    recents: recents,
                    onPick: _pick,
                    onClearRecents: () =>
                        ref.read(_recentProvider.notifier).state = [],
                  )
                : _Results(query: q),
          ),
        ],
      ),
    );
  }
}

// ── Header (widget séparé = structure claire) ─────────────────
class _SearchHeader extends StatelessWidget {
  final String q;
  final TextEditingController ctrl;
  final FocusNode focus;
  final ValueChanged<String> onChanged, onSubmitted;
  final VoidCallback onClear, onCancel;

  const _SearchHeader({
    required this.q,
    required this.ctrl,
    required this.focus,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(
            children: [
              // Champ de recherche
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFAAAAAA),
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          focusNode: focus,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0D0D0D),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Produit, marque, catégorie…',
                            hintStyle: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13.5,
                              color: Color(0xFFAAAAAA),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (q.isNotEmpty)
                        GestureDetector(
                          onTap: onClear,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.cancel_rounded,
                              color: Color(0xFFAAAAAA),
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Annuler
              GestureDetector(
                onTap: onCancel,
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: FeezColors.red,
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

// ── État vide ─────────────────────────────────────────────────
class _HomeState extends StatelessWidget {
  final List<String> recents;
  final void Function(String) onPick;
  final VoidCallback onClearRecents;

  const _HomeState({
    required this.recents,
    required this.onPick,
    required this.onClearRecents,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        // Recherches récentes
        if (recents.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Récent',
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClearRecents,
                child: const Text(
                  'Effacer',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FeezColors.mid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recents.map((r) {
              return GestureDetector(
                onTap: () => onPick(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 13, color: FeezColors.mid),
                      const SizedBox(width: 5),
                      Text(r,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
        ],

        // Catégories
        const Text('Catégories',
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D0D0D),
            )),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: _cats.map((c) {
            return GestureDetector(
              onTap: () => onPick(c[0]),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${c[1]} ${c[0]}',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 22),

        // Populaires
        const Text('Populaires',
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D0D0D),
            )),
        const SizedBox(height: 8),
        ..._trends.asMap().entries.map((e) {
          return GestureDetector(
            onTap: () => onPick(e.value),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F5)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${e.key + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: e.key < 3
                            ? FeezColors.red
                            : FeezColors.mid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.value,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0D0D0D),
                        )),
                  ),
                  const Icon(Icons.north_west_rounded,
                      size: 14, color: Color(0xFFCCCCCC)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Résultats ─────────────────────────────────────────────────
class _Results extends ConsumerWidget {
  final String query;
  const _Results({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_resultsProvider(query));
    final cart  = ref.watch(marketCartProvider);

    return async.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: 5,
        itemBuilder: (_, __) => const _SkeletonRow(),
      ),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 14),
                Text(
                  'Aucun résultat pour "$query"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Essaie un autre mot-clé',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: FeezColors.mid,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                '${list.length} résultat${list.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: FeezColors.mid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final p   = list[i];
                  final qty = cart[p.id] ?? 0;
                  return _ProductRow(
                    product: p,
                    qty: qty,
                    query: query,
                    onTap: () =>
                        ctx.push('/product/${p.id}', extra: p),
                    onAdd: () {
                      HapticFeedback.lightImpact();
                      ref.read(marketCartProvider.notifier).add(p.id);
                    },
                    onRemove: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(marketCartProvider.notifier)
                          .remove(p.id);
                    },
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

// ── Ligne produit ─────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final int qty;
  final String query;
  final VoidCallback onTap, onAdd, onRemove;

  const _ProductRow({
    required this.product,
    required this.qty,
    required this.query,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 66,
                height: 66,
                color: const Color(0xFFF5F5F5),
                child: p.hasImage
                    ? Image.network(
                        p.primaryImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(p.emoji,
                              style:
                                  const TextStyle(fontSize: 28)),
                        ),
                      )
                    : Center(
                        child: Text(p.emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(
                    text: p.name,
                    query: query,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D0D0D),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(p.unit,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: FeezColors.mid,
                      )),
                  const SizedBox(height: 5),
                  Text(p.formattedPrice,
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D0D0D),
                        height: 1.0,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Bouton
            qty == 0
                ? GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: FeezColors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: FeezColors.red
                                .withValues(alpha: 0.30),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                    ),
                  )
                : Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEE2738),
                          Color(0xFFCF1422),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onRemove,
                          child: const SizedBox(
                            width: 28,
                            height: 36,
                            child: Center(
                              child: Icon(Icons.remove_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                        Text('$qty',
                            style: const TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                        GestureDetector(
                          onTap: onAdd,
                          child: const SizedBox(
                            width: 28,
                            height: 36,
                            child: Center(
                              child: Icon(Icons.add_rounded,
                                  color: Colors.white, size: 14),
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

// ── Highlight ─────────────────────────────────────────────────
class _HighlightText extends StatelessWidget {
  final String text, query;
  final TextStyle style;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
    final lText  = text.toLowerCase();
    final lQuery = query.toLowerCase();
    final spans  = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lText.indexOf(lQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + lQuery.length),
        style: TextStyle(
          color: FeezColors.red,
          fontWeight: FontWeight.w800,
          backgroundColor: FeezColors.red.withValues(alpha: 0.08),
        ),
      ));
      start = idx + lQuery.length;
    }
    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: double.infinity,
                    color: const Color(0xFFEEEEEE)),
                const SizedBox(height: 6),
                Container(
                    height: 11,
                    width: 80,
                    color: const Color(0xFFEEEEEE)),
                const SizedBox(height: 8),
                Container(
                    height: 16,
                    width: 60,
                    color: const Color(0xFFEEEEEE)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}