#!/usr/bin/env python3
"""Vector sources for the 苔根小径 monsters (action test level).

Each creature is split into parts (body, eye, wing, cap ...) so the game can animate them with
transforms. Style follows the approved 小呆猪 frames: chibi shapes, soft top-left light, gradient
shading, a thin dark tinted outline, glossy eyes and blush. Every monster carries a small violet
mark of the wizard's curse (eye glints, spine tips, glowing spots, a crystal).

Run:  python3 tools/monster_art/make_svgs.py
Then: Godot --headless --path . --script tools/render_monster_art.gd   (SVG -> PNG in assets/)
Standard library only. One SVG pixel becomes one texture pixel; the game draws at 0.42 scale.
"""
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg")

CURSE = "#b27cff"
CURSE_LIGHT = "#ecd4ff"
CURSE_DEEP = "#5b2a8c"


def svg(w, h, defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
            f'<defs>\n{defs}\n</defs>\n{body}\n</svg>\n')


def radial(gid, stops, cx=0.4, cy=0.35, r=0.75):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<radialGradient id="{gid}" cx="{cx}" cy="{cy}" r="{r}">{s}</radialGradient>'


def linear(gid, stops, x1=0, y1=0, x2=0, y2=1):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops)
    return f'<linearGradient id="{gid}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def pts(points):
    return " ".join(f"{x:.1f},{y:.1f}" for x, y in points)


def glossy_eye(cx, cy, rx, ry, iris="#1b1612", glint=True, outline=None):
    """Big glossy chibi eye with two highlights and an optional violet curse glint."""
    out = f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{iris}"'
    out += f' stroke="{outline}" stroke-width="1.5"/>' if outline else '/>'
    if glint:
        out += (f'<path d="M {cx - rx * 0.75:.1f},{cy + ry * 0.35:.1f} Q {cx:.1f},{cy + ry * 1.05:.1f} '
                f'{cx + rx * 0.75:.1f},{cy + ry * 0.35:.1f}" fill="none" stroke="{CURSE}" '
                f'stroke-width="{max(1.2, rx * 0.28):.1f}" stroke-linecap="round" opacity="0.85"/>')
    out += f'<circle cx="{cx - rx * 0.3:.1f}" cy="{cy - ry * 0.38:.1f}" r="{rx * 0.42:.1f}" fill="#ffffff"/>'
    out += f'<circle cx="{cx + rx * 0.3:.1f}" cy="{cy + ry * 0.25:.1f}" r="{rx * 0.18:.1f}" fill="#ffffff" opacity="0.8"/>'
    return out


def sprout(x, y, outline, scale=1.0, lean=0.0):
    """Two-leaf sprout rooted at (x, y)."""
    s = scale
    tx, ty = x + lean * s, y - 16 * s
    return (f'<path d="M {x},{y} Q {x + 1 * s},{y - 9 * s} {tx},{ty}" fill="none" stroke="{outline}" stroke-width="{4.6 * s:.1f}" stroke-linecap="round"/>'
            f'<path d="M {x},{y} Q {x + 1 * s},{y - 9 * s} {tx},{ty}" fill="none" stroke="#6f9a3c" stroke-width="{2.4 * s:.1f}" stroke-linecap="round"/>'
            f'<path d="M {tx},{ty} C {tx - 6 * s},{ty - 10 * s} {tx - 18 * s},{ty - 8 * s} {tx - 20 * s},{ty - 1 * s} C {tx - 14 * s},{ty + 4 * s} {tx - 5 * s},{ty + 3 * s} {tx},{ty} Z" fill="#a9dc6e" stroke="{outline}" stroke-width="{2 * s:.1f}" stroke-linejoin="round"/>'
            f'<path d="M {tx},{ty} C {tx + 5 * s},{ty - 12 * s} {tx + 17 * s},{ty - 13 * s} {tx + 21 * s},{ty - 6 * s} C {tx + 15 * s},{ty + 1 * s} {tx + 6 * s},{ty + 2 * s} {tx},{ty} Z" fill="#bde67e" stroke="{outline}" stroke-width="{2 * s:.1f}" stroke-linejoin="round"/>'
            f'<path d="M {tx - 2 * s},{ty - 1 * s} L {tx - 14 * s},{ty - 3 * s}" stroke="#7fae45" stroke-width="{1.2 * s:.1f}" stroke-linecap="round"/>'
            f'<path d="M {tx + 2 * s},{ty - 2 * s} L {tx + 15 * s},{ty - 7 * s}" stroke="#86b84a" stroke-width="{1.2 * s:.1f}" stroke-linecap="round"/>')


