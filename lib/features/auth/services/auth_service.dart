import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // 1. Envoyer OTP par SMS
  Future<void> sendOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  // 2. Vérifier le code OTP
  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // 3. Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 4. Utilisateur courant
  User? get currentUser => _supabase.auth.currentUser;

  // 5. Stream de changements de session
  Stream<AuthState> get authStateChanges =>
    _supabase.auth.onAuthStateChange;
}
