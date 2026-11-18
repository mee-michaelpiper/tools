"""Listen für den Fachbereich nach dem Workshop 29.10.2026 (K-2, S-1, F-08, F-10, F-36.2).

Eingaben (JSON aus Lese-Abfragen der Wawi bzw. des Lesemodells, im Scratchpad):
  l2.out.json  Anlagen-Artikel (Kategorie-Ast Schließanlagen › mechanisch/mechatronisch/elektronisch)
  l4.out.json  alle Konfig-Positionen (pos) und Positionen der Anlagen ohne Shop-Kanal (anlpos)
  l5.out.json  Kategorien mit Shop-Freigabe und Artikelzahlen
  visible_positions.json  Positionen, die vor S-1 im .NET-Shop einzeln sichtbar waren

Aufruf: .venv/bin/python tools/fachbereich_listen.py <scratchpad-verzeichnis>
"""
import csv
import json
import sys
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

SRC = Path(sys.argv[1])
ROOT = Path.home() / "repos/Meesenburg.SiseShop.POC/docs"  # Doku des Shops (Verknüpfung auf ~/repos/sise-docs/shop)
OUT = ROOT / "analyse/workshop/Listen_Fachbereich_2026-10-30.xlsx"
KANAL = "JTL-Shop: sicherheit.meesenburg.com (Shop 5)"

FONT = Font(name="Arial", size=10)
BOLD = Font(name="Arial", size=10, bold=True)
HEAD = Font(name="Arial", size=10, bold=True, color="FFFFFF")
HEAD_FILL = PatternFill("solid", start_color="1F3864")
INPUT_FILL = PatternFill("solid", start_color="FFF2CC")
WARN_FILL = PatternFill("solid", start_color="FCE4D6")


def load(name):
    return json.loads((SRC / name).read_text())


anl = load("l2.out.json")["anl"]
pos_data = load("l4.out.json")
positions, anl_positions = pos_data["pos"], {r["kArtikel"] for r in pos_data["anlpos"]}
cats = {c["kKategorie"]: c for c in load("l5.out.json")["cats"]}
visible = {int(x) for x in load("visible_positions.json")}


def path(cid):
    names, seen = [], set()
    while cid in cats and cid not in seen:
        seen.add(cid)
        names.append(cats[cid]["cName"] or f"#{cid}")
        cid = cats[cid]["kOberKategorie"]
    if cid and cid not in cats:
        names.append(f"[Oberkategorie {cid} existiert nicht mehr]")
    return " › ".join(reversed(names))


def sheet(wb, title, intro, headers, rows, widths, inputs=(), warn=None):
    ws = wb.create_sheet(title)
    ws["A1"] = title
    ws["A1"].font = Font(name="Arial", size=12, bold=True)
    ws["A2"] = intro
    ws["A2"].font = FONT
    ws["A2"].alignment = Alignment(wrap_text=True, vertical="top")
    ws.merge_cells(start_row=2, start_column=1, end_row=2, end_column=len(headers))
    ws.row_dimensions[2].height = 15 * (intro.count("\n") + 2)
    r0 = 3
    if warn:
        ws.cell(r0, 1, warn).font = BOLD
        ws.cell(r0, 1).fill = WARN_FILL
        ws.cell(r0, 1).alignment = Alignment(wrap_text=True, vertical="top")
        ws.merge_cells(start_row=r0, start_column=1, end_row=r0, end_column=len(headers))
        ws.row_dimensions[r0].height = 15 * (warn.count("\n") + 2)
        r0 += 1
    hr = r0 + 1
    for c, h in enumerate(headers, 1):
        cell = ws.cell(hr, c, h)
        cell.font, cell.fill = HEAD, HEAD_FILL
        cell.alignment = Alignment(wrap_text=True, vertical="center")
    for i, row in enumerate(rows, hr + 1):
        for c, v in enumerate(row, 1):
            cell = ws.cell(i, c, v)
            cell.font = FONT
            cell.alignment = Alignment(vertical="top", wrap_text=isinstance(v, str) and len(v) > 40)
            if headers[c - 1] in inputs:
                cell.fill = INPUT_FILL
    for c, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(c)].width = w
    ws.freeze_panes = ws.cell(hr + 1, 1)
    ws.auto_filter.ref = f"A{hr}:{get_column_letter(len(headers))}{hr + max(len(rows), 1)}"
    return ws


