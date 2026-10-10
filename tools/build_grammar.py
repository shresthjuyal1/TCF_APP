"""Build the grammar path (Path tab) from tools/grammar-source.txt.

Usage: python3 -I tools/build_grammar.py <project_dir>
Writes Allez/Content/Parcours/parcours.json (the lessons, their order and rule cards)
and one grammar-<level>.json question file per level. Stops with an error if a question is malformed.
"""
import json
import random
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
SOURCE = ROOT / "tools/grammar-source.txt"
OUT = ROOT / "Allez/Content/Parcours"

units, errors = [], []
for number, raw in enumerate(SOURCE.read_text().splitlines(), 1):
    line = raw.strip()
    if not line or line.startswith("# "):
        continue
    if line.startswith("## "):
        uid, title, level, icon = [p.strip() for p in line[3:].split("|")]
        units.append({"id": uid, "title": title, "level": level, "icon": icon,
                      "guide": {"summary": "", "examples": []}, "questions": []})
    elif line.startswith("RULE:"):
        units[-1]["guide"]["summary"] = line[5:].strip()
    elif line.startswith("EX:"):
        french, english = [p.strip() for p in line[3:].split(" = ", 1)]
        units[-1]["guide"]["examples"].append({"french": french, "english": english})
    elif line.startswith("Q:"):
        parts = [p.strip() for p in line[2:].split(" | ")]
        if len(parts) != 6:
            errors.append(f"line {number}: expected 6 parts separated by ' | ', found {len(parts)}")
            continue
        sentence, correct, *wrong, explanation = parts
        unit = units[-1]
        qid = f"{unit['id']}-{len(unit['questions']) + 1:02d}"
        if sentence.count("___") != 1:
            errors.append(f"line {number}: the sentence needs exactly one ___")
        options = [correct] + wrong
        if len(set(options)) != 4:
            errors.append(f"line {number}: the four options must all be different")
        # Shuffle the options the same way every time, so rebuilding doesn't move answers around.
        random.Random(qid).shuffle(options)
        unit["questions"].append({
            "id": qid, "skill": "grammar", "level": unit["level"], "question": sentence,
            "options": options, "correctIndex": options.index(correct), "explanation": explanation,
        })
    else:
        errors.append(f"line {number}: not understood: {line[:40]}")

for unit in units:
    if not unit["guide"]["summary"]:
        errors.append(f"{unit['id']}: missing RULE")
    if len(unit["questions"]) != 10:
        errors.append(f"{unit['id']}: has {len(unit['questions'])} questions instead of 10")

if errors:
    sys.exit("Problems found:\n" + "\n".join(errors))

OUT.mkdir(parents=True, exist_ok=True)
for old in OUT.glob("*.json"):
    old.unlink()
levels = sorted({u["level"] for u in units})
for level in levels:
    questions = [q for u in units if u["level"] == level for q in u["questions"]]
    data = {"id": f"grammar-{level.lower()}", "title": f"Grammar {level}", "kind": "practice", "questions": questions}
    (OUT / f"grammar-{level.lower()}.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")

path = {"units": [{"id": u["id"], "title": u["title"], "level": u["level"], "icon": u["icon"],
                   "guide": u["guide"], "questionIds": [q["id"] for q in u["questions"]]} for u in units]}
(OUT / "parcours.json").write_text(json.dumps(path, ensure_ascii=False, indent=2) + "\n")

answer_positions = [q["correctIndex"] for u in units for q in u["questions"]]
print(f"{len(units)} lessons, {len(answer_positions)} questions across levels {', '.join(levels)}")
print("Correct answer position A/B/C/D:", [answer_positions.count(i) for i in range(4)])
