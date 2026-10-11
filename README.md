# 🇫🇷 Allez! — TCF French Exam Prep

A playful, Duolingo-style iOS app built to prepare for the **TCF (Test de connaissance du français)**, with the goal of reaching **B2**. It's a personal study app that works completely offline, with all content bundled inside it.

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![Python](https://img.shields.io/badge/content%20pipeline-Python-yellow)

---

## ✨ Features

### 🗺️ Grammar path
- **44 lessons** taking you from **A1 to C1**: être/avoir and articles → passé composé, imparfait, subjonctif, *si* clauses → passé simple.
- Each lesson starts with a **rule card** (explanation plus French examples with pronunciation), then **10 exercises** with explanations.
- Lessons unlock in order, and the first lesson of every level is always open, so you can jump ahead.
- Finished lessons **glow gold**, the trail lights up, and level banners track progress.

### 📖 Reading
- **40 full timed mock tests** (39 questions, 60 minutes), in the same format and level mix as the real exam.
- **Practice mode**: 10 random questions from **898 unique questions**, filterable by level (A1–C2).
- English translations of the passage, question and answers (practice mode only).
- Results show your score, an estimated CEFR level, results per level, and an answer review.

### 📚 Vocabulary
- **611 words in 14 themes** (Work, Environment, Admin, Ideas & arguments, Linking words…), chosen by **frequency analysis of the reading passages**.
- Each word has its article and gender, a level tag, and a **real example sentence from the tests** with its translation.
- Built-in French text-to-speech, plus quizzes in **both directions** (French → English / English → French).

### 🔥 Motivation
- **Daily streak**: 10 minutes of practice a day, a weekly flame calendar, and **one automatic streak freeze per week**.
- Daily reminder notification, skipped once the day's practice is done.
- Personal greeting, goal level vs. current level, and a countdown to the exam date.
- Sound effects generated in code (no audio files), which respect the silent switch and can be muted in Settings.
- 🥖 **15 hidden French easter eggs** along the path. Try tapping the Eiffel Tower ten times.

---

## 🛠️ Tech stack

| Area | Tools |
|---|---|
| App | Swift, SwiftUI, Observation, AVFoundation (speech + synthesized audio), UserNotifications |
| Data | JSON content files, UserDefaults for progress |
| Content pipeline | Python, Swift + PDFKit, macOS spell checker (NSSpellChecker) |
| Workflow | Xcode, Git, GitHub |

No third-party packages.

---

## 🧪 Content pipeline

All learning content lives in JSON files, so it can be updated without touching app code.

```
41 PDF practice tests ──► text rebuilt by page coordinates ──► parsed & validated ──► 40 JSON tests
                                                                     │
reading passages ──► word frequency analysis ──► curated vocabulary ─┘──► 611 words + real examples
grammar-source.txt ──► build script with validation ──► 44 lessons / 440 questions
```

- **Extraction:** the PDFs drew text out of order, so each page is rebuilt from the text's positions (`tools/pdftext.swift`).
- **Parsing & validation:** every question is checked for a level, a passage, the question, 4 options, exactly one answer and translations. All **1,568** questions pass. Questions repeated across tests are deduplicated to **898** for practice mode.
- **Data quality:** a spell-checker-based scan flagged 226 suspect words. Manual review confirmed **73 corrections across 12 tests**; names, brands and URLs were left untouched.
- **Verification:** every vocabulary example is checked to appear word for word in the source passages, and a stress test of **90,000 generated quiz questions** found zero questions with two correct answers.

See [`tools/README.md`](tools/README.md) for the commands.

---

## 📁 Project structure

```
Allez/
├── AllezApp.swift          App entry point and bar styling
├── Models/                 Questions, content loading, progress, streak, reminders
├── Views/                  Path, lessons, tests, vocab, streak, settings, easter eggs
├── Theme/                  Colors, button styles, sound effects, French voice
└── Content/                JSON content: Parcours (grammar), Lecture (reading), Vocab
tools/                      Content-building scripts (Python + Swift)
tcf-app-spec-v2.md          Original product spec and roadmap
```

---

## 🚀 Running it

1. Open `Allez.xcodeproj` in Xcode (iOS 17+).
2. Under **Signing & Capabilities**, choose your own team.
3. Pick an iPhone and press **▶**.

> The source PDFs are not included in the repository (`PDFs/` is git-ignored).

---

## 🗺️ Roadmap

- [x] Grammar path, reading tests, vocabulary
- [x] Streak, reminders, progress saving, sound effects
- [ ] Listening practice with audio
- [ ] Mistake review with spaced repetition and a stats screen
- [ ] Writing practice (word counter, checklist, model answers)
- [ ] Speaking practice (record, compare, transcript)
- [ ] Full mock exam across all sections
- [ ] "Why this answer is correct" explanations for the reading questions

---

*A personal learning project. Built with the help of [Claude Code](https://claude.com/claude-code).*
