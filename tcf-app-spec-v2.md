# TCF Prep App — Spec (for Claude Code)

## Goal
A personal-use iOS app (SwiftUI) with a Duolingo-style interface that prepares me for the French TCF exam. I am not a developer, so please explain what you are doing in plain language, keep the project simple, and make sure it builds and runs in Xcode after every step.

## About me / constraints
- Current level: A2 / borderline B1. Target: at least B2 on the TCF.
- Devices: M1 MacBook Air (latest macOS, Xcode) and iPhone 15 (latest iOS).
- Personal testing app only. No App Store release, no accounts, no backend.
- Everything works offline; all content is bundled inside the app.
- Sessions of 15-20 minutes, like Duolingo.

## Tech choices
- Swift + SwiftUI, iOS 17 or later.
- SwiftData (or simple JSON files in Documents) for progress. No third-party packages unless really needed.
- Questions live in JSON files inside the app bundle so content can be added without changing code.
- Audio for listening questions: bundled audio files. Text-to-speech (AVSpeechSynthesizer, fr-FR) for vocabulary and as a fallback.

## Skills to cover (the TCF sections)
1. Compréhension écrite (reading): passage + multiple choice.
2. Compréhension orale (listening): audio + multiple choice, with replay.
3. Maîtrise des structures de la langue (grammar/vocab): short multiple-choice / fill-in-the-blank.
4. Expression écrite (writing): prompt, text box, word counter, then a self-check checklist and a model answer to compare with.
5. Expression orale (speaking): prompt, record myself, play it back next to a model answer; optional on-device French speech recognition to show a transcript.

## App structure
- Home: a path of units (Duolingo-style), locked until the previous one is done. Units are grouped by CEFR level (A2 to B1 to B2).
- Lesson flow: question, answer, instant feedback (green/red) with a short explanation, progress bar at the top. A lesson is about 10-15 questions.
- Mistakes feed a "Review" lesson (spaced repetition: missed questions come back later).
- Mock exam mode: timed mini-test in TCF format, with a score and a rough level estimate at the end.
- Stats screen: accuracy per skill, so I can see my weak areas.

## Motivation features
- Daily streak with a flame, plus streak freeze (one per week).
- XP per correct answer and a daily goal (default 20 XP, adjustable).
- Daily reminder notification at a time I choose.
- Badges (first lesson, 7-day streak, 100 correct answers, first mock exam...).
- Short celebration animation and haptics at the end of a lesson.

## Content (for later)
- Do NOT worry about real content yet. Build the app with a small set of made-up sample questions (about 10-20, a mix of skills and levels) so every feature can be tested.
- Design the question model so that real content can be dropped in later as JSON files without code changes. A question needs at least: id, skill, level, optional passage, optional audio file name, question, options, correct answer index, optional explanation. Add optional fields where useful (for example English translations, vocabulary).
- Once the app works, ask me about content and how I want to add it.

## Build order (ask me to test after each step)
1. Empty app with the unit path, one lesson of 10 sample questions, feedback and progress bar.
2. Load questions from JSON; reading and grammar question types.
3. Listening questions with audio.
4. XP, streak, daily goal, and progress saving.
5. Notifications and badges.
6. Review mode (mistakes) and stats screen.
7. Writing and speaking practice.
8. Mock exam mode.

## Design
- Clean, friendly, rounded cards, large tap targets, bright accent color, supports dark mode.
- Mimic the Duolingo feel (path, bottom feedback bar, bouncy buttons) but with original artwork, names, and colors. No Duolingo assets.

## First step for you, Claude Code
Before writing code, read this spec and ask me any questions that would change the design. Then create the Xcode project and complete build step 1.