wb = Workbook()
info = wb.active
info.title = "Anleitung"
lines = [
    ("Listen für den Fachbereich – Workshop 29.10.2026", True),
    ("Stand 30.10.2026, erstellt aus der JTL-Wawi (nur lesend) und dem .NET-Shop.", False),
    ("", False),
    ("Gelb hinterlegte Spalten sind zum Ausfüllen. Bitte keine Zeilen löschen, damit die Liste wieder eingelesen werden kann.", False),
    ("Verkaufskanal des Shops in der Wawi: " + KANAL, False),
    ("", False),
    ("Blätter", True),
    ("K-2 Kanal Konfigurator – Artikel, die dem neuen Verkaufskanal „Konfigurator“ zugeordnet werden sollen", False),
    ("S-1 Konfig-Positionen – alle Artikel, die Position im Konfigurator sind: ab jetzt nie einzeln im Shop; einzeln gewünschte Artikel neu anlegen", False),
    ("F-08 Dummy-Artikel – Hilfsartikel im Shop-Kanal (Achtung: sind Konfig-Positionen)", False),
    ("F-10a Alte Kategorien – Kategorien der alten Videoüberwachung, im Shop nicht sichtbar", False),
    ("F-10b Kategorien ohne Menü – im Shop freigegeben, aber eine Oberkategorie nicht: erscheinen nicht im Menü", False),
    ("F-36.2 Schlüsselcode – Systeme ohne Position „Schlüsselcode“ (Zuschlag je Schlüssel fehlt)", False),
]
for i, (t, b) in enumerate(lines, 1):
    info.cell(i, 1, t).font = BOLD if b else FONT
info.column_dimensions["A"].width = 140

# K-2: Anlagen-Zylinder und ihre Positionen ohne Shop-Kanal
pos_by_id = {r["kArtikel"]: r for r in positions}
rows = [[r["cArtNr"], r["cName"], "Anlagen-Zylinder", r["system"], r["technik"], round(r["vk_netto"] or 0, 2), "nein", "dem Kanal „Konfigurator“ zuordnen", ""]
        for r in sorted(anl, key=lambda r: (r["system"] or "", r["cArtNr"]))]
rows += [[p["cArtNr"], p["cName"], "Position (Code, Schlüssel …)", p["gruppen"], "", round(p["vk_netto"] or 0, 2), "nein", "dem Kanal „Konfigurator“ zuordnen", ""]
         for p in sorted((pos_by_id[k] for k in anl_positions if k in pos_by_id), key=lambda p: p["cArtNr"])]
sheet(wb, "K-2 Kanal Konfigurator",
      "Entscheidung K-2: eigener Verkaufskanal „Konfigurator“ in der Wawi. Diese Artikel braucht der Schließanlagen-Konfigurator; heute ist keiner einem Shop zugeordnet.\n"
      "Bitte den Kanal anlegen, alle Zeilen zuordnen und abhaken. Nicht dem Shop-Kanal zuordnen – sonst erscheinen sie einzeln im Shop.",
      ["Artikelnummer", "Name", "Art", "System / Konfig-Gruppen", "Technik", "VK netto €", "heute im Shop-Kanal", "Aktion", "Erledigt (Datum, Kürzel)"],
      rows, [16, 60, 22, 40, 12, 11, 12, 30, 18], inputs=["Erledigt (Datum, Kürzel)"])

