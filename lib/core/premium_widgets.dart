// lib/core/premium_widgets.dart
// ══════════════════════════════════════════════════════════════
// Kit de composants premium réutilisables :
//  • PremiumButton  → bouton avec gradient, highlight, ombre
//  • PremiumCard    → card avec bordure subtile + ombre douce
//  • TapScale       → wrapper avec animation scale au tap
//  • SkeletonBox    → placeholder shimmer-ready
// ══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'theme.dart';

// ── Bouton premium réaliste ───────────────────────────────────
class PremiumButton extends StatefulWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final double fontSize;
  final bool loading;
  final Widget? leading;

  const PremiumButton({super.key,
    required this.label,
    required this.onTap,
    this.color = FeezColors.red,
    this.textColor = Colors.white,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 54,
    this.radius = 16,
    this.fontSize = 17,
    this.loading = false,
    this.leading,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null || widget.loading;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp:   disabled ? null : (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: widget.height,
        decoration: BoxDecoration(
          // Style flat moderne (pas de gradient)
          color: _pressed ? _darken(widget.color, 0.07) : widget.color,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _pressed
            ? null
            : [BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: widget.loading
            ? SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                  color: widget.textColor, strokeWidth: 2.4))
            : Row(mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, children: [
                if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 8)],
                if (widget.leadingIcon != null) ...[
                  Icon(widget.leadingIcon, color: widget.textColor, size: 19),
                  const SizedBox(width: 9),
                ],
                Text(widget.label, style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w900,
                  color: widget.textColor,
                  letterSpacing: 0.02)),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(widget.trailingIcon, color: widget.textColor, size: 18),
                ],
              ])),
      ),
    );
  }
}

// ── Bouton secondaire (outline) ───────────────────────────────
class SecondaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final double height;
  final double radius;

  const SecondaryButton({super.key,
    required this.label,
    required this.onTap,
    this.color = FeezColors.red,
    this.icon,
    this.height = 50,
    this.radius = 14,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) { setState(() => _p = false); widget.onTap?.call(); },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: widget.height,
      decoration: BoxDecoration(
        gradient: _p
          ? LinearGradient(colors: [
              widget.color.withValues(alpha: 0.10),
              widget.color.withValues(alpha: 0.05),
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          : const LinearGradient(colors: [Colors.white, Color(0xFFFAFAFA)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.color, width: 1.4),
      ),
      child: Center(child: Row(mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.color, size: 18),
            const SizedBox(width: 8),
          ],
          Text(widget.label, style: TextStyle(
            fontFamily: 'BarlowCondensed', fontSize: 16,
            fontWeight: FontWeight.w900, color: widget.color)),
        ])),
    ),
  );
}

// ── Card premium ──────────────────────────────────────────────
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  const PremiumCard({super.key, required this.child,
    this.padding, this.margin, this.radius = 16, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(14),
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        boxShadow: const [BoxShadow(color: Color(0x08000000),
          blurRadius: 10, offset: Offset(0, 3))]),
      child: child);
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}

// ── Wrapper tap scale (micro-animation) ───────────────────────
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const TapScale({super.key, required this.child,
    this.onTap, this.scale = 0.97});
  @override State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 110));
    _anim = Tween<double>(begin: 1.0, end: widget.scale)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) => _ctrl.reverse(),
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _anim, child: widget.child));
}

// ── Box skeleton (à utiliser dans Shimmer.fromColors) ────────
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool circle;
  const SkeletonBox({super.key,
    this.width, required this.height,
    this.borderRadius, this.circle = false});
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : (borderRadius ?? BorderRadius.circular(8))));
}

// ── Section header (titre + voir tout) ────────────────────────
class SectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.label,
    this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label.toUpperCase(), style: const TextStyle(
      fontFamily: 'DMSans', fontSize: 10.5,
      fontWeight: FontWeight.w800,
      color: FeezColors.low, letterSpacing: 0.10)),
    const Spacer(),
    if (actionLabel != null)
      GestureDetector(
        onTap: onAction,
        child: Text(actionLabel!, style: const TextStyle(
          fontFamily: 'DMSans', fontSize: 11.5,
          fontWeight: FontWeight.w700, color: FeezColors.red))),
  ]);
}

// ── Bouton retour UNIFORME (à utiliser partout) ───────────────
class FeezBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool overlay; // True si sur image/header coloré
  const FeezBackButton({super.key, this.onTap, this.overlay = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: overlay
          ? Colors.white.withValues(alpha: 0.92)
          : Colors.white,
        shape: BoxShape.circle,
        border: overlay ? null
          : Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        boxShadow: const [BoxShadow(
          color: Color(0x14000000),
          blurRadius: 8, offset: Offset(0, 2))]),
      child: const Center(child: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 16, color: Color(0xFF0D0D0D)))));
}

// ── Texte expandable avec "Voir plus" ────────────────────────
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextStyle? actionStyle;
  const ExpandableText({super.key,
    required this.text,
    this.maxLines = 2,
    this.style, this.actionStyle});
  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final tp = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.maxWidth);
      final overflow = tp.didExceedMaxLines;

      if (!overflow) return Text(widget.text, style: widget.style);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.text,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: widget.style),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Voir moins' : 'Voir plus',
            style: widget.actionStyle ?? const TextStyle(
              fontFamily: 'DMSans', fontSize: 11.5,
              fontWeight: FontWeight.w700, color: FeezColors.red))),
      ]);
    });
}
