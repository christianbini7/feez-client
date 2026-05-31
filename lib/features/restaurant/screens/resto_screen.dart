import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';
import '../../../services/supabase_service.dart';
import '../../cart/providers/cart_provider.dart';

class RestoScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> resto;
  const RestoScreen({super.key, required this.resto});
  @override
  ConsumerState<RestoScreen> createState() => _RestoScreenState();
}

class _RestoScreenState extends ConsumerState<RestoScreen> {
  List<Map<String, dynamic>> _menu = [];
  bool _loading = true;
  Map<String, int> _foodCart = {};

  static String _fmt(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  // Demo menu si pas de données Supabase
  final _demoMenu = [
    {'emoji': '🍕', 'name': 'Pizza Margherita', 'description': 'Tomate, mozzarella, basilic frais', 'price': 5500},
    {'emoji': '🍕', 'name': 'Pizza 4 Fromages', 'description': 'Mozza, cheddar, parmesan, gorgonzola', 'price': 6500},
    {'emoji': '🥗', 'name': 'Salade César', 'description': 'Laitue, poulet grillé, parmesan, croûtons', 'price': 3500},
    {'emoji': '🍝', 'name': 'Pasta Carbonara', 'description': 'Pâtes, lardons, crème, parmesan', 'price': 4800},
    {'emoji': '🥤', 'name': 'Limonade maison', 'description': 'Citron frais, menthe, sucre de canne', 'price': 1200},
    {'emoji': '🍰', 'name': 'Tiramisu', 'description': 'Mascarpone, café, biscuits', 'price': 2500},
  ];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final restoId = widget.resto['id'] as String?;
      if (restoId != null) {
        final items = await SupabaseService.getMenuItems(restoId);
        if (mounted) setState(() { _menu = items; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _cartTotal {
    return _foodCart.entries.fold(0, (sum, e) {
      final allItems = _menu.isNotEmpty ? _menu : _demoMenu;
      final item = allItems.firstWhere(
        (m) => (m['name'] as String) == e.key, orElse: () => <String, dynamic>{});
      if (item.isEmpty) return sum;
      return sum + ((item['price'] as int) * e.value);
    });
  }

  void _addItem(Map<String, dynamic> item) {
    final name = item['name'] as String;
    setState(() => _foodCart[name] = (_foodCart[name] ?? 0) + 1);
  }

  void _removeItem(Map<String, dynamic> item) {
    final name = item['name'] as String;
    if ((_foodCart[name] ?? 0) > 0) {
      setState(() {
        _foodCart[name] = _foodCart[name]! - 1;
        if (_foodCart[name] == 0) _foodCart.remove(name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r    = widget.resto;
    final menu = _menu.isNotEmpty ? _menu : _demoMenu;
    final isOpen = r['is_open'] == true;
    final bgColor = const Color(0xFFFFF0E6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [

        // ── Hero ──────────────────────────────────────
        Stack(children: [
          Container(
            height: 175,
            color: bgColor,
            child: Center(child: Text(r['logo_url'] ?? '🍽️',
              style: const TextStyle(fontSize: 56))),
          ),
          Positioned(top: 12, left: 14,
            child: FeezBackButton(
              overlay: true,
              onTap: () => context.canPop() ? context.pop() : context.go('/home'))),
          Positioned(top: 12, right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFFE8F5E8) : FeezColors.off,
                borderRadius: BorderRadius.circular(20)),
              child: Text(isOpen ? '🟢 Ouvert' : '🔴 Fermé',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: isOpen ? FeezColors.green : FeezColors.low)))),
        ]),

        // ── Infos resto ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['name'] ?? 'Restaurant',
              style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 24,
                fontWeight: FontWeight.w900, color: FeezColors.ink, letterSpacing: -0.02)),
            const SizedBox(height: 3),
            Text(
              '⭐ ${(r['rating'] ?? 0.0).toStringAsFixed(1)} · ${r['delivery_time'] ?? '25-35 min'} · ${r['cuisine_type'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: FeezColors.low)),
            const SizedBox(height: 7),
            Wrap(spacing: 6, children: [
              _rtag('Livraison gratuite', food: true),
              _rtag(r['cuisine_type'] ?? 'Restaurant'),
              _rtag('Halal'),
            ]),
          ]),
        ),

        // Séparateur
        Container(height: 8, color: FeezColors.off),

        // ── Menu ──────────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: FeezColors.food, strokeWidth: 2))
          : ListView(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 6),
                child: Text('Menu',
                  style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 16,
                    fontWeight: FontWeight.w900, color: FeezColors.ink))),
              ...menu.map((item) => _MenuItem(
                item: item,
                qty: _foodCart[item['name']] ?? 0,
                onAdd: () => _addItem(item),
                onRemove: () => _removeItem(item),
              )),
              const SizedBox(height: 16),
            ]),
        ),

        // ── Food cart bar ─────────────────────────────
        if (_cartTotal > 0)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x10000000),
                blurRadius: 20, offset: Offset(0, -4))]),
            child: PremiumButton(
              label: 'Voir mon panier · ${_fmt(_cartTotal)}',
              trailingIcon: Icons.arrow_forward_rounded,
              color: FeezColors.food,
              height: 54,
              onTap: () => context.push('/cart')),
          ),
      ])),
    );
  }

  Widget _rtag(String label, {bool food = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: food ? const Color(0xFFFFF0E6) : FeezColors.off,
      borderRadius: BorderRadius.circular(5)),
    child: Text(label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: food ? FeezColors.food : FeezColors.mid)));
}

class _MenuItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int qty;
  final VoidCallback onAdd, onRemove;
  const _MenuItem({required this.item, required this.qty, required this.onAdd, required this.onRemove});

  static String _fmt(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FeezColors.line))),
    child: Row(children: [
      // Image
      Container(width: 62, height: 62,
        decoration: BoxDecoration(color: FeezColors.off, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(item['emoji'] ?? '🍽️',
          style: const TextStyle(fontSize: 27)))),
      const SizedBox(width: 12),
      // Info
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item['name'] ?? '',
          style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 15,
            fontWeight: FontWeight.w800, color: FeezColors.ink)),
        if (item['description'] != null)
          Text(item['description'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: FeezColors.low, height: 1.4)),
        const SizedBox(height: 4),
        Text(_fmt(item['price'] as int? ?? 0),
          style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 15,
            fontWeight: FontWeight.w900, color: FeezColors.ink)),
      ])),
      // Contrôles premium
      qty == 0
        ? GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFFAFAFA)]),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: FeezColors.food, width: 1.6),
                boxShadow: const [BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 6, offset: Offset(0, 2))]),
              child: const Center(child: Icon(Icons.add_rounded,
                color: FeezColors.food, size: 20))))
        : Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFFF8A33), Color(0xFFE05F00)]),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFCB5500), width: 0.5),
              boxShadow: const [BoxShadow(
                color: Color(0x29000000),
                blurRadius: 6, offset: Offset(0, 2))]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(onTap: onRemove,
                child: const SizedBox(width: 28, height: 36,
                  child: Center(child: Icon(Icons.remove_rounded,
                    color: Colors.white, size: 14)))),
              Text('$qty', style: const TextStyle(
                fontFamily: 'BarlowCondensed', fontSize: 14,
                fontWeight: FontWeight.w900, color: Colors.white)),
              GestureDetector(onTap: onAdd,
                child: const SizedBox(width: 28, height: 36,
                  child: Center(child: Icon(Icons.add_rounded,
                    color: Colors.white, size: 14)))),
            ])),
    ]),
  );
}
