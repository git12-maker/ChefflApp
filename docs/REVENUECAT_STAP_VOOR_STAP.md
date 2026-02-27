# RevenueCat + In-App Purchases – Stap voor Stap

Chronologische handleiding om RevenueCat volledig werkend en store-compliant op te zetten voor Cheffl.

**Tijdsindicatie:** 2–4 uur (excl. wachttijden van Apple/Google)

---

## Overzicht volgorde

1. **Apple** – App Store Connect (account, agreement, producten)
2. **Google** – Play Console (account, merchant, producten)
3. **RevenueCat** – Account, project, apps, producten, entitlements, offerings
4. **Code** – Flutter SDK, initialisatie, paywall
5. **Webhook** – Supabase Edge Function
6. **Testen** – Sandbox purchases
7. **Compliance** – Restore, privacy, store rules

---

# DEEL A: Apple App Store Connect

## Stap A1 – Apple Developer Account

- [ ] Ga naar [developer.apple.com](https://developer.apple.com) en meld je aan
- [ ] Betaal €99/jaar voor het Apple Developer Program (vereist voor in-app purchases)
- [ ] Accepteer de **Paid Applications Agreement** (App Store Connect → Agreements, Tax, and Banking)
- [ ] Vul **Belastinggegevens** in
- [ ] Vul **Bankgegevens** in (voor uitbetalingen)

Zonder deze stappen werken in-app purchases niet.

---

## Stap A2 – App registreren in App Store Connect

- [ ] Ga naar [App Store Connect](https://appstoreconnect.apple.com)
- [ ] **My Apps** → **+** → **New App**
- [ ] Vul in:
  - **Platform:** iOS
  - **Name:** Cheffl
  - **Primary Language:** Nederlands of English
  - **Bundle ID:** `com.cheffl.app`
  - **SKU:** uniek (bijv. `cheffl-001`)

> **Let op:** De Bundle ID in Xcode (`ios/Runner.xcodeproj`) moet exact overeenkomen met de Bundle ID in App Store Connect.

---

## Stap A3 – In-App Purchase Capability

In-App Purchase moet aanstaan voor je App ID. Dit kan op twee manieren:

### Optie A: Via Xcode (als de optie zichtbaar is)

- [ ] Open het project in Xcode: `ios/Runner.xcworkspace`
- [ ] Selecteer het **Runner** target
- [ ] Tab **Signing & Capabilities** → **+ Capability**
- [ ] Zoek op "In-App Purchase" of "StoreKit" en voeg toe

### Optie B: Via Apple Developer Portal (als In-App Purchase niet in Xcode staat)

Sommige Xcode-versies tonen In-App Purchase niet in de capability-lijst. Voer dan deze stappen uit:

- [ ] Ga naar [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
- [ ] **Identifiers** → selecteer je App ID (`com.cheffl.app`)
- [ ] Scroll naar **Capabilities**
- [ ] Vink **In-App Purchase** aan en klik **Save**
- [ ] Zorg dat **Automatically manage signing** aanstaat in Xcode (Signing & Capabilities)
- [ ] Doe een **Product → Clean Build Folder** in Xcode en bouw opnieuw

> **Let op:** Als je App ID al In-App Purchase had aangevinkt bij het aanmaken (Stap App ID), dan staat het waarschijnlijk al goed. Je kunt dan doorgaan naar Stap A4.

---

## Stap A4 – Producten aanmaken in App Store Connect

- [ ] In App Store Connect: jouw app → **Monetization** → **In-App Purchases** (of **Subscriptions** voor abonnementen)
- [ ] Maak de volgende producten aan:

### Credit packs (consumable)

| Product ID       | Type       | Prijs  | Reference Name   |
|------------------|------------|--------|------------------|
| cheffl_credits_5 | Consumable | $1.99  | Cheffl 5 Credits |
| cheffl_credits_15| Consumable | $3.99  | Cheffl 15 Credits|
| cheffl_credits_50| Consumable | $9.99  | Cheffl 50 Credits|

**Per product:**
- **Type:** Consumable (consumptie, kan opnieuw gekocht worden)
- **Reference Name:** intern (bijv. "Cheffl 5 Credits")
- **Product ID:** exact zoals boven (gebruik dit in code)
- **Price:** kies het gewenste prijsniveau
- **Localization:** minimaal 1 taal (Name + Description)
- **Review Screenshot:** maak een screenshot van de paywall in de app (kan later; nodig voor "Ready to Submit")

### Subscriptions (optioneel)

| Product ID       | Type                    | Prijs   | Reference Name   |
|------------------|-------------------------|---------|------------------|
| cheffl_pro_monthly| Auto-Renewable Subscription | $4.99  | Cheffl Pro Monthly |
| cheffl_pro_yearly | Auto-Renewable Subscription | $29.99 | Cheffl Pro Yearly  |

**Per subscription:**
- Maak een **Subscription Group** aan (bijv. "Cheffl Pro")
- Voeg subscription producten toe aan deze groep
- Stel **Base Plan** in (maandelijks/jaarlijks)
- Localization en Review Screenshot zijn verplicht

- [ ] Zorg dat elk product de status **Ready to Submit** krijgt

---

## Stap A5 – In-App Purchase Key (voor RevenueCat)

RevenueCat heeft een key nodig om purchases te valideren.

- [ ] App Store Connect → **Users and Access** → **Integrations** → **In-App Purchase**
- [ ] Klik **Generate In-App Purchase Key**
- [ ] **Name:** bijv. "RevenueCat"
- [ ] **Key ID** onthouden
- [ ] Download het **.p8** bestand (éénmalig mogelijk)
- [ ] Bewaar **Issuer ID** en **Key ID** (te vinden onder Keys)

Je hebt straks nodig: `.p8` bestand, Key ID, Issuer ID, Bundle ID.

---

# DEEL B: Google Play Console

## Stap B1 – Google Play Developer Account

- [ ] Ga naar [play.google.com/console](https://play.google.com/console)
- [ ] Betaal eenmalig $25
- [ ] Accepteer de **Developer Distribution Agreement**
- [ ] Vul belasting- en betalingsgegevens in

---

## Stap B2 – App aanmaken in Play Console

- [ ] **Create app** (of kies bestaande app)
- [ ] **Application ID:** `com.cheffl.app` (moet overeenkomen met `build.gradle.kts`)
- [ ] Vul app-details in (naam, beschrijving, etc.)

> **Belangrijk:** Voor in-app producten moet er minstens één APK of App Bundle geüpload zijn (ook als draft). Je kunt een eerste build uploaden en als intern test track gebruiken.

---

## Stap B3 – Billing-permissie

- [ ] In **android/app/src/main/AndroidManifest.xml** controleren of `<uses-permission android:name="com.android.vending.BILLING" />` aanwezig is (RevenueCat voegt dit toe via de SDK, maar controleer het)

---

## Stap B4 – In-app producten aanmaken

- [ ] Play Console → jouw app → **Monetize** → **Products** → **In-app products**
- [ ] **Create product** voor elk credit pack:

| Product ID       | Type           | Prijs  |
|------------------|----------------|--------|
| cheffl_credits_5 | One-time product | $1.99 |
| cheffl_credits_15| One-time product | $3.99 |
| cheffl_credits_50| One-time product | $9.99 |

**Vereisten:**
- **Product ID:** identiek aan Apple (zelfde IDs voor cross-platform)
- **Name** en **Description:** verplicht
- **Price:** stel in per land/regio
- **Status:** Active

### Subscriptions (optioneel)

- [ ] **Monetize** → **Subscriptions** → **Create subscription**
- [ ] Maak `cheffl_pro_monthly` en `cheffl_pro_yearly` aan met base plans

---

## Stap B5 – Service credentials voor RevenueCat

- [ ] Ga naar [Google Cloud Console](https://console.cloud.google.com)
- [ ] Selecteer het project dat gekoppeld is aan je Play Console-app
- [ ] **APIs & Services** → **Credentials** → **Create credentials** → **Service account**
- [ ] Geef een naam (bijv. "RevenueCat")
- [ ] Maak de service account
- [ ] Klik op de service account → **Keys** → **Add key** → **Create new key** → **JSON**
- [ ] Download en bewaar het JSON-bestand
- [ ] Terug naar **Play Console** → **Users and permissions** → voeg de service account toe met **Admin**-rechten voor **Financial data**

> **Let op:** Credentials kunnen tot 36 uur nodig hebben om actief te worden.

---

# DEEL C: RevenueCat Dashboard

## Stap C1 – Account en project

- [ ] Ga naar [app.revenuecat.com](https://app.revenuecat.com) en maak een account
- [ ] **+ New Project** → naam: "Cheffl"

---

## Stap C2 – iOS-app toevoegen

- [ ] Project → **+ New** → **App**
- [ ] **Platform:** Apple App Store
- [ ] **App name:** Cheffl iOS
- [ ] **Bundle ID:** `com.cheffl.app` (exact zoals in App Store Connect)
- [ ] **Shared Secret:** niet nodig als je de In-App Purchase Key gebruikt (aanbevolen)

### In-App Purchase Key koppelen

- [ ] Ga naar **Project** → **Apps** → je iOS-app → **App Store Connect API** of **In-App Purchase**
- [ ] Upload het `.p8` bestand
- [ ] Vul **Key ID** en **Issuer ID** in
- [ ] Sla op

---

## Stap C3 – Android-app toevoegen

- [ ] Project → **+ New** → **App**
- [ ] **Platform:** Google Play Store
- [ ] **App name:** Cheffl Android
- [ ] **Package name:** `com.cheffl.app`
- [ ] **Service credentials:** upload het JSON-bestand van Stap B5

---

## Stap C4 – API Keys noteren

- [ ] **Project** → **API Keys**
- [ ] Er zijn aparte keys voor **Apple** en **Google**
- [ ] Noteer:
  - **Public API Key (Apple):** begint met `appl_`
  - **Public API Key (Google):** begint met `goog_`

Deze gebruik je in de Flutter-app.

---

## Stap C5 – Entitlements

Entitlements bepalen wat een gebruiker krijgt na aankoop.

- [ ] **Project** → **Entitlements** → **+ New**
- [ ] Maak `credits` aan (voor credit packs)
- [ ] Maak optioneel `pro` aan (voor subscription)

---

## Stap C6 – Products koppelen

- [ ] **Project** → **Products** → **+ New**
- [ ] Voor elk product:

| Entitlement | Identifier   | App Store Product ID  | Google Product ID   |
|-------------|--------------|------------------------|----------------------|
| credits     | credits_5    | cheffl_credits_5       | cheffl_credits_5     |
| credits     | credits_15   | cheffl_credits_15      | cheffl_credits_15    |
| credits     | credits_50   | cheffl_credits_50      | cheffl_credits_50    |
| pro         | pro_monthly  | cheffl_pro_monthly     | cheffl_pro_monthly   |
| pro         | pro_yearly   | cheffl_pro_yearly      | cheffl_pro_yearly    |

- [ ] Sla elk product op

---

## Stap C7 – Offering maken

Offerings groeperen producten voor je paywall.

- [ ] **Project** → **Offerings** → **Current** (default) of maak een nieuwe
- [ ] **+ Add package**
- [ ] **Identifier:** bijv. `$credits_5` (voor 5 credits pack)
- [ ] **Package type:** Custom
- [ ] **Product:** kies `credits_5`
- [ ] Herhaal voor `$credits_15`, `$credits_50`, en eventueel subscription packages

---

## Stap C8 – Webhook configureren (na Edge Function)

- [ ] **Project** → **Integrations** → **Webhooks** → **+ New**
- [ ] **URL:** `https://<jouw-project>.supabase.co/functions/v1/revenuecat-webhook`
- [ ] **Authorization header:** kies een geheim (bijv. random string) en noteer deze
- [ ] **Events:** vink aan: `INITIAL_PURCHASE`, `NON_RENEWING_PURCHASE`, `RENEWAL` (voor subscriptions)
- [ ] **Environment:** Sandbox en/of Production
- [ ] Sla op

---

# DEEL D: Flutter Code

## Stap D1 – Dependencies

```yaml
# pubspec.yaml
dependencies:
  purchases_flutter: ^8.0.0
```

- [ ] Voeg toe en run `flutter pub get`

---

## Stap D2 – iOS Podfile

- [ ] `ios/Podfile` openen
- [ ] Controleer: `platform :ios, '11.0'` (of hoger)

---

## Stap D3 – Android launchMode

- [ ] `android/app/src/main/AndroidManifest.xml`
- [ ] Zorg dat de MainActivity `launchMode="standard"` of `singleTop` heeft (voor Google Pay verificatie)

---

## Stap D4 – RevenueCat initialisatie

Initialiseer na Supabase, met de juiste API key per platform:

```dart
// In main.dart of een init-service
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

Future<void> _initRevenueCat() async {
  const iosKey = 'appl_XXXXXXXX';  // Vervang met jouw Apple key
  const androidKey = 'goog_XXXXXXXX';  // Vervang met jouw Google key
  
  if (Platform.isIOS) {
    await Purchases.configure(PurchasesConfiguration(iosKey));
  } else if (Platform.isAndroid) {
    await Purchases.configure(PurchasesConfiguration(androidKey));
  }
  
  // Na Supabase login: link RevenueCat aan user
  final user = SupabaseService.getCurrentUser();
  if (user != null) {
    await Purchases.logIn(user.id);
  }
}
```

- [ ] Roep `_initRevenueCat()` aan na `SupabaseService.initialize()`
- [ ] Na elke succesvolle login: `Purchases.logIn(userId)`

---

## Stap D5 – Paywall screen

- [ ] Maak een `PaywallScreen` die:
  - `Purchases.getOfferings()` aanroept
  - De packages toont (credits_5, credits_15, credits_50)
  - Bij tap: `Purchases.purchasePackage(package)` aanroept
  - Bij succes: navigeert terug en refreshed credits (webhook zal ze toevoegen)
  - **Restore purchases** button: `Purchases.restorePurchases()`

---

## Stap D6 – Geen credits → Paywall

- [ ] In `GenerateScreenSimple`: als `!canGen`, navigeer naar de Paywall in plaats van alleen een Snackbar
- [ ] In Profile: "Buy credits" button die naar Paywall navigeert

---

# DEEL E: Webhook Edge Function

## Stap E1 – Edge Function aanmaken

- [ ] Maak `supabase/functions/revenuecat-webhook/index.ts`
- [ ] Parse het webhook body (event type, `app_user_id`, product identifier)
- [ ] Mapping: product ID → aantal credits (5, 15, 50, of voor subscription: 20/240)
- [ ] Controleer Authorization header
- [ ] Roep `add_credits_to_user` RPC aan met Supabase service role client
- [ ] Return 200 direct; verwerk asynchroon als nodig
- [ ] Idempotency: check of `event_id` al verwerkt is (bijv. in `webhook_events` tabel)

---

## Stap E2 – Deploy

```bash
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

- [ ] Stel de RevenueCat Authorization header in op dezelfde waarde als in je function

---

# DEEL F: Testen

## Stap F1 – Sandbox-accounts

**Apple:**
- [ ] App Store Connect → **Users and Access** → **Sandbox** → **Testers**
- [ ] Maak een sandbox Apple ID aan
- [ ] Op je testdevice: **Instellingen** → **App Store** → onderaan uitloggen, dan met sandbox-account inloggen

**Google:**
- [ ] Play Console → **Setup** → **License testing**
- [ ] Voeg je test-Gmail toe

---

## Stap F2 – Testen in de app

- [ ] Run de app op een **echt device** (geen simulator voor Apple IAP)
- [ ] Log in met een testaccount
- [ ] Ga naar de paywall
- [ ] Koop een credit pack (sandbox, geen echte kosten)
- [ ] Controleer in RevenueCat dashboard of de purchase verschijnt
- [ ] Controleer of credits in de app toenemen (via webhook)

---

# DEEL G: Store compliance

## Verplicht voor Apple

- [ ] **Restore purchases** – Apple vereist een restore-knop; RevenueCat: `Purchases.restorePurchases()`
- [ ] **Privacy Policy** – link in App Store listing en in de app
- [ ] **Terms of Use** – aanbevolen voor in-app purchases
- [ ] **Subscription info** – bij subscriptions: duur, prijs, annuleren

## Verplicht voor Google

- [ ] **Restore purchases** –zelfde als Apple
- [ ] **Refund policy** – link in Play Console
- [ ] **Subscription** – duidelijke informatie over hernieuwing en annulering

---

## Checklist voor publicatie

- [ ] Alle producten status "Ready to Submit" (Apple)
- [ ] Alle producten Active (Google)
- [ ] Paywall toont prijzen correct
- [ ] Restore purchases werkt
- [ ] Webhook geeft credits na aankoop
- [ ] Geen credits meer → duidelijke prompt naar paywall
- [ ] Privacy policy URL beschikbaar

---

## Volgende stappen

Zodra je bij een bepaalde stap bent, kun je de bijbehorende code en configuratie uitwerken. Begin bij Deel A als je nog geen Apple/Google setup hebt.
