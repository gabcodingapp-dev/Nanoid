# Changelog

## 1.2.0 — Endless Home

### Added

- A completely redesigned, Spotify-inspired Home interface with a time-aware greeting, pinned search/settings controls, compact quick-access grid and colored Explore cards.
- Persistent Home filters for All, Music, Podcasts and Live discovery lanes during the current session.
- An endless discovery feed that loads two fresh shelves near the bottom instead of ending after one recommended list.
- Rotating discovery lanes for Philippine charts, OPM, new releases, viral hits, mood, focus, workout, genres, podcasts, concerts and live radio.
- Pull-to-refresh for recommendations, playlists and discovery shelves.
- One-tap play-all and full-search actions on every generated shelf.
- Search-result caching so endless discovery does not repeatedly request the same catalogue lanes.
- Responsive two- or four-column shortcut grids for liked songs, downloads, recent tracks and favorite playlists.

### Improved

- Recommendations are now artwork-led horizontal shelves instead of a long terminal text list.
- Playlist cards now include readable titles and responsive spacing.
- Home loading is incremental and bounded to two network searches per page.
- Empty discovery queries advance to a different lane instead of trapping the feed on a failed request.

### Compatibility

- Package ID remains `com.gab.nanoid`.
- Version is `1.2.0+3`.

## 1.1.0 — SimpMusic-inspired feature pack

### Added

- Moods, genres, charts, OPM, podcasts, live-performance and new-release discovery shortcuts.
- Read-only Return YouTube Dislike community estimates in Now Playing, with six-hour caching and an opt-out setting.
- Labelled YouTube transcript fallback when LRCLIB and the existing lyrics providers return no result.
- SponsorBlock category picker for sponsors, intros, outros, self-promotion, interaction reminders, previews, off-topic sections and filler.
- Category signatures for downloaded SponsorBlock data, so changing categories invalidates stale offline segment caches.
- SimpMusic, Return YouTube Dislike and SponsorBlock credits in the app, README and NOTICE.

### Improved

- Liquid Glass v2 now has a directional rim, internal refraction sweep, pointer-following glow and a subtle press response.
- Now Playing actions use Liquid Glass when the effect is enabled.
- Gradle memory settings now work on common 2–4 GB builders instead of requesting an 8 GB heap.
- The placeholder counter test was replaced with model and synced-lyrics tests.

### Compatibility

- Package ID remains `com.gab.nanoid`.
- Version is `1.1.0+2`, allowing an in-place upgrade from `1.0.0+1` when signed with the same release key.