# S-1: alle aktiven Konfig-Positionen
rows = []
for p in sorted((p for p in positions if p["cAktiv"] == "Y"), key=lambda p: (-(p["kArtikel"] in visible), p["cArtNr"])):
    rows.append([p["cArtNr"], p["cName"], p["gruppen"], p["hauptartikel"], round(p["vk_netto"] or 0, 2),
                 "ja" if p["im_shop"] else "nein", "ja" if p["kArtikel"] in visible else "nein", "", ""])
sheet(wb, "S-1 Konfig-Positionen",
      "Entscheidung S-1: Artikel, die Position einer Konfigurationsgruppe sind, zeigt der Shop nie einzeln (nur im Konfigurator). Umgesetzt am 30.10.2026.\n"
      "Bitte prüfen, welche davon auch einzeln verkauft werden sollen (z. B. Pflegespray, Nachschlüssel): diese als eigenen Artikel neu anlegen. Zuerst die Zeilen mit „bisher einzeln sichtbar = ja“ ansehen (oben einsortiert).",
      ["Artikelnummer", "Name", "Konfig-Gruppen", "Anzahl Hauptartikel", "VK netto €", "im Shop-Kanal", "bisher einzeln sichtbar", "einzeln verkaufen? (ja/nein)", "neue Artikelnummer"],
      rows, [16, 55, 45, 11, 11, 11, 12, 16, 18], inputs=["einzeln verkaufen? (ja/nein)", "neue Artikelnummer"],
      warn="Wichtig: Positionen NICHT aus dem Shop-Kanal nehmen. Der kleine Konfigurator auf der Artikelseite zeigt nur Positionen, die im Shop-Kanal sind (wie der JTL-Shop).")

# F-08: Dummy-Artikel
dummies = [p for p in positions if "dummy" in (p["cName"] or "").lower() and p["im_shop"]]
rows = [[p["cArtNr"], p["cName"], round(p["vk_netto"] or 0, 2), KANAL, p["gruppen"], p["hauptartikel"],
         "im Kanal lassen (Position im kleinen Konfigurator); einzeln nicht mehr sichtbar durch S-1", ""] for p in dummies]
sheet(wb, "F-08 Dummy-Artikel",
      "Entscheidung F-08: Dummy-Artikel aus dem Shop-Kanal nehmen. Prüfung 30.10.2026: Die drei Dummy-Artikel im Shop-Kanal sind Positionen „Füllstück“ im kleinen Konfigurator.",
      ["Artikelnummer", "Name", "VK netto €", "Verkaufskanal", "Konfig-Gruppen", "Anzahl Hauptartikel", "Empfehlung IT", "Entscheidung"],
      rows, [16, 45, 11, 40, 35, 12, 60, 25], inputs=["Entscheidung"],
      warn="Aus dem Shop-Kanal genommen, fehlen sie als Auswahl „Dummy / Füllstück“ bei den genannten Zylindern. Einzeln sind sie seit S-1 ohnehin nicht mehr sichtbar.")

# F-10a: alte Videoüberwachung (Liste vom 10.10.)
with open(ROOT / "analyse/anhang/jtl_kategorien_nicht_gelistet_2026-10-10.csv", encoding="utf-8") as f:
    old = list(csv.DictReader(f, delimiter=";"))
rows = []
for o in old:
    cid = int(o["Id"])
    c = cats.get(cid, {})
    rows.append([cid, o["Name"], path(cid), "ja" if c.get("cAktiv") == "Y" else "nein", "ja" if c.get("im_shop") else "nein",
                 c.get("art", ""), c.get("art_shop", ""),
                 "löschen, wenn 0 Artikel im Shop; sonst Artikel umhängen und dann löschen", ""])
