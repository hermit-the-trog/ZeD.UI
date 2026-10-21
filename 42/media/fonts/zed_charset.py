"""
The character set shared by ZeD-UI's two font bakers:

  generate_fonts.py            bitmap faces (42/media/fonts/*.fnt and EN/2x, 3x, 4x)
  ZeDUI/tools/fonts/bake_sdf.py  distance-field role faces (42/media/fonts/sdf)

One list means the bitmap and distance-field faces always cover the same letters.

What it covers, and why:
  Basic Latin and Latin-1 Supplement       English, French, German, Spanish, Italian, Portuguese,
                                           Scandinavian languages, the degree sign, the multiply sign
  Latin Extended-A (U+0100-017F)           Czech, Polish, Hungarian, Turkish, Croatian, Slovak,
                                           Slovenian, Latvian, Lithuanian, Romanian (the old forms)
  Latin Extended-B, a chosen subset        Romanian comma letters (S and T with comma below), the
                                           f with hook, Azerbaijani schwa, the Vietnamese horn
                                           letters, the pinyin tone-mark letters, Welsh and others
  Spacing modifier letters                 caron, breve, dot, ring, ogonek, tilde, double acute
  Greek (U+0370-03FF)                      Greek, with tonos and dialytika forms
  Cyrillic (U+0400-04FF)                   Russian, Ukrainian, Belarusian, Bulgarian, Serbian,
                                           Macedonian, Kazakh and the other Cyrillic languages
  Punctuation and symbols                  dashes, typographic quotes, bullet, ellipsis, per mille,
                                           euro and other currency signs, trademark, numero sign,
                                           arrows, minus, comparison signs

A baker keeps only the code points its own TTF actually draws; the rest are reported as missing
(Fira Mono has fewer Latin Extended-B letters than Fira Sans, for example).
"""

import struct

# Latin Extended-B: the letters in common use (kept short on purpose)
LATIN_EXT_B = (
    [0x018F, 0x0192, 0x01A0, 0x01A1, 0x01AF, 0x01B0]
    + list(range(0x01CD, 0x01DD))      # pinyin: A I O U with caron, U with diaeresis and tone marks
    + [0x01DD]                          # turned e
    + [0x01E6, 0x01E7, 0x01E8, 0x01E9, 0x01EA, 0x01EB]   # G and K with caron, O with ogonek
    + [0x01F4, 0x01F5, 0x01F8, 0x01F9]
    + [0x01FA, 0x01FB, 0x01FC, 0x01FD, 0x01FE, 0x01FF]
    + [0x0218, 0x0219, 0x021A, 0x021B]  # Romanian: S and T with comma below
    + [0x0237, 0x0259]                  # dotless j, schwa
)

# Spacing modifier letters (the loose accent marks)
MODIFIERS = [0x02C6, 0x02C7, 0x02D8, 0x02D9, 0x02DA, 0x02DB, 0x02DC, 0x02DD]

# Punctuation, currency and symbols. The first nine were already in the set before the
# alphabet extension (en dash, em dash, curly quotes, bullet, ellipsis, euro).
PUNCT = [
    0x2012, 0x2013, 0x2014, 0x2015,            # figure dash, en dash, em dash, horizontal bar
    0x2018, 0x2019, 0x201A, 0x201B,            # single curly quotes
    0x201C, 0x201D, 0x201E, 0x201F,            # double curly quotes
    0x2020, 0x2021, 0x2022, 0x2026,            # dagger, double dagger, bullet, ellipsis
    0x2030, 0x2032, 0x2033, 0x2039, 0x203A,    # per mille, primes, single guillemets
    0x2044,                                     # fraction slash
    0x20AC, 0x20B4, 0x20B9, 0x20BA, 0x20BD,    # euro, hryvnia, rupee, lira, ruble
    0x2116, 0x2122, 0x2126,                    # numero sign, trademark, ohm
    0x2190, 0x2191, 0x2192, 0x2193,            # arrows
    0x2212, 0x2260, 0x2264, 0x2265,            # minus, not equal, less or equal, greater or equal
    0x1E9E,                                     # capital sharp s
]

