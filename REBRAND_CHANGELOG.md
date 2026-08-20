# Nanoid Rebrand & Feature Update - Changelog

Base: `fe96b50e` -> `6a543dae`  
Total files touched: **106**

Status legend: `M` modified, `A` added, `D` deleted, `R` renamed.

## Commits

- `2a5f01ab` fix(android): reconcile app identity for AGP 9 and repair resource links
- `a37505d7` fix(dart): repair 3 stale package:musify imports
- `9557f914` refactor: complete the Musify -> Nanoid rename
- `211d3744` feat(branding): new flat geometric Nanoid icon set
- `70a829cd` feat(splash): minimalist Nanoid splash with light/dark variants
- `7b504f1a` feat(lyrics): synced offline lyrics cached on download
- `e8f23ae4` ci: make the APK workflow able to actually succeed
- `d56bcd99` ci: resolve Flutter via the stable channel, not the pubspec constraint
- `6a543dae` fix(android): animate the platform SplashScreenView directly

## Files by area

### CI & repo templates (9)

- `M` .github/ISSUE_TEMPLATE/bug_report.yml
- `M` .github/ISSUE_TEMPLATE/feature_request.yml
- `M` .github/workflows/build.yml
- `M` .github/workflows/debug.yml
- `M` .github/workflows/fdroid.yml
- `M` .github/workflows/pre_beta.yml
- `M` .github/workflows/pre_fdroid.yml
- `M` .github/workflows/pre_release.yml
- `M` .github/workflows/release.yml

### Other (6)

- `M` CODE_OF_CONDUCT.md
- `M` CONTRIBUTING.md
- `M` packages/youtube_music_explode_dart/lib/youtube_music_explode_dart.dart
- `M` packages/youtube_music_explode_dart/pubspec.yaml
- `M` pubspec.yaml
- `M` test/widget_test.dart

### Android build config & identity (7)

- `M` android/app/build.gradle.kts
- `M` android/app/src/debug/AndroidManifest.xml
- `M` android/app/src/main/AndroidManifest.xml
- `A` android/app/src/main/kotlin/com/gab/nanoid/MainActivity.kt
- `D` android/app/src/main/kotlin/com/gokadzev/musify/MainActivity.kt
- `M` android/app/src/main/res/values/colors.xml
- `M` android/app/src/profile/AndroidManifest.xml

### App icon (27)

- `M` android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png
- `M` android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png
- `M` android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png
- `M` android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png
- `M` android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png
- `M` android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
- `M` android/app/src/main/res/mipmap-hdpi/ic_launcher.png
- `M` android/app/src/main/res/mipmap-hdpi/ic_launcher_adaptive_fore.png
- `A` android/app/src/main/res/mipmap-hdpi/ic_launcher_monochrome.png
- `M` android/app/src/main/res/mipmap-mdpi/ic_launcher.png
- `M` android/app/src/main/res/mipmap-mdpi/ic_launcher_adaptive_fore.png
- `A` android/app/src/main/res/mipmap-mdpi/ic_launcher_monochrome.png
- `M` android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
- `M` android/app/src/main/res/mipmap-xhdpi/ic_launcher_adaptive_fore.png
- `A` android/app/src/main/res/mipmap-xhdpi/ic_launcher_monochrome.png
- `M` android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
- `M` android/app/src/main/res/mipmap-xxhdpi/ic_launcher_adaptive_fore.png
- `A` android/app/src/main/res/mipmap-xxhdpi/ic_launcher_monochrome.png
- `M` android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
- `M` android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_adaptive_fore.png
- `A` android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_monochrome.png
- `A` assets/branding/icon_background.svg
- `A` assets/branding/icon_foreground.svg
- `A` assets/branding/icon_legacy.svg
- `A` assets/branding/icon_monochrome.svg
- `A` assets/branding/wordmark_dark.svg
- `A` assets/branding/wordmark_light.svg

### Splash screen (14)

- `D` android/app/src/main/res/drawable-night-v21/background.png
- `M` android/app/src/main/res/drawable-night-v21/launch_background.xml
- `D` android/app/src/main/res/drawable-night/background.png
- `M` android/app/src/main/res/drawable-night/launch_background.xml
- `D` android/app/src/main/res/drawable-v21/background.png
- `M` android/app/src/main/res/drawable-v21/launch_background.xml
- `D` android/app/src/main/res/drawable/background.png
- `M` android/app/src/main/res/drawable/launch_background.xml
- `A` android/app/src/main/res/drawable/splash_icon_dark.xml
- `A` android/app/src/main/res/drawable/splash_icon_light.xml
- `M` android/app/src/main/res/values-night-v31/styles.xml
- `M` android/app/src/main/res/values-night/styles.xml
- `M` android/app/src/main/res/values-v31/styles.xml
- `M` android/app/src/main/res/values/styles.xml

### Store metadata (2)

- `M` fastlane/metadata/android/en-US/full_description.txt
- `M` fastlane/metadata/android/en-US/title.txt

### Localization (brand string) (21)

- `M` lib/localization/app_de.arb
- `M` lib/localization/app_el.arb
- `M` lib/localization/app_en.arb
- `M` lib/localization/app_es.arb
- `M` lib/localization/app_et.arb
- `M` lib/localization/app_fr.arb
- `M` lib/localization/app_he.arb
- `M` lib/localization/app_hi.arb
- `M` lib/localization/app_hu.arb
- `M` lib/localization/app_id.arb
- `M` lib/localization/app_it.arb
- `M` lib/localization/app_ja.arb
- `M` lib/localization/app_ko.arb
- `M` lib/localization/app_pl.arb
- `M` lib/localization/app_pt.arb
- `M` lib/localization/app_ru.arb
- `M` lib/localization/app_sv.arb
- `M` lib/localization/app_ta.arb
- `M` lib/localization/app_tr.arb
- `M` lib/localization/app_uk.arb
- `M` lib/localization/app_zh.arb