# --------------------------------------------------------------------------------------------
# 苔团史莱姆 · moss slime. Body without eyes (eyes are a separate part so they can look and blink).
# Anchor (feet) at (85, 142).
def slime_body():
    ol = "#1d4034"
    jelly = "M 18,140 C 8,116 16,82 40,60 C 56,45 70,36 85,35 C 100,36 114,45 130,60 C 154,82 162,116 152,140 C 128,147 42,147 18,140 Z"
    defs = (radial("jelly", [(0, "#dcfbdc"), (0.32, "#98e3ae"), (0.72, "#55ba85"), (1, "#2f8a63")], 0.38, 0.32, 0.8)
            + radial("core", [(0, "#fff2ff"), (0.45, "#d59cff"), (1, "#8a45d6")], 0.45, 0.4, 0.6)
            + radial("moss", [(0, "#b5cf6c"), (0.6, "#86a549"), (1, "#5f7f35")], 0.4, 0.3, 0.8)
            + f'<clipPath id="jc"><path d="{jelly}"/></clipPath>')
    b = f'<path d="{jelly}" fill="url(#jelly)"/>'
    b += '<g clip-path="url(#jc)">'
    b += '<ellipse cx="85" cy="152" rx="84" ry="26" fill="#1f6b4c" opacity="0.5"/>'
    b += '<ellipse cx="92" cy="104" rx="36" ry="22" fill="#d6ffe6" opacity="0.22"/>'
    b += '<path d="M 146,76 C 158,98 160,120 152,140" fill="none" stroke="#eafff0" stroke-width="5" opacity="0.35"/>'
    b += '</g>'
    for cx, cy, r in [(46, 112, 5.5), (124, 98, 3.8), (114, 124, 4.4), (58, 128, 2.8), (134, 118, 2.4)]:
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#eafff2" fill-opacity="0.18" stroke="#eafff2" stroke-opacity="0.65" stroke-width="1.5"/>'
    # The swallowed curse: a small violet spark floating inside the jelly.
    b += '<circle cx="104" cy="116" r="15" fill="#b574ff" opacity="0.18"/>'
    b += '<path d="M 104,105 Q 106,114 115,116 Q 106,118 104,127 Q 102,118 93,116 Q 102,114 104,105 Z" fill="url(#core)" stroke="#6b2fb8" stroke-width="1.2" opacity="0.95"/>'
    b += '<ellipse cx="58" cy="66" rx="17" ry="9" transform="rotate(-38 58 66)" fill="#ffffff" opacity="0.82"/>'
    b += '<circle cx="77" cy="53" r="3.6" fill="#ffffff" opacity="0.85"/>'
    b += '<ellipse cx="56" cy="100" rx="9" ry="4.8" fill="#ff7fa6" opacity="0.6"/>'
    b += '<ellipse cx="120" cy="100" rx="9" ry="4.8" fill="#ff7fa6" opacity="0.6"/>'
    b += f'<path d="{jelly}" fill="none" stroke="{ol}" stroke-width="3.2" stroke-linejoin="round"/>'
    # Moss beret with a drippy edge and a sprout.
    moss = "M 48,52 C 52,32 68,24 85,25 C 102,24 120,32 124,52 C 116,47 108,55 99,49 C 91,56 82,48 74,54 C 66,48 57,57 48,52 Z"
    b += f'<path d="{moss}" fill="url(#moss)" stroke="#2e4a22" stroke-width="2.6" stroke-linejoin="round"/>'
    for cx, cy, r in [(64, 38, 3), (78, 33, 2.4), (98, 34, 3.2), (110, 42, 2.2), (86, 42, 2.0), (70, 46, 1.8)]:
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#c8df86" opacity="0.9"/>'
    b += sprout(88, 27, "#2e4a22", 1.0, 3)
    return svg(170, 150, defs, b)


def slime_eye():
    b = glossy_eye(13, 16, 8.5, 11.5, "#172520", True)
    return svg(26, 32, "", b)


# --------------------------------------------------------------------------------------------
# 栗刺球 · burr hog (chestnut hedgehog). Side view facing right; anchor (100, 158).
def spine_row(cx, cy, rx, ry, a0, a1, count, length, width, fill, hi, ol, tips, sweep=10):
    out = ""
    for i in range(count):
        t = i / (count - 1)
        a = math.radians(a0 + (a1 - a0) * t)
        base = (cx + rx * math.cos(a), cy - ry * math.sin(a))
        taper = 0.55 + 0.45 * math.sin(math.pi * t)
        l = length * taper
        d = a + math.radians(sweep)
        tip = (base[0] + math.cos(d) * l, base[1] - math.sin(d) * l)
        n = (-math.sin(a), -math.cos(a))
        left = (base[0] + n[0] * width, base[1] + n[1] * width)
        right = (base[0] - n[0] * width, base[1] - n[1] * width)
        inner = (base[0] - math.cos(a) * 6, base[1] + math.sin(a) * 6)
        out += f'<polygon points="{pts([left, tip, right, inner])}" fill="{fill}" stroke="{ol}" stroke-width="2" stroke-linejoin="round"/>'
        mid = ((left[0] + inner[0]) / 2, (left[1] + inner[1]) / 2)
        out += f'<polygon points="{pts([left, tip, mid])}" fill="{hi}" opacity="0.8"/>'
        if tips and i % 3 == 1:
            out += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="5.5" fill="{CURSE}" opacity="0.3"/>'
            out += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="2.6" fill="{CURSE_LIGHT}" stroke="{CURSE_DEEP}" stroke-width="1"/>'
    return out