sheet(wb, "F-10a Alte Kategorien",
      "Kategorien der alten Videoüberwachung (Eyseo/Eytron …). Im Shop nicht sichtbar, der .NET-Shop blendet sie aus (Entscheidung F-10 B). Bereinigung freiwillig.\n"
      "Pfad = vollständiger Weg in der Wawi-Kategorieverwaltung. „Artikel im Shop“ = aktive Artikel im Shop-Kanal in genau dieser Kategorie.",
      ["Kategorie-Nr (kKategorie)", "Name", "Pfad in der Wawi", "aktiv", "im Shop freigegeben", "Artikel gesamt", "Artikel im Shop", "Vorschlag", "Erledigt"],
      rows, [12, 30, 70, 8, 12, 10, 10, 50, 15], inputs=["Erledigt"])

# F-10b: im Shop freigegeben, aber eine Oberkategorie nicht
rows = []
for cid, c in cats.items():
    if not c["im_shop"] or c["cAktiv"] != "Y":
        continue
    parent, blocker = c["kOberKategorie"], None
    while parent in cats:
        if not cats[parent]["im_shop"] or cats[parent]["cAktiv"] != "Y":
            blocker = parent
        parent = cats[parent]["kOberKategorie"]
    if blocker:
        b = cats[blocker]
        rows.append([cid, c["cName"], path(cid), blocker, b["cName"], "nicht freigegeben" if not b["im_shop"] else "inaktiv",
                     c["art"], c["art_shop"], "", ""])
rows.sort(key=lambda r: r[2])
sheet(wb, "F-10b Kategorien ohne Menü",
      "Diese Kategorien sind für den Shop freigegeben, aber eine Oberkategorie nicht (Spalte „blockiert durch“). Darum erscheinen sie nicht im Menü.\n"
      "Je Zeile entscheiden: Oberkategorie freigeben, Kategorie umhängen, oder Freigabe der Kategorie entfernen. Viele sind Konfigurator-Hilfskategorien (Längen, Färbung) – die bleiben unsichtbar.",
      ["Kategorie-Nr", "Name", "Pfad in der Wawi", "blockiert durch Nr", "blockiert durch Name", "Grund", "Artikel gesamt", "Artikel im Shop", "Entscheidung (freigeben / umhängen / Freigabe entfernen / so lassen)", "Erledigt"],
      rows, [12, 30, 70, 12, 28, 16, 10, 10, 30, 14], inputs=["Entscheidung (freigeben / umhängen / Freigabe entfernen / so lassen)", "Erledigt"])

# F-36.2: Systeme ohne Schlüsselcode-Position
# Anlagen-Zylinder mit Schlüsselcode-Gruppe je System (Lesemodell, 30.10.2026)
WITH_KEY_CODE = {"Keso 6000FP2": 14, "Keso 8000 O²": 34, "Keso 8000 O³": 5}
by_system = {}
for r in anl:
    by_system.setdefault(r["system"], []).append(r["kArtikel"])
rows = [[system, len(ids), WITH_KEY_CODE.get(system, 0), "", ""] for system, ids in sorted(by_system.items())]
sheet(wb, "F-36.2 Schlüsselcode",
      "Entscheidung F-36.2: Bei Anlagen Typ D/E/F wird der Schlüsselcode je Schlüssel berechnet. In der Wawi hängt die Position (Gruppe „Schlüsselfunktion“ bzw. „Schlüssel Schließfunktion“) nur an Keso-Zylindern.\n"
      "Stand 30.10.2026: Keso 6000FP2 14/14, Keso 8000 O² 34/35, Keso 8000 O³ 5/30, alle anderen 0. Ohne die Position berechnet der Shop keinen Zuschlag.",
      ["System", "Anlagen-Zylinder", "davon mit Schlüsselcode-Position", "Soll ein Schlüsselcode-Zuschlag berechnet werden? (ja/nein)", "Erledigt in der Wawi"],
      rows, [30, 16, 18, 40, 20], inputs=["Soll ein Schlüsselcode-Zuschlag berechnet werden? (ja/nein)", "Erledigt in der Wawi"])

OUT.parent.mkdir(parents=True, exist_ok=True)
wb.save(OUT)
print(OUT, {ws.title: ws.max_row for ws in wb})
