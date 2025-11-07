# Pokémon Green Cards (Flutter)

A simple mobile app for **Lab 4 – Populate data from Pokémon API**.

- Loads **Grass-type ("green")** Pokémon TCG cards via **Pokémon TCG API**.
- Shows **name + image** in a **ListView**.
- **Tap** a card to open a **full-screen enlarged** image.
- Optional: **Save/Remove** cards to a local **database (Hive)** and view saved cards.

## Quick Start (Windows CMD)
```bat
cd PokemonGreenCardsApp
setup_project.cmd
```
This will:
- Run `flutter create .` to generate platform folders (android/ios/web/macos/windows/linux)
- Run `flutter pub get`
- Launch the app with `flutter run`

If you prefer manual commands:
```bat
cd PokemonGreenCardsApp
flutter create .
flutter pub get
flutter run
```

## Files
- `lib/main.dart` – App UI, list + details pages, saved toggle
- `lib/models/pokemon_card.dart` – Data model
- `lib/services/tcg_api.dart` – API client (HTTP fetch)
- `lib/widgets/card_tile.dart` – List tile widget
- `pubspec.yaml` – Dependencies (http, cached_network_image, hive, hive_flutter, path_provider)

## Notes
- API: https://api.pokemontcg.io/v2/cards?q=types:grass&pageSize=50
- No API key required for basic usage.
- Database folder is created automatically using Hive.