def burr_body():
    ol = "#3b2418"
    defs = (radial("coat", [(0, "#b8703c"), (0.55, "#80421f"), (1, "#56290f")], 0.45, 0.3, 0.8)
            + radial("face", [(0, "#fde8c6"), (0.7, "#efc48e"), (1, "#d9a066")], 0.35, 0.3, 0.8)
            + radial("snout", [(0, "#ffc4b8"), (1, "#e48c80")], 0.35, 0.3, 0.8)
            + '<clipPath id="bc"><ellipse cx="92" cy="106" rx="62" ry="46"/></clipPath>')
    b = spine_row(90, 108, 58, 44, 200, 38, 13, 34, 8, "#8a6a2e", "#a8864a", ol, False, 14)
    b += spine_row(92, 106, 54, 40, 195, 45, 11, 30, 8, "#cdb06a", "#f0e2a8", ol, True, 8)
    b += '<ellipse cx="92" cy="106" rx="62" ry="46" fill="url(#coat)"/>'
    b += '<g clip-path="url(#bc)">'
    b += '<ellipse cx="112" cy="148" rx="44" ry="18" fill="#e9c796" opacity="0.85"/>'
    for x, y, a in [(58, 84, -20), (76, 74, -8), (96, 72, 6), (70, 98, -14), (90, 90, 0), (110, 86, 12), (52, 110, -30)]:
        b += f'<path d="M {x},{y} q 6,-7 12,0" transform="rotate({a} {x} {y})" fill="none" stroke="#5a2c12" stroke-width="2.2" stroke-linecap="round" opacity="0.7"/>'
    b += '<ellipse cx="70" cy="80" rx="22" ry="10" transform="rotate(-25 70 80)" fill="#ffffff" opacity="0.16"/>'
    b += '</g>'
    b += f'<ellipse cx="92" cy="106" rx="62" ry="46" fill="none" stroke="{ol}" stroke-width="3"/>'
    b += f'<path d="M 30,112 q -10,4 -8,-6" fill="#80421f" stroke="{ol}" stroke-width="2.5" stroke-linecap="round"/>'
    b += f'<ellipse cx="139" cy="80" rx="9" ry="11" transform="rotate(15 139 80)" fill="#c98a5c" stroke="{ol}" stroke-width="2.5"/>'
    b += '<ellipse cx="140" cy="81" rx="4.5" ry="6" transform="rotate(15 140 81)" fill="#f2b0a2"/>'
    b += f'<path d="M 126,86 C 140,78 168,82 182,100 C 192,114 188,134 170,142 C 150,150 128,142 122,126 C 116,112 116,94 126,86 Z" fill="url(#face)" stroke="{ol}" stroke-width="3" stroke-linejoin="round"/>'
    b += f'<ellipse cx="184" cy="116" rx="15" ry="11.5" transform="rotate(-8 184 116)" fill="url(#snout)" stroke="{ol}" stroke-width="2.6"/>'
    b += '<ellipse cx="195" cy="111" rx="6.5" ry="5.8" fill="#4a2419"/><circle cx="193" cy="109" r="2" fill="#ffffff"/>'
    b += glossy_eye(157, 104, 7, 9, "#1d130f", True)
    b += f'<path d="M 146,90 L 166,94" stroke="{ol}" stroke-width="3.2" stroke-linecap="round"/>'
    b += '<ellipse cx="166" cy="127" rx="8" ry="4.2" fill="#ff8f8f" opacity="0.5"/>'
    b += f'<path d="M 172,130 q 5,4 10,0" fill="none" stroke="{ol}" stroke-width="2.2" stroke-linecap="round"/>'
    return svg(210, 170, defs, b)


