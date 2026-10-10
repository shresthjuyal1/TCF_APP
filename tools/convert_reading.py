"""Convert extracted TCF reading-test text (from pdftext) into the app's JSON format.

Usage: python3 -I convert.py <text_dir> <out_dir> <report_path>
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

TEXT_DIR, OUT_DIR, REPORT = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])

QUESTION_HEADER = re.compile(r"^Q(\d+) (skipped|correct|wrong)$")
LEVEL = re.compile(r"^(A1|A2|B1|B2|C1|C2)$")
OPTION = re.compile(r"^([A-D])\. ?(.*)$")
NOISE = [
    re.compile(p) for p in [
        r"^fuck-tcf", r"^\d+/\d+/\d+, \d+:\d+ [AP]M", r"^https?://", r"^===== PAGE \d+ =====$",
        r"^Most Voted$", r"^COMMUNITY VOTE$", r"^DISTRIBUTION$", r"^COMMUNITY VOTE DISTRIBUTION$",
        r"^out of \d+ votes?$", r"^What do you think is correct\?$", r"^[A-D]$", r"^[A-D]( [A-D])+$",
        r"^FULL BREAKDOWN$", r"^([A-D] \(\d+%\) ?)+$", r"^_$", r"^_\d+$", r"^\d+$", r"^Sub$", r"^mit$", r"^Submit$",
        r"^(- )+-$", r"^-$", r"^Test _?$", r"^Test ended early$", r"^[A-D]?( ?[A-D])* ?Submit$",
    ]
]
WORD = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿŒœ]+")

EN_WORDS = set("the a an is are was were he she it they to of and for with his her their this that what does do did in on at be by has have not you your we will from about which who how why can should would there these those its as or but if than more most into".split())
FR_WORDS = set("le la les un une des du de est sont il elle ils elles à au aux et pour avec son sa ses leur leurs ce cette ces que qui quoi en dans sur pas ne vous nous plus être a ont été y se sa".split())


FIXES = {"EddyMitchell": "Eddy Mitchell", "d'éditionLivresque": "d'édition Livresque", "lePetit": "le Petit"}


def clean(line):
    line = re.sub(r"\s*COMMUNITY VOTE DISTRIBUTION\s*", " ", line)
    line = re.sub(r"\s*⚠\s*DISPUTED\s*", " ", line)
    line = line.replace("？", " ?").replace("！", " !")
    line = re.sub(r"\s*\(\d+%\)", "", line)
    # Printing glitch: a repeated accent after a final "é", e.g. "cadeau.u.u.u." or "restauré .é .é .é ."
    line = re.sub(r"(\w)(?:\.\1){3,}", r"\1", line)
    line = re.sub(r"(\s\.é)+\s\.$", ".", line)
    for bad, good in FIXES.items():
        line = line.replace(bad, good)
    return re.sub(r"\s{2,}", " ", line).strip()


def tidy(text):
    """Final clean-up on joined text: printing glitches like "cadeau.u.u.u." and stray spaces before full stops."""
    text = re.sub(r"(\w)(?:\s?\.\s?\1){3,}\s?\.?", r"\1.", text)
    text = re.sub(r"(\w)\.\.(?=\s|$|\")", r"\1.", text)
    return text


def tidy_fields(question):
    for key in ("passage", "question", "questionTranslation"):
        if key in question:
            question[key] = tidy(question[key])
    for key in ("options", "optionTranslations"):
        if key in question:
            question[key] = [tidy(o) for o in question[key]]


def is_noise(line):
    return any(p.match(line) for p in NOISE)


def english_score(text):
    words = [w.lower() for w in WORD.findall(text)]
    if not words:
        return 0
    en = sum(w in EN_WORDS for w in words)
    # Accents count as French only in lowercase words, so names like "Héloïse" don't make English look French.
    accented = sum(1 for w in WORD.findall(text) if w[0].islower() and re.search(r"[àâçéèêëîïôûùüÿœ]", w))
    fr = sum(w in FR_WORDS for w in words) + 2 * accented + 2 * len(re.findall(r" [?:!;]$|[«»’]", text))
    return en - fr


def is_english(text):
    return english_score(text) > 0


def raw_lines(path):
    return [l.strip() for l in path.read_text().splitlines()]


# ---- Pass 1: learn the vocabulary from words that were never split (not at a line edge). ----
vocab = Counter()
files = sorted(TEXT_DIR.glob("*.txt"), key=lambda p: (p.stem != "Overflow", int(re.sub(r"\D", "", p.stem) or 0)))
for path in files:
    for line in raw_lines(path):
        words = WORD.findall(line)
        for w in words[1:-1]:
            vocab[w.lower()] += 1


def known(word):
    return vocab[word.lower()] > 0


def repair(lines):
    """Glue back words that the PDF split across lines (e.g. 'possi' / 'b' / 'le')."""
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        while i + 1 < len(lines):
            nxt = lines[i + 1]
            if not nxt:
                break
            # Punctuation and apostrophes that start a line always belong to the previous word.
            if re.match(r"^[.,;:!?)’'»]", nxt) and not re.match(r"^[A-D]\.", nxt) and line and not line.endswith(("?", "!")):
                glue = "" if nxt[0] in ".,)’'" else " "
                line = line + glue + nxt
                i += 1
                continue
            last = WORD.findall(line[-30:])
            if not last or not re.search(r"[A-Za-zÀ-ÿ]$", line):
                break
            last = last[-1]
            # Try joining the next 1-3 lines' leading fragments.
            joined, used, ok = last, 0, False
            rest_line = None
            for k in range(1, 4):
                if i + k >= len(lines):
                    break
                frag_line = lines[i + k]
                m = re.match(r"^([a-zà-ÿœ]+)(.*)$", frag_line)
                if not m:
                    break
                joined += m.group(1)
                if known(joined) and (not known(last) or vocab[joined.lower()] >= vocab[last.lower()] or not known(m.group(1))):
                    used, ok, rest_line = k, True, m.group(2)
                    break
                if m.group(2):  # fragment line continues with more words; stop extending
                    break
            if not ok:
                break
            # Build the merged line: previous line + glued fragments + remainder of the last fragment line.
            pieces = "".join(re.match(r"^([a-zà-ÿœ]+)", lines[i + k]).group(1) for k in range(1, used + 1))
            line = line + pieces + rest_line
            i += used
        out.append(line)
        i += 1
    return out


def reflow(lines):
    """Join visually wrapped lines into paragraphs, keeping deliberate short lines (greetings, signatures)."""
    if not lines:
        return ""
    width = max(len(l) for l in lines)
    text = lines[0]
    for prev, line in zip(lines, lines[1:]):
        wrapped = len(prev) > 0.6 * width and not re.search(r"[.!?:»]$", prev)
        text += (" " if wrapped else "\n") + line
    return text.strip()


def split_fr_en(lines):
    """Split a block of lines into the French part followed by its English translation."""
    if len(lines) <= 1:
        return lines, []
    best = None
    for k in range(1, len(lines)):
        fr, en = " ".join(lines[:k]), " ".join(lines[k:])
        score = english_score(en) - english_score(fr)
        ratio = len(fr) / max(len(en), 1)
        penalty = abs(ratio - 1.15)
        key = (score, -penalty)
        if best is None or key > best[0]:
            best = (key, k)
    k = best[1]
    return lines[:k], lines[k:]


def parse_question(block, test_no, report):
    qnum = int(QUESTION_HEADER.match(block[0]).group(1))
    disputed = any("DISPUTED" in l for l in block)
    block = [clean(l) for l in block]
    block = [l for l in block if l]
    qid = f"t{test_no:02d}-q{qnum:02d}" if test_no else f"overflow-q{qnum:02d}"
    body = block[1:]
    # Cut the explanation area, if present.
    expl_lines, vocab_items = [], []
    for idx, l in enumerate(body):
        if re.match(r"^KEY LINE$", l) or re.match(r"^WHY [A-D] IS CORRECT$", l):
            tail = body[idx:]
            body = body[:idx]
            mode = None
            for t in tail:
                if re.match(r"^WHY [A-D] IS CORRECT$", t):
                    mode = "why"; continue
                if t == "VOCABULARY":
                    mode = "vocab"; continue
                if t == "KEY LINE":
                    mode = "key"; continue
                if mode == "why":
                    expl_lines.append(t)
                elif mode == "vocab":
                    vocab_items += re.findall(r"\[\s*([^,\]]+?),\s*([^\]]+?)\s*\]", t)
            break
    if not body or not LEVEL.match(body[0]):
        report.append(f"{qid}: no level found"); return None
    level = body[0]
    body = body[1:]
    if body and body[0] == "PASSAGE TEXT":
        body = body[1:]
    opt_starts = [i for i, l in enumerate(body) if OPTION.match(l)]
    letters_seen = [OPTION.match(body[i]).group(1) for i in opt_starts]
    if sorted(set(letters_seen)) != ["A", "B", "C", "D"] or len(opt_starts) != 4:
        report.append(f"{qid}: expected options A-D, found {letters_seen}"); return None
    head = body[:opt_starts[0]]
    # English question = trailing English lines of the head; French question = lines before it.
    en_q = []
    # French puts a space before "?" and ":"; English doesn't. The English question follows the French one.
    french_end = [i for i, l in enumerate(head) if re.search(r"([ \u00a0\u202f][?:]|…)$", l)]
    if french_end and 1 <= len(head) - 1 - french_end[-1] <= 3:
        en_q = head[french_end[-1] + 1:]
        head = head[:french_end[-1] + 1]
    else:
        while head and is_english(head[-1]):
            en_q.insert(0, head.pop())
    if not en_q:
        report.append(f"{qid}: couldn't find the English question"); return None
    en_len = len(" ".join(en_q))
    best_k, best_pen = 1, None
    for k in range(1, min(4, len(head)) + 1):
        fr_len = len(" ".join(head[-k:]))
        pen = abs(fr_len / max(en_len, 1) - 1.15)
        if best_pen is None or pen < best_pen - 0.05:
            best_k, best_pen = k, pen
    fr_q = head[-best_k:]
    passage_lines = head[:-best_k]
    options = {}
    for n, start in enumerate(opt_starts):
        end = opt_starts[n + 1] if n + 1 < len(opt_starts) else len(body)
        m = OPTION.match(body[start])
        lines = [m.group(2)] + body[start + 1:end]
        lines = [l for l in lines if l]
        options[m.group(1)] = lines
    correct = [L for L, ls in options.items() if any("✓" in l for l in ls)]
    if len(correct) != 1:
        report.append(f"{qid}: found {len(correct)} answers marked ✓"); return None
    fr_opts, en_opts = {}, {}
    for L, ls in options.items():
        ls = [l.replace("✓", "").strip() for l in ls]
        ls = [l for l in ls if l]
        fr, en = split_fr_en(ls)
        fr_opts[L] = re.sub(r"\s+([.,])", r"\1", " ".join(fr)).strip()
        en_opts[L] = " ".join(en).strip()
    # Fix the case where the ✓ option's translation was printed under another option.
    empty = [L for L in "ABCD" if not en_opts[L]]
    if empty:
        for L in "ABCD":
            ls = en_opts[L]
            parts = [p for p in re.split(r"(?<=[.?!])\s+(?=[A-Z])", ls) if p]
            if len(empty) == 1 and len(parts) == 2 and L != empty[0]:
                en_opts[L], en_opts[empty[0]] = parts[0], parts[1]
                break
    option_translations = [en_opts[L] for L in "ABCD"] if all(en_opts[L] for L in "ABCD") else None
    if any(not fr_opts[L] for L in "ABCD"):
        report.append(f"{qid}: an option is empty"); return None
    question = {
        "id": qid,
        "skill": "reading",
        "level": level,
    }
    passage = reflow(passage_lines)
    if passage:
        question["passage"] = passage
    question["question"] = " ".join(fr_q)
    question["questionTranslation"] = " ".join(en_q)
    question["options"] = [fr_opts[L] for L in "ABCD"]
    if option_translations:
        question["optionTranslations"] = option_translations
    question["correctIndex"] = "ABCD".index(correct[0])
    if disputed:
        question["answerDisputed"] = True
    if expl_lines:
        question["explanation"] = " ".join(expl_lines)
    if vocab_items:
        question["vocabulary"] = [{"french": f.strip(), "english": e.strip()} for f, e in vocab_items]
    tidy_fields(question)
    if not passage:
        report.append(f"{qid}: warning — no passage text")
    if not option_translations:
        report.append(f"{qid}: warning — option translations dropped (couldn't match them up)")
    return question


report = []
summary = []
OUT_DIR.mkdir(parents=True, exist_ok=True)
for path in files:
    lines = [l for l in raw_lines(path) if l and not is_noise(l)]
    # Text is rebuilt in reading order by pdftext3, so split words are already joined.
    starts = [i for i, l in enumerate(lines) if QUESTION_HEADER.match(l)]
    test_no = int(re.sub(r"\D", "", path.stem)) if path.stem != "Overflow" else 0
    questions = []
    for n, s in enumerate(starts):
        e = starts[n + 1] if n + 1 < len(starts) else len(lines)
        q = parse_question(lines[s:e], test_no, report)
        if q:
            questions.append(q)
    expected = 8 if test_no == 0 else 39
    if test_no:
        data = {
            "id": f"tcf-lecture-{test_no:02d}",
            "title": f"Test {test_no}",
            "kind": "test",
            "timeLimitMinutes": 60,
            "questions": questions,
        }
        name = f"lecture-test-{test_no:02d}.json"
    else:
        data = {
            "id": "tcf-lecture-supplement",
            "title": "Questions supplémentaires",
            "kind": "practice",
            "questions": questions,
        }
        name = "lecture-supplement.json"
    (OUT_DIR / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    summary.append(f"{path.stem}: {len(questions)}/{expected}")

REPORT.write_text("\n".join(summary) + "\n\nPROBLEMS\n" + "\n".join(report) + "\n")
print("\n".join(summary))
print(f"\n{len([r for r in report if 'warning' not in r])} errors, {len([r for r in report if 'warning' in r])} warnings")
