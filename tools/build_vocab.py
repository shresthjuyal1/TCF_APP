"""Build the Vocab tab's JSON files from tools/vocab-source.txt and the reading tests.

For every word it finds the reading questions that use it, picks a short example sentence,
and sets the word's level to the typical (median) level of those questions.

Usage: python3 -I tools/build_vocab.py <project_dir> [--report]
  Writes Allez/Content/Vocab/vocab-<theme>.json. Example translations come from
  tools/vocab-example-translations.tsv (French word <TAB> example sentence <TAB> its English translation).
  With --report, also prints words that were not found and examples still missing a translation.
"""
import json
import re
import statistics
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
REPORT = "--report" in sys.argv
LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]

# Unique reading questions (tests repeat many of them).
texts, seen = [], set()
for f in sorted((ROOT / "Allez/Content/Lecture").glob("*.json")):
    for q in json.loads(f.read_text())["questions"]:
        key = re.sub(r"\W", "", (q.get("passage", "") + q["question"]).lower())
        if key in seen:
            continue
        seen.add(key)
        text = (q.get("passage", "") + "\n" + q["question"]).replace("’", "'")
        texts.append((q["level"], text))


def sentences(text):
    for part in re.split(r"(?<=[.!?…])\s+|\n", text):
        part = part.strip()
        if part:
            yield part


def pattern_for(french, explicit):
    if explicit:
        body = explicit
    else:
        base = re.sub(r"\s*\((m\.|f\.|m\./f\.)\)", "", french)
        base = re.sub(r"^(le/la |le |la |les |l')", "", base).replace("’", "'")
        is_noun = re.match(r"^(le/la |le |la |les |l')", french) is not None
        body = re.escape(base) + ("" if " " in base else (r"(s|x)?" if is_noun else r"(s|x|e|es)?"))
    if explicit and explicit.endswith("$"):
        # Exact forms only, e.g. "pay(?:er|é)$" so that "pays" (country) doesn't count for "payer".
        return re.compile(r"(?<![\w-])(?:" + explicit[:-1] + r")(?![\w])", re.IGNORECASE)
    return re.compile(r"(?<![\w-])(?:" + body + r")[\w-]*" if explicit else r"(?<![\w-])" + body + r"(?![\w])", re.IGNORECASE)


translations = {}
tsv = ROOT / "tools/vocab-example-translations.tsv"
if tsv.exists():
    for line in tsv.read_text().splitlines():
        if "\t" in line and not line.startswith("#"):
            fr, example, en = line.split("\t", 2)
            translations[fr.strip()] = (example.strip(), en.strip())

themes, current = [], None
for raw in (ROOT / "tools/vocab-source.txt").read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith("# "):
        continue
    if line.startswith("## "):
        tid, title, icon = [p.strip() for p in line[3:].split("|")]
        current = {"id": tid, "title": title, "icon": icon, "words": []}
        themes.append(current)
        continue
    parts = [p.strip() for p in line.split("|", 2)]
    french, english = parts[0], parts[1]
    explicit = parts[2] if len(parts) > 2 else None
    current["words"].append({"french": french, "english": english, "pattern": pattern_for(french, explicit)})

out_dir = ROOT / "Allez/Content/Vocab"
out_dir.mkdir(parents=True, exist_ok=True)
for old in out_dir.glob("vocab-*.json"):
    old.unlink()
missing, untranslated, total = [], [], 0
all_french = set()
for number, theme in enumerate(themes, 1):
    words = []
    for w in theme["words"]:
        if w["french"] in all_french:
            missing.append(f"DUPLICATE {w['french']}")
            continue
        all_french.add(w["french"])
        levels, best = [], None
        for level, text in texts:
            if not w["pattern"].search(text):
                continue
            levels.append(LEVELS.index(level))
            for s in sentences(text):
                m = w["pattern"].search(s)
                if not m or not 30 <= len(s) <= 170 or s.endswith("?") or s.isupper():
                    continue
                score = abs(len(s) - 85)
                if not re.match(r"^[«\"A-ZÀ-Ý]", s) or not re.search(r"[.!»]$", s):
                    score += 60  # incomplete sentence
                if m.start() > 0 and m.group(0)[0].isupper():
                    score += 100  # probably part of a name
                if best is None or score < best[0]:
                    best = (score, s)
        if not levels:
            missing.append(f"{theme['id']}: {w['french']}")
            continue
        entry = {"french": w["french"], "english": w["english"], "level": LEVELS[int(statistics.median_low(levels))]}
        if w["french"] in translations:
            # A hand-checked example (which may replace the automatic one) and its translation.
            entry["example"], entry["exampleTranslation"] = translations[w["french"]]
        elif best:
            entry["example"] = best[1]
            untranslated.append(f"{w['french']}\t{best[1]}")
        words.append(entry)
    total += len(words)
    data = {"id": theme["id"], "title": theme["title"], "icon": theme["icon"], "words": words}
    # The number keeps the themes in the same order as in vocab-source.txt.
    (out_dir / f"vocab-{number:02d}-{theme['id']}.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    print(f"{theme['title']}: {len(words)} words")

print(f"\nTotal: {total} words in {len(themes)} themes")
if REPORT:
    print(f"\nNot found in the reading tests ({len(missing)}):")
    print("\n".join(missing))
    print(f"\nExamples without a translation ({len(untranslated)}):")
    print("\n".join(untranslated))
