import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      image: 'assets/onboarding/deliv.png',
      bgTop: Color(0xFF7B6CF7),
      bgBottom: Color(0xFF5B4CE0),
      title: 'Livré en\n15 minutes',
      body: 'Épicerie, pharmacie, beauté — directement chez toi à Abidjan.',
      cta: 'Continuer',
    ),
    _Slide(
      image: 'assets/onboarding/food.png',
      bgTop: Color(0xFF0D1B2A),
      bgBottom: Color(0xFF162940),
      title: 'Tes restos\npréférés',
      body: 'Commande chez les meilleurs restaurants. Livré chaud en 30 min.',
      cta: 'Continuer',
    ),
    _Slide(
      image: 'assets/onboarding/pay.jpg',
      bgTop: Color(0xFF7B6CF7),
      bgBottom: Color(0xFF5B4CE0),
      title: 'Paiement\nfacile',
      body: 'Wave, Orange Money, MTN ou cash. Tout le monde peut commander.',
      cta: 'Commencer',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.go('/auth/phone');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final slide = _slides[_page];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: slide.bgTop,
        body: Stack(children: [

          // ── Pages swipeable ───────────────────────────
          PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlidePage(
              slide: _slides[i], size: size),
          ),

          // ── Skip ─────────────────────────────────────
          if (_page < _slides.length - 1)
            Positioned(
              top: 0, right: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _finish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30))),
                    child: const Text('Passer',
                      style: TextStyle(fontFamily: 'DMSans',
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.white)))))),

          // ── Content bas ───────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomContent(
              slide: slide,
              page: _page,
              total: _slides.length,
              onNext: _page < _slides.length - 1
                ? () => _ctrl.nextPage(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOutCubic)
                : _finish,
            )),
        ])));
  }
}

// ── Slide page ────────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _Slide slide;
  final Size size;
  const _SlidePage({required this.slide, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [slide.bgTop, slide.bgBottom])),
    child: Image.asset(
      slide.image,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover));
}

// ── Bottom content ────────────────────────────────────────────
class _BottomContent extends StatelessWidget {
  final _Slide slide;
  final int page, total;
  final VoidCallback onNext;
  const _BottomContent({
    required this.slide, required this.page,
    required this.total, required this.onNext});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.25, 1],
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.55),
          Colors.black.withValues(alpha: 0.90),
        ])),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero).animate(anim),
                  child: child)),
              child: Text(slide.title,
                key: ValueKey(page),
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 50, fontWeight: FontWeight.w900,
                  color: Colors.white, height: 0.95,
                  letterSpacing: -1.2))),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(slide.body,
                key: ValueKey('b$page'),
                style: TextStyle(
                  fontFamily: 'DMSans', fontSize: 14.5,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.5))),
            const SizedBox(height: 32),
            Row(children: [
              // Dots
              Row(children: List.generate(total, (i) =>
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: i == page ? 24 : 7, height: 7,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: i == page
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(4))))),
              const Spacer(),
              // CTA
              GestureDetector(
                onTap: onNext,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.fromLTRB(22, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 20, offset: const Offset(0, 4))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(slide.cta,
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontSize: 17, fontWeight: FontWeight.w900,
                        color: Color(0xFF0D0D0D), letterSpacing: 0.02)),
                    const SizedBox(width: 8),
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D0D0D),
                        shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14)),
                  ])),
              ),
            ]),
          ]))));
}

class _Slide {
  final String image, title, body, cta;
  final Color bgTop, bgBottom;
  const _Slide({required this.image, required this.title,
    required this.body, required this.cta,
    required this.bgTop, required this.bgBottom});
}