# The set that must stay on the first atlas page of every face (what the old faces carried),
# so ordinary English and Western European text draws from a single texture.
CORE_MAX = 0x00FF
CORE_EXTRA = {0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026, 0x20AC}


def wanted_code_points():
    """Every code point ZeD wants, sorted, with no duplicates (before the TTF filter)."""
    ids = set()
    ids.update(range(0x0020, 0x007F))
    ids.update(range(0x00A0, 0x0100))
    ids.update(range(0x0100, 0x0180))
    ids.update(LATIN_EXT_B)
    ids.update(MODIFIERS)
    ids.update(range(0x0370, 0x0400))
    ids.update(range(0x0400, 0x0500))
    ids.update(PUNCT)
    return sorted(ids)


CHAR_IDS = wanted_code_points()


def is_core(cp):
    """True for the code points that go on page 0 first (ASCII, Latin-1, the old punctuation)."""
    return cp <= CORE_MAX or cp in CORE_EXTRA


def read_cmap(path):
    """Code points a TrueType file draws, as a dict {code point: glyph id}.

    A small reader for cmap formats 4 and 12, so the bakers can tell a real glyph from the
    font's missing-glyph box without installing anything.
    """
    with open(path, "rb") as fh:
        data = fh.read()
    num = struct.unpack(">H", data[4:6])[0]
    tables = {}
    for i in range(num):
        tag, _cs, off, ln = struct.unpack(">4sIII", data[12 + 16 * i:28 + 16 * i])
        tables[tag.decode("latin-1")] = (off, ln)
    o = tables["cmap"][0]
    n = struct.unpack(">H", data[o + 2:o + 4])[0]
    subs = {}
    for i in range(n):
        pid, eid, off = struct.unpack(">HHI", data[o + 4 + 8 * i:o + 12 + 8 * i])
        subs[(pid, eid)] = o + off
    for key in [(3, 10), (0, 4), (3, 1), (0, 3)]:
        if key not in subs:
            continue
        so = subs[key]
        fmt = struct.unpack(">H", data[so:so + 2])[0]
        m = {}
        if fmt == 12:
            ngroups = struct.unpack(">I", data[so + 12:so + 16])[0]
            for g in range(ngroups):
                a, b, s = struct.unpack(">III", data[so + 16 + 12 * g:so + 28 + 12 * g])
                for c in range(a, b + 1):
                    m[c] = s + c - a
            return m
        if fmt == 4:
            segx2 = struct.unpack(">H", data[so + 6:so + 8])[0]
            seg = segx2 // 2
            ends = struct.unpack(">%dH" % seg, data[so + 14:so + 14 + segx2])
            starts = struct.unpack(">%dH" % seg, data[so + 16 + segx2:so + 16 + 2 * segx2])
            deltas = struct.unpack(">%dh" % seg, data[so + 16 + 2 * segx2:so + 16 + 3 * segx2])
            ro_base = so + 16 + 3 * segx2
            ros = struct.unpack(">%dH" % seg, data[ro_base:ro_base + segx2])
            for i in range(seg):
                for c in range(starts[i], ends[i] + 1):
                    if c == 0xFFFF:
                        continue
                    if ros[i] == 0:
                        gid = (c + deltas[i]) & 0xFFFF
                    else:
                        a = ro_base + 2 * i + ros[i] + 2 * (c - starts[i])
                        gid = struct.unpack(">H", data[a:a + 2])[0]
                        if gid:
                            gid = (gid + deltas[i]) & 0xFFFF
                    if gid:
                        m[c] = gid
            return m
    raise RuntimeError(f"{path}: no usable Unicode cmap (format 4 or 12)")
