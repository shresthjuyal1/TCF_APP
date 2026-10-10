# Content tools

Scripts that build the app's content files. They are not part of the app itself.

## Grammar path (Path tab)
Edit `grammar-source.txt` (one lesson per `##` block: rule card, examples, 10 questions), then run:

```bash
python3 -I tools/build_grammar.py .
```

It writes `Allez/Content/Parcours/` and refuses to build if a question is malformed.

## Vocabulary (Vocab tab)
`vocab-source.txt` lists the words by theme. `vocab-example-translations.tsv` holds each word's
example sentence (taken word for word from the reading tests) and its English translation. Run:

```bash
python3 -I tools/build_vocab.py . --report
```

It writes `Allez/Content/Vocab/` and reports words not found in the tests or examples missing a translation.

## Reading tests (Reading tab)
1. `pdftext.swift` rebuilds each PDF page's text in reading order (the PDFs draw text out of order).
2. `convert_reading.py` turns that text into one JSON test file per PDF and reports anything it couldn't read.

```bash
swiftc -O tools/pdftext.swift -o /tmp/pdftext && mkdir -p /tmp/tcf-text /tmp/tcf-json
/tmp/pdftext /tmp/tcf-text PDFs/Reading/*.pdf
python3 -I tools/convert_reading.py /tmp/tcf-text /tmp/tcf-json /tmp/tcf-report.txt
```

Check `/tmp/tcf-report.txt`, then copy the JSON files from `/tmp/tcf-json` into `Allez/Content/Lecture/`.