def burr_ball():
    ol = "#3b2418"
    defs = (radial("ball", [(0, "#bb743f"), (0.55, "#82431f"), (1, "#56290f")], 0.4, 0.32, 0.8)
            + radial("face", [(0, "#fde8c6"), (1, "#e3ad72")], 0.35, 0.3, 0.8)
            + '<clipPath id="ballc"><circle cx="85" cy="85" r="47"/></clipPath>')
    b = ""
    for ring, (count, length, fill, hi, offset) in enumerate([(20, 26, "#8a6a2e", "#a8864a", 9), (20, 24, "#cdb06a", "#f0e2a8", 0)]):
        for i in range(count):
            a = math.radians(i * 360 / count + offset)
            l = length * (1.0 if i % 2 == 0 else 0.72)
            base = (85 + 44 * math.cos(a), 85 - 44 * math.sin(a))
            d = a + math.radians(14)
            tip = (base[0] + math.cos(d) * l, base[1] - math.sin(d) * l)
            n = (-math.sin(a), -math.cos(a))
            left = (base[0] + n[0] * 8, base[1] + n[1] * 8)
            right = (base[0] - n[0] * 8, base[1] - n[1] * 8)
            b += f'<polygon points="{pts([left, tip, right])}" fill="{fill}" stroke="{ol}" stroke-width="2" stroke-linejoin="round"/>'
            mid = ((left[0] + base[0]) / 2, (left[1] + base[1]) / 2)
            b += f'<polygon points="{pts([left, tip, mid])}" fill="{hi}" opacity="0.8"/>'
            if ring == 1 and i % 4 == 0:
                b += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="5.5" fill="{CURSE}" opacity="0.3"/>'
                b += f'<circle cx="{tip[0]:.1f}" cy="{tip[1]:.1f}" r="2.6" fill="{CURSE_LIGHT}" stroke="{CURSE_DEEP}" stroke-width="1"/>'
    b += '<circle cx="85" cy="85" r="47" fill="url(#ball)"/>'
    b += '<g clip-path="url(#ballc)">'
    b += f'<path d="M 96,78 C 120,74 138,96 132,122 C 118,138 94,136 86,120 C 80,106 82,86 96,78 Z" fill="url(#face)" stroke="{ol}" stroke-width="2.6"/>'
    b += f'<path d="M 104,98 q 6,5 12,0" fill="none" stroke="{ol}" stroke-width="3" stroke-linecap="round"/>'
    b += f'<path d="M 101,94 l 6,2" stroke="{ol}" stroke-width="2.6" stroke-linecap="round"/>'
    b += '<ellipse cx="120" cy="112" rx="7" ry="3.8" fill="#ff8f8f" opacity="0.55"/>'
    for x, y, a in [(54, 62, -30), (70, 52, -5), (50, 88, -60), (64, 110, -100), (86, 60, 10)]:
        b += f'<path d="M {x},{y} q 6,-7 12,0" transform="rotate({a} {x} {y})" fill="none" stroke="#5a2c12" stroke-width="2.2" stroke-linecap="round" opacity="0.7"/>'
    b += '<ellipse cx="66" cy="66" rx="18" ry="9" transform="rotate(-35 66 66)" fill="#ffffff" opacity="0.18"/>'
    b += '</g>'
    b += f'<circle cx="85" cy="85" r="47" fill="none" stroke="{ol}" stroke-width="3"/>'
    return svg(170, 170, defs, b)


# --------------------------------------------------------------------------------------------
# 噗噗菇 · puffcap. Stem (with face, anchor (60, 104)), cap (anchor (90, 100)) and spore.
def puff_stem():
    ol = "#3a2f40"
    stem = "M 26,104 C 18,80 22,52 30,32 C 44,26 76,26 90,32 C 98,52 102,80 94,104 C 76,111 44,111 26,104 Z"
    defs = (linear("stem", [(0, "#fff6df"), (1, "#e2c99a")])
            + f'<clipPath id="sc"><path d="{stem}"/></clipPath>')
    b = ""
    for cx, rot in [(34, -18), (60, 0), (86, 18)]:
        b += f'<ellipse cx="{cx}" cy="105" rx="11" ry="6" transform="rotate({rot} {cx} 105)" fill="#c8a878" stroke="{ol}" stroke-width="2.4"/>'
    b += f'<path d="{stem}" fill="url(#stem)"/>'
    b += '<g clip-path="url(#sc)">'
    b += '<ellipse cx="102" cy="72" rx="22" ry="48" fill="#c9a36c" opacity="0.45"/>'
    b += '<ellipse cx="60" cy="30" rx="36" ry="9" fill="#8d7a5e" opacity="0.6"/>'
    b += '<ellipse cx="36" cy="60" rx="6" ry="20" fill="#ffffff" opacity="0.35"/>'
    b += '</g>'
    b += f'<path d="{stem}" fill="none" stroke="{ol}" stroke-width="3" stroke-linejoin="round"/>'
    # Sleepy, grumpy eyes: lids slant toward the middle.
    for cx, lid in [(45, 1), (75, -1)]:
        b += glossy_eye(cx, 60, 5.6, 7, "#221a26", True)
        y_out, y_in = 53.5 + (0 if lid > 0 else 3.5), 53.5 + (3.5 if lid > 0 else 0)
        x0, x1 = cx - 8, cx + 8
        b += f'<path d="M {x0},{y_out - 6} L {x1},{y_in - 6 if lid > 0 else y_out - 6} L {x1},{y_in if lid > 0 else y_out} L {x0},{y_out if lid > 0 else y_in} Z" fill="#fbf0d6"/>'
        b += f'<path d="M {x0},{y_out if lid > 0 else y_in} L {x1},{y_in if lid > 0 else y_out}" stroke="{ol}" stroke-width="2.6" stroke-linecap="round"/>'
    b += '<ellipse cx="37" cy="74" rx="7" ry="4" fill="#ff9fae" opacity="0.45"/>'
    b += '<ellipse cx="83" cy="74" rx="7" ry="4" fill="#ff9fae" opacity="0.45"/>'
    return svg(120, 114, defs, b)


