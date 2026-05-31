import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final p = auth.profile;
    String name = 'Utilisateur Feez';
    final firstName = p?['first_name']?.toString().trim() ?? '';
    final lastName  = p?['last_name']?.toString().trim() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      name = '$firstName $lastName'.trim();
    } else if ((p?['full_name'] as String?)?.trim().isNotEmpty == true) {
      name = p!['full_name'] as String;
    }
    final phone = p?['phone'] as String? ?? auth.user?.phone ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: ListView(padding: const EdgeInsets.fromLTRB(0, 0, 0, 110), children: [

        // ══════ HEADER élégant avec carte avatar ════════
        Container(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          color: Colors.white,
          child: Column(children: [
            // Titre page
            const Row(children: [
              Text('Profil', style: TextStyle(
                fontFamily: 'BarlowCondensed', fontSize: 26,
                fontWeight: FontWeight.w900, color: FeezColors.ink,
                letterSpacing: -0.02)),
            ]),
            const SizedBox(height: 18),
            // Card user
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFE8192C), Color(0xFFC91426)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: FeezColors.red.withValues(alpha: 0.30),
                  blurRadius: 20, offset: const Offset(0, 8))]),
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                // Pattern pois blancs en arrière-plan
                Positioned.fill(child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(painter: _ProfileDotsPainter()))),
                // Lueur décorative
                Positioned(right: -30, top: -30,
                  child: Container(width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10)))),
                // Contenu
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 64, height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                      child: Center(child: Text(initial,
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed', fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: FeezColors.red, height: 1)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'BarlowCondensed', fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white, letterSpacing: -0.02)),
                        if (phone.isNotEmpty)
                          Text(phone, style: TextStyle(
                            fontFamily: 'DMSans', fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(6)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.verified_rounded,
                              color: Colors.white, size: 11),
                            SizedBox(width: 3),
                            Text('Membre Feez', style: TextStyle(
                              fontFamily: 'DMSans', fontSize: 10,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                          ])),
                      ])),
                  ]),
                ),
              ])),
          ])),

        const SizedBox(height: 12),

        // ══════ 3 STATS minimalistes ════════
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
            child: Row(children: [
              _stat('12', 'Commandes'),
              _vsep(),
              _stat('8', 'Favoris'),
              _vsep(),
              _stat('3', 'Promos'),
            ]))),

        const SizedBox(height: 16),

        // ══════ SECTIONS ════════
        _section(context, 'MON COMPTE', [
          _ProfileItem(Icons.person_outline, 'Informations', 'Nom, téléphone, email', const Color(0xFF42A5F5)),
          _ProfileItem(Icons.location_on_outlined, 'Mes adresses', 'Cocody, Marcory…', const Color(0xFFEF5350)),
          _ProfileItem(Icons.payment_outlined, 'Paiement', 'Wave, Orange, MTN', const Color(0xFF66BB6A)),
        ]),
        _section(context, 'ACTIVITÉS', [
          _ProfileItem(Icons.history_rounded, 'Mes commandes', '12 commandes',
            const Color(0xFF7E57C2), route: '/orders'),
          _ProfileItem(Icons.favorite_outline, 'Mes favoris', '8 produits',
            const Color(0xFFE91E63)),
          _ProfileItem(Icons.notifications_outlined, 'Notifications', 'Activées',
            const Color(0xFFFFA726)),
        ]),
        _section(context, 'PRÉFÉRENCES', [
          _ProfileItem(Icons.language_outlined, 'Langue', 'Français', const Color(0xFF26A69A)),
          _ProfileItem(Icons.dark_mode_outlined, 'Apparence', 'Clair', const Color(0xFF607D8B)),
        ]),
        _section(context, 'SUPPORT', [
          _ProfileItem(Icons.help_outline, 'Aide', 'FAQ, support', const Color(0xFF42A5F5)),
          _ProfileItem(Icons.info_outline, 'À propos', 'Conditions, confidentialité', const Color(0xFF78909C)),
          _ProfileItem(Icons.star_outline_rounded, 'Noter Feez', 'Sur le store', const Color(0xFFFFB300)),
        ]),

        const SizedBox(height: 12),

        // Déconnexion
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/onboarding');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE4E4), width: 1)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout_rounded, color: FeezColors.red, size: 18),
                SizedBox(width: 8),
                Text('Se déconnecter', style: TextStyle(
                  fontFamily: 'BarlowCondensed', fontSize: 16,
                  fontWeight: FontWeight.w800, color: FeezColors.red)),
              ])))),

        const SizedBox(height: 16),
        Center(child: Text('feez · v1.0',
          style: TextStyle(
            fontFamily: 'BarlowCondensed', fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.black.withValues(alpha: 0.30)))),
      ]),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(
        fontFamily: 'BarlowCondensed', fontSize: 24,
        fontWeight: FontWeight.w900, color: FeezColors.ink, height: 1)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
        fontFamily: 'DMSans', fontSize: 11,
        fontWeight: FontWeight.w600, color: FeezColors.mid)),
    ]));

  Widget _vsep() => Container(
    width: 0.5, height: 32, color: const Color(0xFFEEEEEE));

  Widget _section(BuildContext context, String title, List<_ProfileItem> items) =>
    Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Text(title, style: const TextStyle(
            fontFamily: 'DMSans', fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: FeezColors.low, letterSpacing: 0.12))),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5)),
          child: Column(children: List.generate(items.length, (i) {
            final it = items[i];
            return Column(children: [
              InkWell(
                onTap: it.route != null ? () => context.push(it.route!) : () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(children: [
                    Container(width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: it.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(it.icon, color: it.color, size: 16)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.label, style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 13,
                          fontWeight: FontWeight.w700, color: FeezColors.ink)),
                        Text(it.subtitle, style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 11, color: FeezColors.low)),
                      ])),
                    const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCCCCCC), size: 18),
                  ]))),
              if (i < items.length - 1)
                const Padding(padding: EdgeInsets.only(left: 54),
                  child: Divider(height: 0.5, color: Color(0xFFF0F0F0))),
            ]);
          }))),
      ]));
}

class _ProfileItem {
  final IconData icon;
  final String label, subtitle;
  final Color color;
  final String? route;
  _ProfileItem(this.icon, this.label, this.subtitle, this.color, {this.route});
}

class _ProfileDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    const spacing = 14.0;
    const radius = 1.2;
    for (double y = 6; y < size.height; y += spacing) {
      for (double x = 6; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dot);
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}
