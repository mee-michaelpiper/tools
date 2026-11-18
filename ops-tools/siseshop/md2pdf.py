"""Analyse-Markdown → HTML (Meesenburg-Look) → PDF über Chrome headless.

Aufruf (aus dem Projektordner):
    python3 -m venv .venv && .venv/bin/pip install -r tools/requirements.txt
    python3 ~/repos/tools/ops-tools/siseshop/md2pdf.py ~/repos/Meesenburg.SiseShop.POC/docs/analyse
Ergebnis: <ordner>/pdf/*.pdf. Voraussetzung: Google Chrome; für Mermaid-Diagramme Internetzugang (cdn.jsdelivr.net).
"""
import html
import pathlib
import re
import subprocess
import sys
import tempfile

import markdown

SRC = pathlib.Path(sys.argv[1])
OUT = SRC / "pdf"
OUT.mkdir(exist_ok=True)
TMP = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else pathlib.Path(tempfile.mkdtemp(prefix="md2pdf-"))
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

CSS = """
@page { size: A4; margin: 16mm 14mm 16mm 14mm; }
* { box-sizing: border-box; }
body { font-family: Roboto, Arial, sans-serif; font-size: 9.5pt; line-height: 1.45; color: #131c38; margin: 0; }
.doc-head { border-bottom: 2px solid #1b88ff; padding-bottom: 6px; margin-bottom: 14px; display: flex; justify-content: space-between;
            font-size: 8pt; color: #565656; }
.doc-head b { color: #24366e; font-family: Rubik, Tahoma, sans-serif; font-weight: 500; }
h1, h2, h3, h4 { font-family: Rubik, Tahoma, sans-serif; color: #24366e; break-after: avoid; }
h1 { font-size: 17pt; font-weight: 500; margin: 0 0 10px; }
h2 { font-size: 13pt; font-weight: 500; margin: 20px 0 8px; border-bottom: 1px solid #e7eaee; padding-bottom: 3px; }
h3 { font-size: 11pt; font-weight: 500; margin: 14px 0 6px; }
h4 { font-size: 10pt; font-weight: 500; margin: 12px 0 4px; }
p, li { orphans: 3; widows: 3; }
a { color: #0e6aa8; text-decoration: none; }
code { font-family: "JetBrains Mono", Menlo, Consolas, monospace; font-size: 8pt; background: #f4f6f9; padding: 0 3px; border-radius: 3px;
       overflow-wrap: anywhere; }
pre { background: #f4f6f9; border: 1px solid #e7eaee; border-radius: 6px; padding: 8px 10px; white-space: pre-wrap; overflow-wrap: anywhere;
      font-size: 7.8pt; break-inside: avoid; }
pre code { background: none; padding: 0; }
blockquote { margin: 8px 0; padding: 6px 12px; background: #eceef5; border-left: 3px solid #24366e; color: #131c38; border-radius: 0 6px 6px 0; }
blockquote p { margin: 2px 0; }
table { border-collapse: collapse; width: 100%; margin: 8px 0 12px; font-size: 8pt; }
thead { display: table-header-group; }
tr { break-inside: avoid; }
th { background: #24366e; color: #fff; text-align: left; font-weight: 500; padding: 4px 6px; }
td { border-bottom: 1px solid #e7eaee; padding: 4px 6px; vertical-align: top; overflow-wrap: break-word; hyphens: auto; }
tr:nth-child(even) td { background: #f9fafc; }
hr { border: none; border-top: 1px solid #e7eaee; margin: 14px 0; }
.mermaid { text-align: center; break-inside: avoid; margin: 10px 0; }
"""


def convert(md_path: pathlib.Path) -> pathlib.Path:
    text = md_path.read_text(encoding="utf-8")

    # Mermaid-Blöcke vor dem Markdown-Parser herausnehmen
    mermaids: list[str] = []

    def keep(m: re.Match) -> str:
        mermaids.append(m.group(1))
        return f"\n\nMERMAIDBLOCK{len(mermaids) - 1}\n\n"

    text = re.sub(r"```mermaid\n(.*?)```", keep, text, flags=re.S)

    # Einrückung verschachtelter Listen auf 4er-Schritte bringen (python-markdown erwartet 4 Leerzeichen)
    lines, in_code, in_list, fence_indent = [], False, False, 0
    list_marker = re.compile(r"^(\s*)([-*+]|\d+\.)\s")
    for line in text.split("\n"):
        if line.lstrip().startswith("```"):
            # Codeblöcke in Listen kann python-markdown nicht: Block an den Zeilenanfang holen (mit Leerzeile davor)
            if not in_code:
                fence_indent = len(line) - len(line.lstrip(" "))
                if lines and lines[-1].strip():
                    lines.append("")
            in_code = not in_code
            lines.append(line.lstrip(" "))
            if not in_code:
                lines.append("")
            continue
        if in_code:
            lines.append(line[fence_indent:] if line[:fence_indent].strip() == "" else line)
            continue
        # Listenpunkt direkt nach einem Absatz braucht eine Leerzeile davor
        if list_marker.match(line) and lines and lines[-1].strip() and not list_marker.match(lines[-1]) \
                and not lines[-1].lstrip().startswith("|"):
            prev_indent = len(lines[-1]) - len(lines[-1].lstrip(" "))
            if prev_indent >= len(line) - len(line.lstrip(" ")) or not in_list:
                lines.append("")
        if line.strip():
            n = len(line) - len(line.lstrip(" "))
            if n == 0:
                in_list = bool(list_marker.match(line))
            elif in_list:
                depth = {1: 1, 2: 1, 3: 1, 4: 1, 5: 2, 6: 2, 7: 2, 8: 2, 9: 3, 10: 3}.get(n)
                if depth:
                    line = " " * (4 * depth) + line.lstrip(" ")
        lines.append(line)
    text = "\n".join(lines)

    # Links auf andere Analyse-Dateien zeigen im PDF auf die PDF-Fassung
    text = re.sub(r"\]\((\d\d_[a-z_]+)\.md\)", r"](\1.pdf)", text)

    body = markdown.markdown(text, extensions=["tables", "fenced_code", "sane_lists", "toc"])
    for i, code in enumerate(mermaids):
        body = body.replace(f"<p>MERMAIDBLOCK{i}</p>", f'<pre class="mermaid">{html.escape(code)}</pre>')

    title = re.search(r"^# (.+)$", md_path.read_text(encoding="utf-8"), flags=re.M)
    title = title.group(1) if title else md_path.stem
    mermaid_js = ""
    if mermaids:
        mermaid_js = """<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
<script>mermaid.initialize({ startOnLoad: true, theme: 'neutral', flowchart: { useMaxWidth: true } });</script>"""

    doc = f"""<!doctype html><html lang="de"><head><meta charset="utf-8"><title>{html.escape(title)}</title>
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&family=Rubik:wght@500&display=swap" rel="stylesheet">
<style>{CSS}</style></head><body>
<div class="doc-head"><span><b>Meesenburg · Webshop Sicherheit und Service</b> – Analyse</span><span>Stand 07.10.2026 · vertraulich</span></div>
{body}
{mermaid_js}
</body></html>"""

    html_path = TMP / (md_path.stem + ".html")
    html_path.write_text(doc, encoding="utf-8")
    pdf_path = OUT / (md_path.stem + ".pdf")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--virtual-time-budget=15000", "--run-all-compositor-stages-before-draw",
                    f"--print-to-pdf={pdf_path}", html_path.as_uri()],
                   check=True, capture_output=True, timeout=180)
    return pdf_path


for md in sorted(SRC.glob("*.md")):
    print(convert(md))