def puff_cap():
    ol = "#1f2f45"
    cap = "M 14,96 C 8,56 44,16 90,14 C 136,16 172,56 166,96 C 150,107 30,107 14,96 Z"
    defs = (radial("cap", [(0, "#9fd6dc"), (0.5, "#5a92b0"), (1, "#2f5378")], 0.4, 0.22, 0.85)
            + radial("spot", [(0, "#fff4ff"), (0.45, "#e6aaff"), (1, "#a45cf0")], 0.4, 0.35, 0.7)
            + f'<clipPath id="cc"><path d="{cap}"/></clipPath>')
    b = f'<path d="{cap}" fill="url(#cap)"/>'
    b += '<g clip-path="url(#cc)">'
    b += '<ellipse cx="90" cy="108" rx="84" ry="18" fill="#1d3656" opacity="0.5"/>'
    b += '<ellipse cx="60" cy="34" rx="24" ry="8" transform="rotate(-24 60 34)" fill="#ffffff" opacity="0.4"/>'
    b += '</g>'
    for cx, cy, r in [(58, 48, 11), (102, 32, 8.5), (134, 60, 12), (86, 70, 8), (40, 76, 7), (122, 88, 6), (152, 84, 5)]:
        b += f'<circle cx="{cx}" cy="{cy}" r="{r * 1.8:.1f}" fill="#d49bff" opacity="0.2"/>'
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#spot)" stroke="{CURSE_DEEP}" stroke-width="1.5"/>'
        b += f'<circle cx="{cx - r * 0.35:.1f}" cy="{cy - r * 0.35:.1f}" r="{r * 0.28:.1f}" fill="#ffffff" opacity="0.8"/>'
    b += f'<path d="{cap}" fill="none" stroke="{ol}" stroke-width="3.2" stroke-linejoin="round"/>'
    b += '<path d="M 20,97 C 44,108 136,108 160,97" fill="none" stroke="#b9e4ea" stroke-width="2.6" stroke-linecap="round" opacity="0.55"/>'
    return svg(180, 112, defs, b)


def spore():
    defs = radial("sp", [(0, "#fff6ff"), (0.5, "#d4a4ff"), (1, "#8a4fd6")], 0.4, 0.35, 0.7)
    b = '<circle cx="21" cy="21" r="18" fill="#c89bff" opacity="0.2"/>'
    b += '<circle cx="21" cy="21" r="13" fill="#dcbcff" opacity="0.3"/>'
    for i in range(8):
        a = i * math.pi / 4 + 0.3
        b += f'<circle cx="{21 + math.cos(a) * 11:.1f}" cy="{21 + math.sin(a) * 11:.1f}" r="2" fill="#efdcff" stroke="#6b3aa8" stroke-width="0.8"/>'
    b += '<circle cx="21" cy="21" r="8.5" fill="url(#sp)" stroke="#4b2a78" stroke-width="1.6"/>'
    b += '<circle cx="18.5" cy="18" r="2.4" fill="#ffffff" opacity="0.9"/>'
    return svg(42, 42, defs, b)


# --------------------------------------------------------------------------------------------
# 灰翅夜蛾 · shade moth. Front view: body (centre (50, 64)) and one LEFT wing (shoulder pivot
# (124, 72)); the right wing is the same texture mirrored.
def moth_body():
    ol = "#3a2a4a"
    defs = (radial("abd", [(0, "#f2ecfa"), (0.6, "#c4b4e0"), (1, "#8f7bb8")], 0.4, 0.3, 0.8)
            + radial("head", [(0, "#fbf7ff"), (1, "#cdbfe6")], 0.4, 0.3, 0.8))
    b = ""
    for side in (-1, 1):
        x0, y0 = 50 + side * 7, 34
        cx1, cy1 = 50 + side * 14, 14
        x1, y1 = 50 + side * 30, 8
        b += f'<path d="M {x0},{y0} Q {cx1},{cy1} {x1},{y1}" fill="none" stroke="{ol}" stroke-width="4" stroke-linecap="round"/>'
        b += f'<path d="M {x0},{y0} Q {cx1},{cy1} {x1},{y1}" fill="none" stroke="#8c77a8" stroke-width="2" stroke-linecap="round"/>'
        for k in range(1, 6):
            t = k / 6
            px = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * cx1 + t * t * x1
            py = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * cy1 + t * t * y1
            b += f'<path d="M {px:.1f},{py:.1f} l {side * 5:.1f},{3.5:.1f}" stroke="#6d5a84" stroke-width="1.6" stroke-linecap="round"/>'
            b += f'<path d="M {px:.1f},{py:.1f} l {-side * 1.5:.1f},{-5:.1f}" stroke="#6d5a84" stroke-width="1.4" stroke-linecap="round"/>'
        b += f'<circle cx="{x1}" cy="{y1}" r="3.2" fill="#e9dcff" stroke="{ol}" stroke-width="1.5"/>'
    b += f'<ellipse cx="50" cy="88" rx="15" ry="25" fill="url(#abd)" stroke="{ol}" stroke-width="2.6"/>'
    for y in (82, 92, 102):
        b += f'<path d="M {50 - 12 + (y - 82) * 0.12:.1f},{y} Q 50,{y + 5} {50 + 12 - (y - 82) * 0.12:.1f},{y}" fill="none" stroke="#8e78b8" stroke-width="2" stroke-linecap="round"/>'
    b += '<circle cx="50" cy="110" r="3" fill="#b27cff" opacity="0.8"/>'
    for i in range(10):
        a = i * math.tau / 10 + 0.2
        b += f'<circle cx="{50 + math.cos(a) * 16:.1f}" cy="{58 + math.sin(a) * 14:.1f}" r="7.5" fill="#fff8ee" stroke="{ol}" stroke-width="2.2"/>'
    b += '<ellipse cx="50" cy="58" rx="16" ry="14" fill="#fff8ee"/>'
    b += '<ellipse cx="46" cy="64" rx="7" ry="4" fill="#efe2cf" opacity="0.8"/>'
    b += f'<circle cx="50" cy="42" r="15.5" fill="url(#head)" stroke="{ol}" stroke-width="2.6"/>'
    b += glossy_eye(43.5, 43, 5.8, 7, "#241834", True)
    b += glossy_eye(56.5, 43, 5.8, 7, "#241834", True)
    b += '<ellipse cx="39" cy="51" rx="4" ry="2.4" fill="#ff9fc0" opacity="0.5"/>'
    b += '<ellipse cx="61" cy="51" rx="4" ry="2.4" fill="#ff9fc0" opacity="0.5"/>'
    return svg(100, 120, defs, b)


