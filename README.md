<div align="center">

  <img src="assets/icons/nanoid_icon.png" width="120" height="120" style="border-radius: 24px;" onerror="this.style.display='none'">

  # Nanoid

  ### Minimalist Music — by **Gab Nikumura**

  **Offline Lyrics • Minimal Splash • Clean Design • `com.gab.nanoid`**

  <p>
    <a href="https://github.com/gabcodingapp-dev/Nanoid/releases/latest"><img src="https://img.shields.io/github/v/release/gabcodingapp-dev/Nanoid?label=Release&color=111111&style=for-the-badge"></a>
    <a href="https://github.com/gabcodingapp-dev/Nanoid/releases"><img src="https://img.shields.io/github/downloads/gabcodingapp-dev/Nanoid/total?color=000000&style=for-the-badge&label=Downloads"></a>
    <a href="https://github.com/gabcodingapp-dev/Nanoid/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/gabcodingapp-dev/Nanoid/build.yml?label=Build&color=333&style=for-the-badge"></a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.47-02569B?style=flat-square&logo=flutter&logoColor=white">
    <img src="https://img.shields.io/badge/Package-com.gab.nanoid-000?style=flat-square">
    <img src="https://img.shields.io/badge/License-GPL--3.0-00C853?style=flat-square">
    <img src="https://img.shields.io/badge/By-Gab-FF4081?style=flat-square">
  </p>

</div>

---

> [!TIP]
> **Nanoid by Gab — minimalist, faster, with offline synced lyrics.**

---

## ✨ What's New in Nanoid

| **Before** | **Nanoid by Gab Nikumura** |
|---|---|
| Lyrics only online | **Offline Lyrics** — auto-fetched on download, read without internet |
| Heavy splash | **Minimalist Splash** — black, centered logo, 400ms |
| Generic design | **Minimalist UI** — black/white, less clutter, faster |

---

## 🎵 Features

- **Stream + Download** — with offline lyrics (new!)
- **Offline Lyrics** — when you download a song, lyrics are fetched via `LyricsManager` and cached in Hive (`offline_lyrics` box) → read offline in `Now Playing`
- **Minimalist Splash** — pure black `launch_background`, centered `ic_launcher`
- **Better Features:**
  - **Smart Cache** — lyrics cached per `artist::title` key
  - **Live Progress** — download progress with lyrics fetch indicator
  - **Clean Player** — no ads, no bloat
- **Nanoid 1.2 Endless Home:**
  - **Spotify-inspired interface** — greeting, quick access, artwork-first shelves and Explore cards
  - **Never-ending discovery** — new music, podcast and live shelves load as you scroll
  - **Home filters** — switch between All, Music, Podcasts and Live
  - **Philippines + OPM discovery** — local charts and rotating Filipino music lanes
  - **Pull to refresh** — rebuild recommendations, playlists and discovery in one gesture
- **Nanoid 1.1 feature pack:**
  - **Community Ratings** — read-only estimates from Return YouTube Dislike
  - **Multi-source Lyrics** — LRCLIB and legacy sources, then a labelled YouTube transcript fallback
  - **Granular SponsorBlock** — choose sponsors, intros, outros, self-promotion, filler and more
  - **Liquid Glass v2** — directional rim lighting and touch-responsive specular glow

See the honest [SimpMusic feature-parity plan](SIMPMUSIC_FEATURE_PARITY.md) for
what is already present, what landed, and the remaining platform work.

---

## 📊 GitHub Widgets

<p align="center">
  <a href="https://github.com/gabcodingapp-dev/Nanoid"><img src="https://github-readme-stats.vercel.app/api/pin/?username=gabcodingapp-dev&repo=Nanoid&theme=dark&hide_border=true" width="400"></a>
  <img src="https://img.shields.io/github/last-commit/gabcodingapp-dev/Nanoid?color=111&style=flat-square&label=Last%20Commit">
  <img src="https://img.shields.io/github/issues/gabcodingapp-dev/Nanoid?color=FF4081&style=flat-square">
</p>

---

## ⬇️ Download

- **Release APK:** [Latest Release](https://github.com/gabcodingapp-dev/Nanoid/releases/latest)
- **CI Build:** `Actions` → `Artifacts` → `Nanoid-debug`

---

## 🛠️ Build

```bash
git clone https://github.com/gabcodingapp-dev/Nanoid.git
cd Nanoid
flutter pub get
flutter build apk --release
```

---

## 👤 Credits

| Role | Name |
|---|---|
| **Developer** | **Gab Nikumura** (`gabcodingapp-dev`) |
| **Package** | `com.gab.nanoid` |
| **Licence** | GPL-3.0 — see LICENSE and NOTICE |
| **Feature inspiration** | [SimpMusic](https://github.com/maxrave-dev/SimpMusic) by maxrave-dev and contributors |
| **Community ratings** | [Return YouTube Dislike](https://returnyoutubedislike.com/) |
| **Skip segments** | [SponsorBlock](https://sponsor.ajay.app/) |

Nanoid is not affiliated with or endorsed by SimpMusic. The Nanoid 1.1 Flutter
implementations are maintained in this repository; see `NOTICE` for attribution.

---

## 📄 License

GPL-3.0 © 2026 Gab Nikumura — keep source open.

---

<div align="center">

**Made with 🖤 by Gab Nikumura**

</div>
