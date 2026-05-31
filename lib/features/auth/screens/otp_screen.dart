import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  String _otp = '';
  bool _loading = false;
  bool _error = false;
  int _countdown = 59;
  Timer? _timer;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync:this,duration:const Duration(milliseconds:500));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween:Tween(begin:0.0,end:-8.0),weight:1),
      TweenSequenceItem(tween:Tween(begin:-8.0,end:8.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:8.0,end:-8.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:-8.0,end:8.0),weight:2),
      TweenSequenceItem(tween:Tween(begin:8.0,end:0.0),weight:1),
    ]).animate(CurvedAnimation(parent:_shakeCtrl,curve:Curves.linear));
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 59);
    _timer = Timer.periodic(const Duration(seconds:1), (_) {
      if (_countdown > 0) setState(() => _countdown--);
      else _timer?.cancel();
    });
  }

  @override
  void dispose() { _shakeCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  void _kp(String d) {
    if (_otp.length >= 6 || _loading) return;
    HapticFeedback.lightImpact();
    setState(() { _otp += d; _error = false; });
    if (_otp.length == 6) _verify();
  }

  void _del() {
    if (_otp.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() { _otp = _otp.substring(0, _otp.length-1); _error = false; });
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final ok = await ref.read(authProvider.notifier).verifyOtp(widget.phone, _otp);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.heavyImpact();
        context.go('/auth/verified');
      } else {
        HapticFeedback.vibrate();
        setState(() { _otp = ''; _loading = false; _error = true; });
        _shakeCtrl.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() { _otp = ''; _loading = false; _error = true; });
      _shakeCtrl.forward(from: 0);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    try {
      await ref.read(authProvider.notifier).sendOtp(widget.phone);
      _startCountdown();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Code renvoyé !'),
        backgroundColor: FeezColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20,12,20,0),
            child: Row(children: [
              FeezBackButton(
                onTap: () => context.canPop() ? context.pop() : context.go('/home')),
              const Spacer(),
              const Text('feez',
                style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 24,
                  fontWeight: FontWeight.w900, fontStyle: FontStyle.italic,
                  color: FeezColors.red, letterSpacing: -0.02)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6E9),
                  borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('📱', style: TextStyle(fontSize: 26)))),
              const SizedBox(height: 18),
              const Text('Code de\nvérification',
                style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: FeezColors.ink, height: 1.0, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              RichText(text: TextSpan(
                style: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 13.5, color: FeezColors.mid, height: 1.5),
                children: [
                  const TextSpan(text: 'Code envoyé au '),
                  TextSpan(text: widget.phone,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: FeezColors.ink)),
                ],
              )),
            ]),
          ),

          const SizedBox(height:32),

          // ── Boxes OTP ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:24),
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _otp.length;
                  final active = i == _otp.length && !_loading;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds:200),
                    margin: const EdgeInsets.symmetric(horizontal:4),
                    width: 46, height: 54,
                    decoration: BoxDecoration(
                      color: _error
                        ? const Color(0xFFFFF0F0)
                        : filled ? FeezColors.off : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _error
                          ? FeezColors.red
                          : active ? FeezColors.red
                          : filled ? FeezColors.ink
                          : FeezColors.line,
                        width: (active || _error) ? 2 : 1.5,
                      ),
                      boxShadow: active ? [BoxShadow(color:FeezColors.red.withOpacity(0.15),blurRadius:8)] : null,
                    ),
                    child: Center(child: _loading && i == 0
                      ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:FeezColors.red))
                      : Text(filled ? '•' : '',
                          style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:FeezColors.ink))),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height:16),

          // ── Message erreur / renvoyer ─────────────────────
          Center(
            child: _error
              ? Text('Code incorrect. Réessaie.',
                  style:const TextStyle(fontSize:13,color:FeezColors.red,fontWeight:FontWeight.w600))
              : GestureDetector(
                  onTap: _resend,
                  child: RichText(text:TextSpan(
                    style:const TextStyle(fontSize:13),
                    children:[
                      TextSpan(text:'Renvoyer le code',
                        style:TextStyle(fontWeight:FontWeight.w700,
                          color:_countdown>0 ? FeezColors.low : FeezColors.red)),
                      if (_countdown > 0)
                        TextSpan(text:' dans ${_countdown}s',
                          style:const TextStyle(color:FeezColors.low)),
                    ],
                  )),
                ),
          ),

          const Spacer(),

          // ── Clavier ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16),
            child: Column(children: [
              for (final row in [['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']])
                Row(children: row.map((k) => Expanded(
                  child: k.isEmpty ? const SizedBox() : Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color:Colors.transparent,
                      child:InkWell(
                        onTap: _loading ? null : () => k=='⌫' ? _del() : _kp(k),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical:15),
                          decoration: BoxDecoration(color:FeezColors.off,borderRadius:BorderRadius.circular(14)),
                          child: Center(child: k=='⌫'
                            ? const Icon(Icons.backspace_outlined,size:20,color:FeezColors.mid)
                            : Text(k,style:const TextStyle(fontFamily:'BarlowCondensed',
                                fontSize:24,fontWeight:FontWeight.w900,color:FeezColors.ink))),
                        ),
                      ),
                    ),
                  ),
                )).toList()),
            ]),
          ),
          const SizedBox(height:24),
        ]),
      ),
    );
  }
}