def moth_wing():
    ol = "#3a2a4a"
    upper = "M 124,66 C 104,22 64,4 28,12 C 6,20 2,50 18,66 C 42,86 96,80 124,72 Z"
    lower = "M 124,76 C 98,82 60,96 50,120 C 44,140 70,148 92,136 C 110,124 120,102 124,80 Z"
    defs = (radial("wu", [(0, "#c3b5e2"), (0.55, "#8674b2"), (1, "#4f3f78")], 0.85, 0.75, 0.95)
            + radial("wl", [(0, "#b6a8d8"), (0.6, "#7a68a6"), (1, "#4a3a70")], 0.9, 0.2, 1.0)
            + radial("eye", [(0, "#fff0ff"), (0.5, "#dca8ff"), (1, "#8a45d6")], 0.4, 0.35, 0.7)
            + f'<clipPath id="uc"><path d="{upper}"/></clipPath><clipPath id="lc"><path d="{lower}"/></clipPath>')
    b = f'<path d="{lower}" fill="url(#wl)"/>'
    b += f'<g clip-path="url(#lc)"><path d="{lower}" fill="none" stroke="#ece2fb" stroke-width="10" opacity="0.45"/>'
    b += '<circle cx="78" cy="120" r="8" fill="#f2e2a2"/><circle cx="78" cy="120" r="4.5" fill="#3a2a55"/>'
    b += '<circle cx="76.5" cy="118.5" r="1.4" fill="#ffffff"/></g>'
    b += f'<path d="{lower}" fill="none" stroke="{ol}" stroke-width="2.6" stroke-linejoin="round"/>'
    b += f'<path d="{upper}" fill="url(#wu)"/>'
    b += f'<g clip-path="url(#uc)"><path d="{upper}" fill="none" stroke="#ece2fb" stroke-width="11" opacity="0.45"/>'
    for x, y in [(90, 30), (60, 20), (40, 46), (70, 64)]:
        b += f'<path d="M 124,68 Q {(124 + x) / 2 + 4:.1f},{(68 + y) / 2 - 6:.1f} {x},{y}" fill="none" stroke="#d6caf0" stroke-width="1.6" opacity="0.5"/>'
    b += '<circle cx="54" cy="40" r="22" fill="#c592ff" opacity="0.18"/>'
    b += '<circle cx="54" cy="40" r="14.5" fill="#f2e2a2" stroke="#8a6a3a" stroke-width="1.2"/>'
    b += '<circle cx="54" cy="40" r="9.5" fill="#3a2a55"/>'
    b += '<circle cx="54" cy="40" r="5.5" fill="url(#eye)"/>'
    b += '<circle cx="51.5" cy="37.5" r="2" fill="#ffffff" opacity="0.9"/></g>'
    b += f'<path d="{upper}" fill="none" stroke="{ol}" stroke-width="2.6" stroke-linejoin="round"/>'
    for x, y in [(30, 13), (17, 26), (10, 42), (14, 58)]:
        b += f'<circle cx="{x}" cy="{y}" r="2.3" fill="#f3ecff" opacity="0.9"/>'
    return svg(130, 152, defs, b)


