import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';
import '../providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen>
    with SingleTickerProviderStateMixin {
  String _digits = '';
  bool _loading = false;
  String _countryCode = '+225';
  String _countryFlag = '🇨🇮';

  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  final _countries = [
    {'flag':'🇨🇮','code':'+225','name':'Côte d\'Ivoire'},
    {'flag':'🇸🇳','code':'+221','name':'Sénégal'},
    {'flag':'🇲🇱','code':'+223','name':'Mali'},
    {'flag':'🇧🇫','code':'+226','name':'Burkina Faso'},
    {'flag':'🇹🇬','code':'+228','name':'Togo'},
    {'flag':'🇧🇯','code':'+229','name':'Bénin'},
    {'flag':'🇬🇳','code':'+224','name':'Guinée'},
    {'flag':'🇳🇪','code':'+227','name':'Niger'},
  ];

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(vsync:this,duration:const Duration(milliseconds:100));
    _btnScale = Tween<double>(begin:1.0,end:0.94).animate(
      CurvedAnimation(parent:_btnCtrl,curve:Curves.easeInOut));
  }

  @override
  void dispose() { _btnCtrl.dispose(); super.dispose(); }

  void _kp(String d) {
    if (_digits.length >= 10) return;
    HapticFeedback.lightImpact();
    setState(() => _digits += d);
  }

  void _del() {
    if (_digits.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  String get _formatted {
    // Format: XX XX XX XX XX
    final parts = <String>[];
    for (int i = 0; i < _digits.length; i += 2) {
      parts.add(_digits.substring(i, (i+2).clamp(0, _digits.length)));
    }
    return parts.join(' ');
  }

  String get _fullPhone => '$_countryCode${_digits.replaceAll(' ', '')}';

  Future<void> _continue() async {
    if (_digits.length < 8 || _loading) return;
    _btnCtrl.forward().then((_) => _btnCtrl.reverse());
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(_fullPhone);
      if (mounted) context.push('/auth/otp', extra: _fullPhone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur d\'envoi: $e'),
          backgroundColor: FeezColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width:40,height:4,margin:const EdgeInsets.only(top:12,bottom:16),
            decoration:BoxDecoration(color:FeezColors.line,borderRadius:BorderRadius.circular(2))),
          const Padding(padding:EdgeInsets.only(left:20,bottom:12),
            child:Text('Indicatif pays',style:TextStyle(fontFamily:'BarlowCondensed',fontSize:20,fontWeight:FontWeight.w900))),
          ..._countries.map((c) => ListTile(
            leading: Text(c['flag']!,style:const TextStyle(fontSize:24)),
            title: Text(c['name']!,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:14)),
            trailing: Text(c['code']!,style:const TextStyle(color:FeezColors.mid,fontWeight:FontWeight.w600)),
            onTap: () {
              setState(() { _countryCode=c['code']!; _countryFlag=c['flag']!; });
              Navigator.pop(context);
            },
          )),
          const SizedBox(height:16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _digits.length >= 8 && !_loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          // ── Header foncé ──────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Back + logo
                Row(children: [
                  FeezBackButton(onTap: () => context.go('/onboarding')),
                  const Spacer(),
                  const Text('feez',
                    style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 24,
                      fontWeight: FontWeight.w900, fontStyle: FontStyle.italic,
                      color: FeezColors.red, letterSpacing: -0.02)),
                ]),
                const SizedBox(height: 36),
                const Text('Ton numéro\nde téléphone',
                  style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 32,
                    fontWeight: FontWeight.w900, color: FeezColors.ink,
                    height: 1.05, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                const Text('Tu recevras un SMS de confirmation',
                  style: TextStyle(fontFamily: 'DMSans',
                    fontSize: 13.5, color: FeezColors.mid)),
              ]),
            ),
          ),

          // ── Saisie numéro ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NUMÉRO', style: TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:FeezColors.low,letterSpacing:0.18)),
              const SizedBox(height:8),
              Row(children: [
                // Indicatif pays
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal:12,vertical:14),
                    decoration: BoxDecoration(color:FeezColors.off,borderRadius:BorderRadius.circular(13),border:Border.all(color:FeezColors.line)),
                    child: Row(children: [
                      Text(_countryFlag,style:const TextStyle(fontSize:18)),
                      const SizedBox(width:6),
                      Text(_countryCode,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:FeezColors.ink)),
                      const SizedBox(width:4),
                      const Icon(Icons.keyboard_arrow_down_rounded,size:16,color:FeezColors.low),
                    ]),
                  ),
                ),
                const SizedBox(width:10),
                // Numéro saisi
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds:200),
                    padding: const EdgeInsets.symmetric(horizontal:16,vertical:14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _digits.isNotEmpty ? FeezColors.red : FeezColors.line,
                        width: _digits.isNotEmpty ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(
                        _digits.isEmpty ? '00 00 00 00 00' : _formatted,
                        style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600,
                          color: _digits.isEmpty ? FeezColors.low : FeezColors.ink,
                          letterSpacing: 1.5,
                        ),
                      )),
                      if (_digits.isNotEmpty)
                        Container(width:8,height:18,decoration:BoxDecoration(
                          color:FeezColors.red,borderRadius:BorderRadius.circular(1))),
                    ]),
                  ),
                ),
              ]),

              const SizedBox(height:12),
              Row(children: [
                const Icon(Icons.lock_outline,size:12,color:FeezColors.low),
                const SizedBox(width:5),
                const Text('Ton numéro est protégé et ne sera jamais partagé',
                  style:TextStyle(fontSize:11,color:FeezColors.low)),
              ]),
            ]),
          ),

          const Spacer(),

          // ── Clavier ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal:16),
            child: Column(children: [
              for (final row in [
                ['1','2','3'],
                ['4','5','6'],
                ['7','8','9'],
                ['','0','⌫'],
              ])
                Row(children: row.map((k) => Expanded(
                  child: k.isEmpty ? const SizedBox() : Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => k=='⌫' ? _del() : _kp(k),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical:15),
                          decoration: BoxDecoration(
                            color: k=='⌫' ? Colors.transparent : FeezColors.off,
                            borderRadius: BorderRadius.circular(14),
                          ),
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

          // ── Bouton continuer ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24,12,24,32),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: canContinue ? 1.0 : 0.5,
              child: PremiumButton(
                label: 'Recevoir le code',
                trailingIcon: Icons.arrow_forward_rounded,
                height: 56, fontSize: 18,
                loading: _loading,
                onTap: canContinue ? _continue : null)),
          ),
        ]),
      ),
    );
  }
}
