import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/auth_provider.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});
  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  int _step = 0;
  bool _loading = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  String _selectedZone = '';

  final _zones = [
    {'name':'Cocody','sub':'Riviera, II Plateaux, Angré, Bingerville','emoji':'🏘️'},
    {'name':'Plateau','sub':'Centre ville, Administration','emoji':'🏙️'},
    {'name':'Marcory','sub':'Zone 4, Koumassi, Treichville','emoji':'🏡'},
    {'name':'Yopougon','sub':'Sideci, Niangon, Wassakara','emoji':'🌇'},
    {'name':'Abobo','sub':'PK18, Baoulé, Gendarmerie','emoji':'🏘️'},
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step) {
      case 0: return _firstNameCtrl.text.trim().length >= 2;
      case 1: return true; // email optionnel
      case 2: return _selectedZone.isNotEmpty;
      default: return false;
    }
  }

  Future<void> _next() async {
    if (!_canContinue) return;
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    // Dernière étape → sauvegarder
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      await ref.read(authProvider.notifier).setupProfile(
        phone:     auth.user?.phone ?? '',
        firstName: _firstNameCtrl.text.trim(),
        lastName:  _lastNameCtrl.text.trim().isNotEmpty ? _lastNameCtrl.text.trim() : null,
        email:     _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('$e'),backgroundColor:FeezColors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24,16,24,0),
            child: Row(children: List.generate(3, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds:300),
                height: 4,
                margin: const EdgeInsets.only(right:4),
                decoration: BoxDecoration(
                  color: i <= _step ? FeezColors.red : FeezColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ))),
          ),

          const SizedBox(height:8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal:24),
            child: Row(children: [
              if (_step > 0)
                GestureDetector(
                  onTap: () => setState(() => _step--),
                  child: Container(width:34,height:34,
                    decoration:BoxDecoration(color:FeezColors.off,borderRadius:BorderRadius.circular(9)),
                    child:const Icon(Icons.arrow_back_ios_new,size:14,color:FeezColors.mid)),
                ),
              const Spacer(),
              Text('${_step+1} / 3',style:const TextStyle(fontSize:12,color:FeezColors.low,fontWeight:FontWeight.w600)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24,16,24,0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds:300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin:const Offset(0.05,0),end:Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStep(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24,12,24,32),
            child: GestureDetector(
              onTap: _canContinue ? _next : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds:200),
                opacity: _canContinue ? 1.0 : 0.45,
                child: Container(
                  height:56,width:double.infinity,
                  decoration:BoxDecoration(
                    color:FeezColors.red,borderRadius:BorderRadius.circular(16),
                    boxShadow:_canContinue ? [BoxShadow(color:FeezColors.red.withOpacity(0.3),blurRadius:16,offset:const Offset(0,6))] : null,
                  ),
                  child:Center(child: _loading
                    ? const SizedBox(width:22,height:22,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2.5))
                    : Text(_step==2 ? 'Commencer !' : 'Continuer →',
                        style:const TextStyle(fontFamily:'BarlowCondensed',fontSize:18,
                          fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:0.03))),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(key:const ValueKey(0),crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('Ton\nprénom',style:TextStyle(fontFamily:'BarlowCondensed',fontSize:38,fontWeight:FontWeight.w900,color:FeezColors.ink,height:1.0,letterSpacing:-0.5)),
          const SizedBox(height:6),
          const Text('Pour personnaliser ton expérience Feez',style:TextStyle(fontSize:14,color:FeezColors.mid)),
          const SizedBox(height:28),
          _field(_firstNameCtrl,'Prénom *',Icons.person_outline, onChanged: (_) => setState((){})),
          const SizedBox(height:14),
          _field(_lastNameCtrl,'Nom (optionnel)',Icons.person_outline),
        ]);
      case 1:
        return Column(key:const ValueKey(1),crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('Ton\nadresse email',style:TextStyle(fontFamily:'BarlowCondensed',fontSize:38,fontWeight:FontWeight.w900,color:FeezColors.ink,height:1.0,letterSpacing:-0.5)),
          const SizedBox(height:6),
          const Text('Optionnel — pour recevoir tes reçus par email',style:TextStyle(fontSize:14,color:FeezColors.mid)),
          const SizedBox(height:28),
          _field(_emailCtrl,'Email (optionnel)',Icons.email_outlined, keyboardType:TextInputType.emailAddress),
          const SizedBox(height:14),
          Container(padding:const EdgeInsets.all(12),
            decoration:BoxDecoration(color:const Color(0xFFF0FFF8),borderRadius:BorderRadius.circular(10),border:Border.all(color:const Color(0xFFBBF7D0))),
            child:const Row(children:[Text('🔒',style:TextStyle(fontSize:14)),SizedBox(width:8),
              Expanded(child:Text('Ton email ne sera jamais partagé',style:TextStyle(fontSize:12,color:Color(0xFF166534))))])),
        ]);
      case 2:
        return Column(key:const ValueKey(2),crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('Où es-tu\nà Abidjan ?',style:TextStyle(fontFamily:'BarlowCondensed',fontSize:38,fontWeight:FontWeight.w900,color:FeezColors.ink,height:1.0,letterSpacing:-0.5)),
          const SizedBox(height:6),
          const Text('Pour estimer tes délais et frais de livraison',style:TextStyle(fontSize:14,color:FeezColors.mid)),
          const SizedBox(height:20),
          ..._zones.map((z) => GestureDetector(
            onTap: () => setState(() => _selectedZone = z['name']!),
            child: AnimatedContainer(
              duration:const Duration(milliseconds:180),
              margin:const EdgeInsets.only(bottom:10),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                color:_selectedZone==z['name'] ? const Color(0xFFFFF0F0) : Colors.white,
                borderRadius:BorderRadius.circular(14),
                border:Border.all(
                  color:_selectedZone==z['name'] ? FeezColors.red : FeezColors.line,
                  width:_selectedZone==z['name'] ? 1.5 : 1,
                ),
              ),
              child:Row(children:[
                Text(z['emoji']!,style:const TextStyle(fontSize:22)),
                const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(z['name']!,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:FeezColors.ink)),
                  Text(z['sub']!,style:const TextStyle(fontSize:11,color:FeezColors.low)),
                ])),
                if (_selectedZone==z['name'])
                  Container(width:22,height:22,decoration:const BoxDecoration(color:FeezColors.red,shape:BoxShape.circle),
                    child:const Icon(Icons.check,color:Colors.white,size:14)),
              ]),
            ),
          )),
          const SizedBox(height:10),
          GestureDetector(
            onTap: () => setState(() => _selectedZone = 'Ma position'),
            child: Container(
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                color:_selectedZone=='Ma position' ? const Color(0xFFFFF0F0) : Colors.white,
                borderRadius:BorderRadius.circular(14),
                border:Border.all(color:_selectedZone=='Ma position' ? FeezColors.red : FeezColors.line),
              ),
              child:Row(children:[
                Container(width:36,height:36,decoration:BoxDecoration(color:FeezColors.red.withOpacity(0.1),shape:BoxShape.circle),
                  child:const Icon(Icons.my_location,color:FeezColors.red,size:18)),
                const SizedBox(width:12),
                const Text('Utiliser ma position GPS',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:FeezColors.ink)),
              ]),
            ),
          ),
        ]);
      default: return const SizedBox();
    }
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, void Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize:15,fontWeight:FontWeight.w500,color:FeezColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color:FeezColors.low,fontWeight:FontWeight.w400),
        prefixIcon: Icon(icon,color:FeezColors.low,size:20),
        filled: true, fillColor: FeezColors.off,
        border: OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(13),borderSide:const BorderSide(color:FeezColors.red,width:1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal:16,vertical:14),
      ),
    );
  }
}
