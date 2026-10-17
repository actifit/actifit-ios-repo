#!/usr/bin/env python3
"""Copy the Arena and Friends translations from the Android app into the iOS Localizable.strings.

The iOS copy (ArenaText, FriendsText) looks strings up under Android's keys, falling back to its
own English, so the two apps share one set of translations. Re-run after Android's strings change:

    python ci_scripts/import_android_strings.py ../actifit/android/app/src/main/res

Each iOS Localizable.strings gets one generated block between BEGIN/END markers, replaced on
every run. Android placeholders are converted (%1$s -> %1$@, %1$d -> %1$ld) and plurals become
key_one / key_other (plus key_zero/_two/_few/_many where a language has them).
"""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

# iOS .lproj -> Android values-<qualifier>
LOCALES = {"ar": "ar", "de": "de", "hi": "hi", "it": "it", "ko": "ko", "nl": "nl", "pt-PT": "pt", "yo": "yo"}
PREFIXES = ("arena_", "friends_", "profile_friend_")
EXTRA_KEYS = {"footer_arena", "close_button"}

BEGIN = "/* BEGIN Arena and Friends, imported from Android by ci_scripts/import_android_strings.py. Do not edit by hand. */"
END = "/* END Arena and Friends */"

IOS_DIR = Path(__file__).resolve().parent.parent / "Actifit" / "Controllers"


def wanted(name):
    return name.startswith(PREFIXES) or name in EXTRA_KEYS


def android_text(elem):
    """Android resource text to a plain string (resource escapes undone)."""
    s = "".join(elem.itertext()).strip()
    if len(s) >= 2 and s[0] == s[-1] == '"':
        s = s[1:-1]
    return s.replace("\\'", "'").replace('\\"', '"').replace("\\@", "@").replace("\\?", "?")


def to_ios(s):
    """Android placeholders to iOS ones, then escaped for a .strings value."""
    s = re.sub(r"%(\d+\$)?d", lambda m: "%" + (m.group(1) or "") + "ld", s)
    s = re.sub(r"%(\d+\$)?s", lambda m: "%" + (m.group(1) or "") + "@", s)
    s = s.replace("\\", "\\\\").replace("\\\\n", "\\n").replace('"', '\\"')
    return s.replace("\n", "\\n")


def load(path):
    entries = {}
    if not path.exists():
        return entries
    for elem in ET.parse(path).getroot():
        name = elem.get("name", "")
        if not wanted(name) or elem.get("translatable") == "false":
            continue
        if elem.tag == "string":
            entries[name] = android_text(elem)
        elif elem.tag == "plurals":
            for item in elem:
                entries[name + "_" + item.get("quantity")] = android_text(item)
    return entries


def placeholders(s):
    """The format specifiers in an Android string, e.g. ['1$d', '2$s'] or ['d']."""
    return sorted((m.group(1) or "") + m.group(2) for m in re.finditer(r"%(\d+\$)?([sd])", s.replace("%%", "")))


def main(res):
    res = Path(res)
    english = load(res / "values" / "strings.xml")
    for ios, android in LOCALES.items():
        entries = load(res / ("values-" + android) / "strings.xml")
        # A translation whose placeholders differ from the English (say %s where a number is
        # passed) would garble or crash String(format:), so it is left out and English shows.
        for key in sorted(entries):
            base = english.get(key, english.get(key.rsplit("_", 1)[0] + "_other"))
            if base is None or placeholders(entries[key]) != placeholders(base):
                print("  %s: skipped %s (placeholders differ from English)" % (ios, key))
                del entries[key]
        target = IOS_DIR / (ios + ".lproj") / "Localizable.strings"
        with open(target, encoding="utf-8", newline="") as f:
            text = f.read()
        text = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\r?\n?", "", text, flags=re.S).rstrip()
        lines = [BEGIN] + ['"%s" = "%s";' % (k, to_ios(v)) for k, v in sorted(entries.items())] + [END]
        with open(target, "w", encoding="utf-8", newline="") as f:
            f.write(text + "\r\n\r\n" + "\r\n".join(lines) + "\r\n")
        print("%-6s %3d strings" % (ios, len(entries)))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