# --------------------------------------------------------------------------------------------
# 橡果蛛 · acorn spider. Body with acorn cap (centre (60, 70)); legs and silk are drawn in code.
def spider_body():
    ol = "#22150f"
    cap = "M 24,58 C 24,30 42,18 60,18 C 78,18 96,30 96,58 C 82,52 38,52 24,58 Z"
    defs = (radial("fur", [(0, "#8a5f48"), (0.55, "#553628"), (1, "#2e1c15")], 0.4, 0.35, 0.8)
            + radial("acorn", [(0, "#e2b676"), (0.6, "#b07a3e"), (1, "#7a4f24")], 0.4, 0.3, 0.85)
            + f'<clipPath id="capc"><path d="{cap}"/></clipPath>')
    b = ""
    for i in range(30):
        a = i * math.tau / 30
        base_l = (60 + math.cos(a - 0.1) * 32, 74 + math.sin(a - 0.1) * 30)
        base_r = (60 + math.cos(a + 0.1) * 32, 74 + math.sin(a + 0.1) * 30)
        tip = (60 + math.cos(a) * 39, 74 + math.sin(a) * 36)
        b += f'<polygon points="{pts([base_l, tip, base_r])}" fill="#3a241a" stroke="{ol}" stroke-width="1.4" stroke-linejoin="round"/>'
    b += f'<ellipse cx="60" cy="74" rx="33" ry="31" fill="url(#fur)" stroke="{ol}" stroke-width="2.4"/>'
    b += '<ellipse cx="48" cy="84" rx="12" ry="7" fill="#ffffff" opacity="0.08"/>'
    b += f'<path d="{cap}" fill="url(#acorn)"/>'
    b += '<g clip-path="url(#capc)">'
    for k in range(-5, 7):
        b += f'<path d="M {20 + k * 12},{60} L {44 + k * 12},{16}" stroke="#8a5c2c" stroke-width="1.6" opacity="0.65"/>'
        b += f'<path d="M {20 + k * 12},{16} L {44 + k * 12},{60}" stroke="#8a5c2c" stroke-width="1.6" opacity="0.65"/>'
    b += '<ellipse cx="46" cy="30" rx="12" ry="6" transform="rotate(-25 46 30)" fill="#ffffff" opacity="0.35"/>'
    b += '</g>'
    b += f'<path d="{cap}" fill="none" stroke="#3a2616" stroke-width="2.8" stroke-linejoin="round"/>'
    b += f'<path d="M 22,58 C 40,66 80,66 98,58" fill="none" stroke="#3a2616" stroke-width="7" stroke-linecap="round"/>'
    b += f'<path d="M 22,58 C 40,66 80,66 98,58" fill="none" stroke="#9a6a36" stroke-width="3.6" stroke-linecap="round"/>'
    b += f'<path d="M 57,20 C 56,12 58,6 64,4" fill="none" stroke="#3a2616" stroke-width="6" stroke-linecap="round"/>'
    b += f'<path d="M 57,20 C 56,12 58,6 64,4" fill="none" stroke="#8a5c2c" stroke-width="3" stroke-linecap="round"/>'
    b += '<circle cx="60" cy="38" r="9" fill="#c592ff" opacity="0.25"/>'
    b += f'<polygon points="60,31 65,38 60,45 55,38" fill="{CURSE_LIGHT}" stroke="{CURSE_DEEP}" stroke-width="1.4" stroke-linejoin="round"/>'
    b += glossy_eye(49, 78, 7.5, 8.8, "#170f0c", True)
    b += glossy_eye(71, 78, 7.5, 8.8, "#170f0c", True)
    b += '<circle cx="40" cy="68" r="3.2" fill="#170f0c"/><circle cx="39" cy="67" r="1.1" fill="#ffffff"/>'
    b += '<circle cx="80" cy="68" r="3.2" fill="#170f0c"/><circle cx="79" cy="67" r="1.1" fill="#ffffff"/>'
    b += '<ellipse cx="40" cy="90" rx="6" ry="3.4" fill="#ff8f8f" opacity="0.38"/>'
    b += '<ellipse cx="80" cy="90" rx="6" ry="3.4" fill="#ff8f8f" opacity="0.38"/>'
    b += f'<path d="M 55,92 L 57.5,100 L 60,92 Z" fill="#f5ead6" stroke="{ol}" stroke-width="1.4" stroke-linejoin="round"/>'
    b += f'<path d="M 60,92 L 62.5,100 L 65,92 Z" fill="#f5ead6" stroke="{ol}" stroke-width="1.4" stroke-linejoin="round"/>'
    return svg(120, 116, defs, b)


# --------------------------------------------------------------------------------------------
# 苔壳蜗牛 · moss snail. Soft body facing right (anchor (82, 86)) and a stone shell with moss and a
# curse crystal (centre (65, 68)). A cracked shell is drawn in code.
def snail_body():
    ol = "#34401f"
    body = "M 8,80 C 18,70 60,66 110,64 C 130,62 136,42 144,32 C 154,20 172,24 175,40 C 178,58 170,76 152,84 C 110,90 38,90 8,80 Z"
    defs = (linear("slug", [(0, "#e3ecb4"), (1, "#9fb56a")])
            + f'<clipPath id="slc"><path d="{body}"/></clipPath>')
    b = ""
    for x0, y0, x1, y1 in [(148, 32, 142, 8), (162, 28, 168, 6)]:
        b += f'<path d="M {x0},{y0} Q {x0 - 1},{(y0 + y1) / 2} {x1},{y1}" fill="none" stroke="{ol}" stroke-width="9" stroke-linecap="round"/>'
        b += f'<path d="M {x0},{y0} Q {x0 - 1},{(y0 + y1) / 2} {x1},{y1}" fill="none" stroke="#cbd99a" stroke-width="5" stroke-linecap="round"/>'
    b += f'<path d="{body}" fill="url(#slug)"/>'
    b += '<g clip-path="url(#slc)">'
    b += '<ellipse cx="90" cy="92" rx="90" ry="10" fill="#7d9450" opacity="0.55"/>'
    b += '<path d="M 14,79 C 60,84 120,84 156,78" fill="none" stroke="#f3f7d6" stroke-width="3" opacity="0.6"/>'
    for cx, cy, r in [(40, 76, 3), (70, 72, 3.6), (100, 74, 2.6), (128, 68, 2.4)]:
        b += f'<ellipse cx="{cx}" cy="{cy}" rx="{r * 1.4:.1f}" ry="{r}" fill="#b8c887" opacity="0.9"/>'
    b += '<ellipse cx="152" cy="38" rx="9" ry="5" transform="rotate(-30 152 38)" fill="#ffffff" opacity="0.35"/>'
    b += '</g>'
    b += f'<path d="{body}" fill="none" stroke="{ol}" stroke-width="3" stroke-linejoin="round"/>'
    for x, y in [(142, 8), (168, 6)]:
        b += f'<circle cx="{x}" cy="{y}" r="7" fill="#fbfbef" stroke="{ol}" stroke-width="2"/>'
        b += f'<circle cx="{x + 2}" cy="{y + 0.5}" r="3.8" fill="#1d2418"/>'
        b += f'<circle cx="{x + 1}" cy="{y - 1}" r="1.3" fill="#ffffff"/>'
    b += f'<path d="M 160,54 q 6,5 11,-1" fill="none" stroke="{ol}" stroke-width="2.4" stroke-linecap="round"/>'
    b += '<ellipse cx="156" cy="60" rx="6" ry="3.4" fill="#ff9f9f" opacity="0.5"/>'
    return svg(184, 94, defs, b)


