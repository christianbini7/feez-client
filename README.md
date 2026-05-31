# feez_client

Super-app de livraison ultra-rapide · Abidjan, Côte d'Ivoire

## Stack technique
- **Flutter 3.x** — UI cross-platform iOS + Android
- **Supabase** — Auth OTP, base de données PostgreSQL, Storage, Realtime
- **Riverpod** — State management (panier, auth, mode)
- **GoRouter** — Navigation déclarative
- **Google Maps** — Suivi GPS livreur
- **CinetPay** — Paiement Mobile Money (Wave, Orange, MTN)
- **Firebase FCM** — Push notifications

## Identité visuelle
- **Feez Market** : Rouge `#E8192C`
- **Feez Food** : Orange `#FF6B00`
- **App Livreur** : Vert `#00C47A`
- **Typo display** : Barlow Condensed 900
- **Typo body** : DM Sans

## Démarrage rapide

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Configurer Supabase dans lib/main.dart
#    url: 'https://VOTRE_URL.supabase.co'
#    anonKey: 'VOTRE_ANON_KEY'

# 3. Lancer
flutter run
```

## Structure du projet

```
lib/
├── main.dart                    # Point d'entrée + init Supabase
├── core/
│   ├── theme.dart               # FeezColors, FeezText, feezTheme()
│   └── router.dart              # GoRouter — toutes les routes
├── models/
│   └── product_model.dart       # ProductModel avec prix promo
├── features/
│   ├── auth/
│   │   ├── screens/             # Splash, Onboarding, Phone, OTP, Setup
│   │   └── services/            # AuthService — OTP Supabase
│   ├── home/
│   │   ├── screens/             # HomeScreen
│   │   ├── widgets/             # ProductCard (style Blinkit)
│   │   └── providers/           # productsProvider
│   ├── cart/
│   │   ├── screens/             # CartScreen, BasketBar
│   │   └── providers/           # MarketCartNotifier, FoodCartNotifier
│   ├── orders/
│   │   ├── screens/             # OrdersScreen, TrackingScreen
│   │   └── providers/           # orderProvider
│   └── profile/
│       └── screens/             # ProfileScreen
```

## Prochaines étapes (Sprint 1)

1. `flutter pub get` — installer les dépendances
2. Créer le projet Supabase et configurer les clés
3. Coder le HomeScreen complet avec la grille de produits
4. Connecter le CartProvider à la BasketBar
5. Implémenter l'auth OTP réelle

## Polices à télécharger

Télécharger depuis Google Fonts et placer dans `assets/fonts/` :
- Barlow Condensed : Bold (700), ExtraBold (800), Black (900), BlackItalic
- DM Sans : Regular (400), Medium (500), SemiBold (600), Bold (700)
