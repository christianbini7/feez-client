// lib/features/auth/providers/auth_provider.dart
// ══════════════════════════════════════════════════════════════
// Gestion de l'authentification OTP via Supabase
// ══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/supabase_service.dart';

// ── État de l'auth ─────────────────────────────────────────
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final Map<String, dynamic>? profile;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Map<String, dynamic>? profile,
    String? error,
  }) => AuthState(
    status:  status  ?? this.status,
    user:    user    ?? this.user,
    profile: profile ?? this.profile,
    error:   error,
  );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  String get firstName => profile?['first_name'] ?? 'Utilisateur';
}

// ── Notifier ───────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  static const _kCachedProfile = 'feez_cached_profile';

  Future<void> _saveCachedProfile(Map<String, dynamic>? profile) async {
    if (profile == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedProfile, jsonEncode(profile));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedProfile);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  Future<void> _clearCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedProfile);
    } catch (_) {}
  }

  void _init() async {
    // 1. Charger profil cache instantanément
    final cached = await _loadCachedProfile();

    // 2. Vérifier la session existante
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Afficher immédiatement avec données cache
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        profile: cached);
      // Rafraîchir en arrière-plan
      _loadProfile(session.user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    // Écouter les changements d'auth
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadProfile(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        _clearCachedProfile();
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<void> _loadProfile(User user) async {
    try {
      final profile = await SupabaseService.getUserProfile();
      state = AuthState(
        status:  AuthStatus.authenticated,
        user:    user,
        profile: profile,
      );
      // Sauver en cache pour prochaine ouverture
      await _saveCachedProfile(profile);
    } catch (e) {
      // Profil pas encore créé
      state = AuthState(
        status: AuthStatus.authenticated,
        user:   user,
      );
    }
  }

  /// Envoyer le code OTP
  Future<void> sendOtp(String phone) async {
    try {
      await SupabaseService.sendOtp(phone);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Vérifier le code OTP
  Future<bool> verifyOtp(String phone, String token) async {
    try {
      final res = await SupabaseService.verifyOtp(phone, token);
      if (res.user != null) {
        await _loadProfile(res.user!);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Code incorrect');
      return false;
    }
  }

  /// Compléter le profil après la première connexion
  Future<void> setupProfile({
    required String phone,
    required String firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      await SupabaseService.upsertUserProfile(
        phone:     phone,
        firstName: firstName,
        lastName:  lastName,
        email:     email,
      );

      // Recharger le profil
      final profile = await SupabaseService.getUserProfile();
      state = state.copyWith(profile: profile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await SupabaseService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Providers ──────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// Provider pour vérifier rapidement si l'user est connecté
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isAuthenticated,
);

// Provider pour le prénom de l'utilisateur
final userFirstNameProvider = Provider<String>(
  (ref) => ref.watch(authProvider).firstName,
);