def snail_shell():
    ol = "#34291d"
    defs = (radial("shell", [(0, "#cfc5a8"), (0.55, "#8d8268"), (1, "#5c5242")], 0.38, 0.3, 0.85)
            + radial("mossy", [(0, "#b5cf6c"), (1, "#5f7f35")], 0.4, 0.3, 0.8)
            + linear("crystal", [(0, "#f7ebff"), (0.5, "#c08cff"), (1, "#6b2fb8")], 0, 0, 1, 1)
            + '<clipPath id="shc"><ellipse cx="65" cy="70" rx="50" ry="47"/></clipPath>')
    b = '<ellipse cx="65" cy="70" rx="50" ry="47" fill="url(#shell)"/>'
    spiral = []
    for i in range(160):
        t = i / 159
        a = -math.pi / 2 + t * math.tau * 2.1
        r = 5 + 38 * t
        spiral.append((68 + math.cos(a) * r, 72 + math.sin(a) * r * 0.95))
    path = "M " + " L ".join(f"{x:.1f},{y:.1f}" for x, y in spiral)
    b += '<g clip-path="url(#shc)">'
    b += f'<path d="{path}" fill="none" stroke="#e2dac2" stroke-width="2" opacity="0.55" transform="translate(-1.5 -1.5)"/>'
    b += f'<path d="{path}" fill="none" stroke="#4a3f30" stroke-width="3.4" stroke-linecap="round"/>'
    b += '<ellipse cx="65" cy="122" rx="56" ry="16" fill="#3c3428" opacity="0.4"/>'
    b += '<ellipse cx="42" cy="44" rx="16" ry="8" transform="rotate(-35 42 44)" fill="#ffffff" opacity="0.3"/>'
    b += '</g>'
    b += f'<ellipse cx="65" cy="70" rx="50" ry="47" fill="none" stroke="{ol}" stroke-width="3"/>'
    moss = "M 22,52 C 24,32 44,20 64,22 C 76,23 84,28 88,36 C 80,34 76,42 68,38 C 60,46 52,38 44,46 C 36,42 30,54 22,52 Z"
    b += f'<path d="{moss}" fill="url(#mossy)" stroke="#2e4a22" stroke-width="2.4" stroke-linejoin="round"/>'
    for cx, cy, r in [(40, 36, 2.6), (56, 30, 2.2), (70, 30, 2.8), (32, 46, 1.8)]:
        b += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#c8df86"/>'
    b += sprout(52, 25, "#2e4a22", 0.75, -2)
    b += '<circle cx="98" cy="30" r="20" fill="#c592ff" opacity="0.22"/>'
    for pts_list in ([(90, 38), (86, 22), (92, 12), (98, 22), (96, 38)],
                     [(98, 40), (100, 18), (108, 8), (112, 22), (106, 42)],
                     [(106, 44), (112, 32), (120, 30), (118, 44)]):
        b += f'<polygon points="{pts(pts_list)}" fill="url(#crystal)" stroke="#3d1f66" stroke-width="2" stroke-linejoin="round"/>'
    b += '<path d="M 101,16 L 103,34" stroke="#ffffff" stroke-width="1.6" opacity="0.7" stroke-linecap="round"/>'
    b += '<path d="M 90,20 L 91,32" stroke="#ffffff" stroke-width="1.4" opacity="0.6" stroke-linecap="round"/>'
    return svg(130, 124, defs, b)


PARTS = {
    "slime_body": slime_body, "slime_eye": slime_eye,
    "burr_body": burr_body, "burr_ball": burr_ball,
    "puff_stem": puff_stem, "puff_cap": puff_cap, "spore": spore,
    "moth_body": moth_body, "moth_wing": moth_wing,
    "spider_body": spider_body,
    "snail_body": snail_body, "snail_shell": snail_shell,
}

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, make in PARTS.items():
        with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8") as f:
            f.write(make())
    print("wrote %d svg files to %s" % (len(PARTS), OUT))
