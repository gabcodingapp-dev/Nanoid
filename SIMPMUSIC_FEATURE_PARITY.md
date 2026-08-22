# SimpMusic feature-parity plan

Reference: [maxrave-dev/SimpMusic](https://github.com/maxrave-dev/SimpMusic) (`dev` branch inspected for Nanoid 1.1).

Nanoid remains a Flutter app with package ID `com.gab.nanoid`; SimpMusic is a Compose Multiplatform app. Features are therefore ported deliberately into Nanoid rather than replacing the app or copying its project structure.

## Nanoid 1.1 — implemented and built

- [x] Keep the existing Nanoid app/package and user-data model
- [x] Moods and genres discovery shortcuts
- [x] Global and Philippines chart discovery
- [x] Music-podcast, live-performance and new-release discovery
- [x] Return YouTube Dislike community estimates (read-only, cached, opt-out)
- [x] YouTube transcript fallback after dedicated lyrics providers fail
- [x] Granular SponsorBlock categories
- [x] Category-aware SponsorBlock offline cache invalidation
- [x] Liquid Glass v2 with directional rim, refraction sweep and touch glow
- [x] Glass treatment on Now Playing actions
- [x] In-app SimpMusic and community-service attribution
- [x] Version bump to `1.1.0+2` without changing `com.gab.nanoid`
- [x] Build-memory fix for 2–4 GB builders

## Already present in Nanoid

- [x] Ad-free background audio from YouTube
- [x] Search for songs, artists, albums and playlists
- [x] Offline downloads and playback
- [x] Offline artwork and synced lyrics
- [x] LRCLIB plus plain-text lyrics fallbacks
- [x] Synced lyrics, tap-to-seek and timing adjustment
- [x] SponsorBlock playback
- [x] Sleep timer with optional fade-out
- [x] Equalizer, presets, playback speed, pitch and volume boost
- [x] Audio quality selection and quality badge
- [x] Queue restore, repeat, smart shuffle and A–B looping
- [x] Dynamic/light/dark/pure-black themes
- [x] Fluid motion/rhythm theme
- [x] Listening history, analytics and monthly recap
- [x] Recommendations and radio stations
- [x] Local/custom playlists, sharing, backup and restore
- [x] Spotify playlist CSV import
- [x] ListenBrainz scrobbling

## Nanoid 1.2 — implemented and built

- [x] Spotify-inspired, artwork-first Home layout
- [x] Quick-access grid for liked songs, downloads, recent tracks and playlists
- [x] All, Music, Podcasts and Live Home filters
- [x] Endless discovery shelves loaded near the bottom of the page
- [x] Pull-to-refresh and retry states
- [x] Rotating Philippines, OPM, genre, mood, podcast and live-performance lanes
- [x] Search-backed discovery caching and duplicate control
- [x] One-tap shelf playback and full-search actions

## Follow-up milestones

These are not falsely labelled as complete because each needs a real platform integration, account flow, or player-engine change.

### Catalog and identity

- [ ] Native YouTube Music Home/Charts/Moods browse shelves (not search-backed shelves)
- [ ] YouTube Music login, library sync and multiple accounts
- [ ] Full podcast subscriptions, episode progress and offline episode library
- [ ] Followed-artist release notifications
- [ ] YouTube like/dislike submission when signed in

### 1.3 — richer playback

- [ ] Dual-player crossfade and optional DJ transition mode
- [ ] 1080p video mode with subtitle selection
- [ ] Spotify Canvas with an explicit Spotify login/consent flow
- [ ] Last.fm option alongside ListenBrainz
- [ ] Android Auto online browse tree

### 1.4 — connected and AI features

- [ ] User-supplied Gemini/OpenAI keys for AI suggestions and lyric translation
- [ ] Discord Rich Presence with opt-in privacy controls
- [ ] Optional cast support

## Attribution and licensing

Both projects are GPL-3.0. Nanoid's in-app About screen, README and NOTICE credit SimpMusic as feature inspiration. Nanoid is not affiliated with or endorsed by SimpMusic. Community APIs are credited individually and can be disabled in Settings.
