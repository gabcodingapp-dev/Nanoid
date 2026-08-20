#!/usr/bin/env python3
"""
Nanoid brand mark generator.

Design rationale (deliberately avoiding "AI-generated" tells):
  * Pure geometry - one circle, one straight stem, one hook curve, one dot.
  * Flat fills only. No gradients, no bevels, no drop shadows, no textures.
  * Exactly three brand colours (ink / mark / accent).
  * The mark is a single-storey lowercase "g" whose bowl doubles as a vinyl
    record: the ring is the disc, the accent dot is the spindle. Monogram for
    "gab" + a music cue, in one shape.

Geometry lives in a 108x108 viewBox (Android adaptive icon unit). All artwork
stays inside the 66dp centre safe zone so no launcher mask can clip it.

Run:  python3 scripts/generate_branding.py      (requires cairosvg)
"""
import os

import cairosvg

INK = "#0B0B0F"      # near-black, violet-leaning
MARK = "#FFFFFF"     # the letterform
ACCENT = "#8B5CF6"   # Violet Radiant spindle

# --- glyph geometry -------------------------------------------------------
CX, CY, R, W = 54, 42, 15, 8.5      # bowl centre, radius, stroke weight
STEM_X = CX + R                     # stem is tangent to the bowl
STEM_TOP, STEM_BOT = CY, 70
SPINDLE_R = 4.2


def glyph(mark_color, accent_color):
    """The 'g' mark as an SVG fragment in the 108 unit space."""
    return f'''
  <g fill="none" stroke="{mark_color}" stroke-width="{W}" stroke-linecap="round">
    <circle cx="{CX}" cy="{CY}" r="{R}"/>
    <path d="M{STEM_X},{STEM_TOP} L{STEM_X},{STEM_BOT}"/>
    <path d="M{STEM_X},{STEM_BOT} C{STEM_X},79 61,82 50,78.5"/>
  </g>
  <circle cx="{CX}" cy="{CY}" r="{SPINDLE_R}" fill="{accent_color}"/>'''


def svg_doc(body, size=108, bg=None):
    back = f'<rect width="108" height="108" fill="{bg}"/>' if bg else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" '
            f'height="{size}" viewBox="0 0 108 108">{back}{body}\n</svg>')


# 1. adaptive foreground - transparent, mark only
FOREGROUND = svg_doc(glyph(MARK, ACCENT))

# 2. adaptive background - flat brand ink
BACKGROUND = svg_doc("", bg=INK)

# 3. monochrome (themed icons + notification tray): one flat colour, no accent
MONOCHROME = svg_doc(glyph(MARK, MARK))

# 4. legacy square launcher icon: rounded-rect plate + mark scaled up, since
#    pre-API-26 launchers apply no mask and therefore no 25% crop.
_LEGACY_SCALE = 1.22
LEGACY = svg_doc(
    f'<rect x="0" y="0" width="108" height="108" rx="24" ry="24" fill="{INK}"/>'
    f'<g transform="translate(54,54) scale({_LEGACY_SCALE}) translate(-54,-54)">'
    f'{glyph(MARK, ACCENT)}</g>'
)


def wordmark(mark_color, accent_color):
    """Lockup used for docs and store assets."""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="420" height="128" '
            f'viewBox="0 0 420 128">'
            f'<g transform="translate(-6,10)">{glyph(mark_color, accent_color)}</g>'
            f'<text x="118" y="82" font-family="Helvetica,Arial,sans-serif" '
            f'font-size="62" font-weight="600" letter-spacing="-2" '
            f'fill="{mark_color}">nanoid</text></svg>')


OUT = "assets/branding"
RES = "android/app/src/main/res"

# Android density buckets
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
LAUNCHER = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
NOTIFICATION = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}


def render(svg, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    cairosvg.svg2png(bytestring=svg.encode(), write_to=path,
                     output_width=px, output_height=px)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, data in [("icon_foreground", FOREGROUND),
                       ("icon_background", BACKGROUND),
                       ("icon_monochrome", MONOCHROME),
                       ("icon_legacy", LEGACY)]:
        with open(f"{OUT}/{name}.svg", "w") as fh:
            fh.write(data)
    with open(f"{OUT}/wordmark_dark.svg", "w") as fh:
        fh.write(wordmark("#FFFFFF", ACCENT))
    with open(f"{OUT}/wordmark_light.svg", "w") as fh:
        fh.write(wordmark(INK, ACCENT))

    for density, px in ADAPTIVE.items():
        render(FOREGROUND, f"{RES}/mipmap-{density}/ic_launcher_adaptive_fore.png", px)
        render(MONOCHROME, f"{RES}/mipmap-{density}/ic_launcher_monochrome.png", px)
    for density, px in LAUNCHER.items():
        render(LEGACY, f"{RES}/mipmap-{density}/ic_launcher.png", px)
    # Notification small icon: white silhouette on transparent; Android tints it.
    for density, px in NOTIFICATION.items():
        render(MONOCHROME, f"{RES}/drawable-{density}/ic_launcher_foreground.png", px)

    print("branding assets regenerated")


if __name__ == "__main__":
    main()