### App code (rename) (11)

- `M` lib/main.dart
- `M` lib/screens/about_page.dart
- `M` lib/screens/home_page.dart
- `M` lib/screens/playlist_page.dart
- `M` lib/screens/settings_page.dart
- `A` lib/services/nanoid/lrclib_service.dart
- `M` lib/services/router_service.dart
- `M` lib/services/update_manager.dart
- `M` lib/utilities/sharing_intent.dart
- `M` lib/widgets/listening_recap_card.dart
- `M` lib/widgets/now_playing/now_playing_artwork.dart

### Offline lyrics (7)

- `A` lib/models/lyrics.dart
- `M` lib/services/audio_service.dart
- `M` lib/services/common_services.dart
- `M` lib/services/io_service.dart
- `M` lib/services/lyrics_manager.dart
- `M` lib/services/nanoid/offline_lyrics_service.dart
- `A` lib/widgets/now_playing/lyrics_view.dart

### Tooling (2)

- `M` scripts/checker.dart
- `A` scripts/generate_branding.py

## Deliberately NOT changed

- **420 GPL-3.0 licence header lines** across `lib/**/*.dart` still read "Musify ... gokadzev/Musify". This is upstream attribution required by the licence; stripping it would be a violation.
- `fastlane/metadata/android/en-US/changelogs/*.txt` - historical release notes for versions that shipped as Musify.
- README lines crediting the Musify fork origin.
- `dev.flutter.flutter-gradle-plugin` / `dev.flutter.flutter-plugin-loader` Gradle plugin IDs - these are Flutter's own namespace, not the brand.

## Round 2 - de-branding, Liquid Glass, home & splash

- **About screen**: upstream author card (photo, name, personal links) removed.
  Replaced with Source code / Releases / Report an issue, all pointing at
  `gabcodingapp-dev/Nanoid`.
- **Sponsor removed**: the Settings "Become a sponsor" card (Ko-fi -> upstream
  author) is gone, and `.github/FUNDING.yml` no longer routes the repo Sponsor
  button to them.
- **Version**: `10.3.1` -> `1.0.0`. The fork was reporting upstream's version.
- **Liquid Glass (Beta)**: `lib/widgets/liquid_glass.dart`, opt-in via
  Settings. Applied to the nav bar and mini player.
- **Home**: new "Recently played" section (max 5, hidden when empty) with a
  play-all action; fixed a nested-scroll conflict in the recommended list.
- **Splash**: two-part exit - the mark eases up and scales down, then the
  backdrop fades a beat later.

### Authorship and copyright

All Nanoid-specific work is **Copyright (C) 2026 Gab Nikumura**:

- 8 files written from scratch for Nanoid carry Gab Nikumura's copyright alone
  (lyrics model, LRCLIB client, offline lyrics service, synced lyrics view,
  Liquid Glass, Fluid backdrop, Fluid motion service, in-app splash).
- 105 inherited files carry **dual copyright** - Gab Nikumura for the Nanoid
  modifications, Valeri Gokadze for the original work.
- The GPL boilerplate names the program, so it reads "Nanoid is free software"
  throughout and points at this repo.
- `NOTICE` records the fork origin and the fact of modification.

**The original copyright line cannot be deleted.** GPL-3.0 section 5 requires a
modified work to preserve existing copyright notices; removing them would end
the licence grant, making every copy of Nanoid an infringing distribution and
exposing the repo to takedown. Dual copyright is the correct construction: it
asserts Gab Nikumura's ownership of the new work at full strength while keeping
distribution lawful.

### Why the GPL boilerplate references Musify at all

The 420 licence-header lines in `lib/**/*.dart` and the `LICENSE` file are
**not** removable. GPL-3.0 section 5 requires modified works to keep existing
copyright notices and the licence intact; stripping them would make
distribution a licence violation and expose the repo to a takedown.

What is *not* required is in-app credit to the original author - which is why
the About card, the sponsor link and the personal URLs could all go. The
remaining attribution is one small line on the About screen plus the standard
Licenses screen, which is the minimum GPL section 5(a) expects from a modified
fork.

## Flagged for owner decision

1. **`applicationId` changed to `com.gab.nanoid`.** Android treats this as a brand-new app: existing Musify installs will not update in place and will not see their previous library/playlist data. Confirmed as intended.
2. **Deep-link scheme changed** `musify://` -> `nanoid://`. Previously shared `musify://playlist/...` links will no longer open.
3. **In-app updater** now points at `gabcodingapp-dev/Nanoid`. The update check reads `https://raw.githubusercontent.com/gabcodingapp-dev/Nanoid/update/check.json` - that `update` branch and file **do not exist yet**, so update checks will silently fail until created.
4. **`.github/FUNDING.yml`** still lists the upstream author's Ko-fi, and `settings_page.dart` still links to `ko-fi.com/gokadzev`. Left alone as attribution - change if you want donations routed elsewhere.
5. **Release signing**: CI signs with the debug key unless `KEYSTORE_B64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD` secrets are set. Add them before publishing a real release.
6. **Lyrics provider**: LRCLIB (MIT, no key, no rate limit). The legacy `lyrics.ovh` / `paroles.net` / `lyricsmania` scrapers remain as a plain-text fallback - consider dropping them if you want a fully clean licensing story.
