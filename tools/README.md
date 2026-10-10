# Content tools

Scripts used to turn the reading-test PDFs in `PDFs/Reading/` into the JSON files in
`Allez/Content/Lecture/`. They are not part of the app.

1. `pdftext.swift` rebuilds each PDF page's text in reading order (the PDFs draw text out of order).
2. `convert_reading.py` turns that text into one JSON test file per PDF and reports anything it couldn't read.

```bash
swiftc -O tools/pdftext.swift -o /tmp/pdftext && mkdir -p /tmp/tcf-text /tmp/tcf-json
/tmp/pdftext /tmp/tcf-text PDFs/Reading/*.pdf
python3 -I tools/convert_reading.py /tmp/tcf-text /tmp/tcf-json /tmp/tcf-report.txt
```

Check `/tmp/tcf-report.txt`, then copy the JSON files from `/tmp/tcf-json` into `Allez/Content/Lecture/`.
