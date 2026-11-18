"""Erzeugt die Workshop-Dateien (analyse/workshop/):
  1. Workshop_Offene_Fragen.xlsx  – alle offenen Fragen zu Shop, Wawi und Konfigurator (aus Bericht 16 + neue Punkte)
  2. Wawi_Datenfehler.xlsx        – bekannte Datenfehler in der Wawi mit Detaillisten
Aufruf: .venv/bin/python tools/workshop_dateien.py <wawi_fehler.json> <orphans.json> [bilder.json] [rabatt_diff.json]
Die JSON-Dateien kommen aus dem .NET-Lesemodell (Mongo-Abfrage bzw. /api/v1/admin/checks/categories/orphans)."""
import json
import re
import sys
from pathlib import Path

from openpyxl import Workbook
from openpyxl.comments import Comment
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

ROOT = Path.home() / "repos/Meesenburg.SiseShop.POC/docs"  # Doku des Shops (Verknüpfung auf ~/repos/sise-docs/shop)
OUT = ROOT / "analyse" / "workshop"
STAND = "27.10.2026"

FONT = Font(name="Arial", size=10)
BOLD = Font(name="Arial", size=10, bold=True)
HEAD = Font(name="Arial", size=10, bold=True, color="FFFFFF")
HEAD_FILL = PatternFill("solid", fgColor="1F2A4F")
INPUT_FILL = PatternFill("solid", fgColor="FFF8D6")     # Eingabefelder für den Workshop
DONE_FILL = PatternFill("solid", fgColor="EEF5EE")
THIN = Side(style="thin", color="D0D4DC")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
WRAP = Alignment(wrap_text=True, vertical="top")


def table(ws, headers, rows, widths, input_cols=(), freeze="C2"):
    ws.append(headers)
    for c in ws[1]:
        c.font, c.fill, c.alignment, c.border = HEAD, HEAD_FILL, Alignment(wrap_text=True, vertical="center"), BORDER
    for r in rows:
        ws.append(r)
    for row in ws.iter_rows(min_row=2, max_row=ws.max_row):
        for c in row:
            c.font, c.alignment, c.border = FONT, WRAP, BORDER
            if c.column in input_cols:
                c.fill = INPUT_FILL
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = freeze
    ws.auto_filter.ref = ws.dimensions
    ws.row_dimensions[1].height = 30


def dropdown(ws, col, values, rows=500):
    dv = DataValidation(type="list", formula1='"' + ",".join(values) + '"', allow_blank=True)
    ws.add_data_validation(dv)
    dv.add(f"{col}2:{col}{rows}")


# ----------------------------------------------------------------------------------------------
# 1. Offene Fragen
# ----------------------------------------------------------------------------------------------

def parse_questions():
    text = (ROOT / "analyse" / "16_fragen_fachbereich.md").read_text(encoding="utf-8")
    # Auswertung (Stand, Vorschlag) aus der Tabelle „Was JTL-Shop und Trello schon beantworten“
    evaluation = {}
    for m in re.finditer(r"^\| (F-\d+)[^|]*\| ([^|]*) \| ([^|]*) \|$", text, re.M):
        evaluation[m.group(1)] = (m.group(2).strip(), m.group(3).strip())
    area, result = "", []
    sections = re.split(r"^(##+ .*)$", text, flags=re.M)
    for i in range(1, len(sections), 2):
        head, body = sections[i], sections[i + 1]
        if head.startswith("## ") and not head.startswith("### "):
            area = head[3:].strip()
            continue
        m = re.match(r"### (F-\d+) (.*?)\s*(🔴|🟡|⚪|✅.*)?$", head)
        if not m:
            continue
        nr, title, mark = m.group(1), m.group(2).strip(), (m.group(3) or "").strip()
        lines = [l.rstrip() for l in body.splitlines()]
        options = [re.sub(r"\*\*", "", l.split("]", 1)[1]).strip() for l in lines if l.strip().startswith("- [ ]")]
        hint = " ".join(re.sub(r"^>\s*", "", l).replace("**", "") for l in lines if l.startswith(">")).strip()
        hint = re.sub(r"^So macht es der JTL-Shop \([^)]*\):\s*", "", hint)
        rest = [l for l in lines if l.strip() and not l.startswith(">") and not l.strip().startswith("- [ ]")
                and not l.startswith("Antwort:") and not l.startswith("---") and not l.startswith("<!--")]
        rest = [l for l in rest if not l.startswith("*Erstellt von")]
        question = re.sub(r"\*\*|`", "", "\n".join(rest)).strip()
        ev = evaluation.get(nr)
        status = ("beantwortet" if mark.startswith("✅") or (ev and ev[1].startswith("✅"))
                  else "bestätigen" if mark == "🟡" or (ev and ev[1].startswith("🟡"))
                  else "später" if mark == "⚪" else "offen")
        result.append(dict(nr=nr, area=area, topic=title, question=question, options="\n".join(options),
                           jtl=hint, proposal=(f"{ev[0]} – {ev[1]}" if ev else ""), status=status))
    return result


NEW_QUESTIONS = [
    dict(nr="R-1", area="Preise", topic="Rundung bei Menge > 1",
         question="Der JTL-Shop rundet die Summe aus den Nettopreisen, der .NET-Shop rundet heute je Stück brutto und multipliziert.\n"
                  "Beispiel: 3 Schlüssel à 9,282 € netto → JTL 33,14 €, .NET-Shop 33,15 €. Schließanlage Typ E: 288,72 € gegenüber 288,74 €.",
         options="A – wie JTL-Shop: Summe aus Netto runden (Rechnung, Stripe und Wawi gleich prüfen)\nB – je Stück brutto runden (heute)",
         jtl="Summe = round2(Σ netto × Menge × 1,19)", proposal="A, nach Abstimmung mit der Buchhaltung (Wawi-Rechnung muss dem Zahlbetrag entsprechen)",
         status="offen"),
    dict(nr="R-2", area="Preise", topic="Kategorie-Rabatt: Wawi oder JTL-Shop?",
         question="24 Artikel haben in der Wawi einen Kategorie-Rabatt, der JTL-Shop gewährt ihn nicht – seine Rabatt-Vorberechnung ist für diese Artikel veraltet "
                  "(nur beim erneuten Senden des Artikels aktualisiert).\nBeispiel: 41001 Ikon Fenstergriff, Kategorie 538 „Abschließbare Fenstergriffe für Halbzylinder“ mit 15 %: "
                  "JTL-Shop 107,21 €, .NET-Shop 91,13 €. Weitere: Längen-Positionen „Zylinderlänge 30–75 mm“ (33,5 %), Schlüssel-Positionen (10 %).\n"
                  "Liste: Wawi_Datenfehler.xlsx, Blatt „Rabatt fehlt im JTL-Shop“.",
         options="A – Wawi gilt: .NET-Shop rechnet wie heute; die 24 Artikel in der Wawi erneut an den JTL-Shop senden\nB – kein Rabatt für diese Artikel: Rabatt in der Wawi entfernen",
         jtl="ohne Rabatt (veraltete Vorberechnung, 41001 zuletzt 18.08.2025)", proposal="A – die Wawi ist die Quelle der Preise", status="offen"),
    dict(nr="S-1", area="Sortiment", topic="Konfig-Positionen als eigene Artikel",
         question="367 Artikel, die als Position im Konfigurator dienen, stehen im .NET-Shop auch als eigene Artikel in Liste und Suche – z. B. „Größe 10-45 mm“, "
                  "„Largekey hellrot Kunststoffclip“, „Sicherungskarte und Gebrauchsanweisung“; 59 davon kosten 0 €.\n"
                  "Der Stripe-Shop hat alle Konfig-Positionen ausgeblendet. Manche sind aber auch einzeln sinnvoll (z. B. Pflegespray, Nachschlüssel).",
         options="A – alle Konfig-Positionen ausblenden (wie Stripe-Shop)\nB – nur Positionen ohne eigenen Sinn ausblenden (Längen, Farben, 0-€-Positionen); Zubehör/Nachschlüssel bleiben\nC – so lassen (wie JTL-Shop)",
         jtl="zeigt sie, soweit im Shop-Kanal", proposal="B, Regel: Länge/Farbe/Funktion/0 € aus, Rest bleibt – Liste zur Durchsicht vorab", status="offen"),
    dict(nr="K-1", area="Konfigurator", topic="Systematik des großen Konfigurators",
         question="Ziel sind die 22 Systeme des Stripe-Shops (Schließanlagen › mechanisch/mechatronisch/elektronisch). Die 12 Systeme des JTL-Plugins bleiben nur zum Vergleich.",
         options="A – Stripe-Systematik (Entscheidung m.piper 27.10.2026)\nB – JTL-Plugin-Systematik", jtl="12 Systeme über Kategorie „Schließanlagen“ und Variationen",
         proposal="A bestätigen", status="bestätigen"),
    dict(nr="K-2", area="Konfigurator", topic="Anlagen-Artikel ohne Shop-Kanal",
         question="Die 197 Anlagen-Zylinder (z. B. 81.A15_Anl_O³) sind in der Wawi aktiv, aber keinem Shop zugeordnet – deshalb ist der Stripe-Konfigurator leer. "
                  "Der .NET-Shop liest sie trotzdem (nur im Konfigurator). Wer hat die Zuordnung entfernt, und soll es so bleiben?",
         options="A – so lassen, .NET-Shop liest unabhängig vom Kanal (heute)\nB – eigener Verkaufskanal „Konfigurator“ in der Wawi",
         jtl="JTL-Shop zeigt sie nicht", proposal="B, sauberer und nachvollziehbar (Bericht 13 J-29)", status="offen"),
    dict(nr="F-36.1", area="Konfigurator", topic="Schlüssel „3 inklusive“",
         question="Bei dormakaba, BKS, Abus und Keso 6000 sind 3 Schlüssel im Zylinderpreis enthalten. Gilt das je Zylinder oder je Schlüsseltyp? "
                  "Und was gilt für Schlüssel, die mehrere Türen schließen?",
         options="A – je Schlüssel für genau eine Tür bis 3 Stück im Satz, Rest als Mehrschlüssel (heute)\nB – je Zylinder 3 inklusive\nC – anders: ______",
         jtl="Stripe-Shop: Schlüssel für eine Tür bis 3 inklusive, sonst Mehrschlüssel", proposal="A bestätigen", status="offen"),
    dict(nr="F-36.2", area="Konfigurator", topic="Schlüsselcode-Zuschlag",
         question="Die Wawi kennt „Schlüsselcode D/E/F“ (1,93 € je Schlüssel) bzw. „Schlüsselaufpreis für Schließanlagen“. Soll das bei Anlagen (Typ D/E/F) je Schlüssel berechnet werden?",
         options="A – ja, je Schlüssel\nB – nein (heute)", jtl="im Stripe-Shop nicht berechnet; für Omega³ nicht gepflegt", proposal="", status="offen"),
    dict(nr="F-36.3", area="Konfigurator", topic="Zylinderzuschlag je Menge",
         question="Der Anlagenzuschlag (z. B. Keso Code E 16,29 € netto) gilt je Zylinder. Bei „3 gleiche Zylinder für eine Tür-Art“: 3 × oder 1 ×?",
         options="A – je Zylinder × Menge (heute)\nB – einmal je Tür-Position", jtl="", proposal="A", status="offen"),
    dict(nr="F-36.4", area="Konfigurator", topic="Gruppe „Schließfunktion“ in der Anlage",
         question="Manche Zylinder haben eine Pflichtgruppe „Schließfunktion“ (Verschieden-/Gleichsperrend). In einer Schließanlage ergibt sich das aus dem Schließplan.",
         options="A – weglassen (heute)\nB – passend zum Anlagentyp automatisch setzen", jtl="Stripe-Shop blendet sie aus", proposal="B, damit der Auftrag vollständig ist", status="offen"),
    dict(nr="F-36.5", area="Konfigurator", topic="Regel für den Anlagentyp (B–F)",
         question="Die Regeln von JTL-Plugin und Stripe-Shop widersprechen sich und sind in Grundfällen falsch. Der .NET-Shop nutzt eine fachliche Regel nach den Wawi-Codes:\n"
                  "B jeder Schlüssel jede Tür · C jeder Schlüssel genau eine Tür · D kein Hauptschlüssel, Zentraltüren · E mit Hauptschlüssel · F Gruppenschlüssel.\n"
                  "Beispiel: Chef-Schlüssel für alle Türen + Mitarbeiter je eine Tür → E (JTL-Plugin: F, Stripe: E).",
         options="A – fachliche Regel des .NET-Shops (heute)\nB – Regel des JTL-Plugins\nC – Regel des Stripe-Shops", jtl="", proposal="A, Fälle im Workshop durchgehen (Bericht 18 C.3)", status="offen"),
    dict(nr="K-3", area="Konfigurator", topic="Funktionen für Phase 2",
         question="Welche Funktionen braucht der große Konfigurator noch, und in welcher Reihenfolge?",
         options="PDF-Angebot (JTL-Plugin: Pflicht vor Warenkorb)\nKonfiguration speichern/teilen per Link (Trello #89)\nKonfiguration aus dem Warenkorb bearbeiten (Trello #12)\nFragebogen/Empfehlung wie Stripe-Shop\nAngebot anfordern statt bestellen",
         jtl="PDF-Angebot und Teilen-Link vorhanden (Dateien unsicher benannt)", proposal="Teilen-Link und Bearbeiten zuerst", status="offen"),
    dict(nr="W-1", area="Wawi", topic="Datenpflege",
         question="Wer korrigiert die Fehler aus der Datei „Wawi_Datenfehler.xlsx“, und bis wann? Wer pflegt künftig neue Konfigurationsgruppen und Anlagen-Artikel?",
         options="", jtl="", proposal="Je Bereich eine verantwortliche Person; Liste im nächsten Termin abhaken", status="offen"),
]


def build_questions():
    questions = parse_questions()
    # F-35 ist durch die Anlagen-Artikel beantwortet (Omega³ hat Code-Gruppe 1320) – nur bestätigen
    for q in questions:
        if q["nr"] == "F-09":
            q["status"] = "beantwortet"
            q["proposal"] = "Erledigt 27.10.2026: kleiner Konfigurator (3.701 Artikel) und großer Konfigurator (18 Anlagen-Systeme) gebaut"
        if q["nr"] == "F-35":
            q["status"] = "bestätigen"
            q["proposal"] = "Beantwortet durch die Daten: Omega³-Anlagen-Artikel (…_Anl_O³) mit Anlagenpreis K8Z/K8E/K8F – im .NET-Shop umgesetzt"
    questions += NEW_QUESTIONS
    order = {"offen": 0, "bestätigen": 1, "später": 2, "beantwortet": 3}
    prio = lambda q: "Livegang" if q["status"] in ("offen", "bestätigen") else "später" if q["status"] == "später" else ""

    wb = Workbook()
    legend = wb.active
    legend.title = "Anleitung"
    rows = [
        ["Workshop: offene Fragen .NET-Shop, Wawi und Konfigurator", ""],
        ["Stand", STAND],
        ["Quelle", "Bericht 16 (Fragen an den Fachbereich), Bericht 18 (Konfiguratoren), Bericht 14 (Plan)"],
        ["", ""],
        ["So arbeiten Sie mit der Datei", ""],
        ["1.", "Blatt „Fragen“: je Zeile eine Frage. Grau = Hintergrund (nicht ändern), gelb = im Workshop ausfüllen."],
        ["2.", "Spalte „Entscheidung“: gewählte Option (z. B. „A“) oder eigener Text."],
        ["3.", "Spalte „Status“ per Auswahlliste: offen · bestätigen · entschieden · später · entfällt."],
        ["4.", "„Verantwortlich“ und „Bis wann“ für alles, was nach dem Workshop zu tun ist."],
        ["5.", "Blatt „Beantwortet“: schon geklärt bzw. umgesetzt – nur zur Kenntnis, bei Bedarf widersprechen."],
        ["", ""],
        ["Beispielzeile (so sieht eine ausgefüllte Frage aus)", ""],
    ]
    for r in rows:
        legend.append(r)
    legend.append(["Nr / Frage", "F-12 · Abholung Fachmarkt Flensburg: 5,90 €, ab 10 € kostenlos – richtig?"])
    legend.append(["Entscheidung", "A – so lassen"])
    legend.append(["Status", "entschieden"])
    legend.append(["Verantwortlich / Bis wann", "Vertrieb (Name) · 15.11.2026"])
    legend.append(["Notizen", "Gilt auch für Abholung in Kiel, sobald eröffnet."])
    for row in legend.iter_rows():
        for c in row:
            c.font, c.alignment = FONT, WRAP
    legend["A1"].font = Font(name="Arial", size=14, bold=True)
    for r in (5, 12):
        legend[f"A{r}"].font = BOLD
    for r in range(13, 18):
        legend[f"B{r}"].fill = INPUT_FILL
    legend.column_dimensions["A"].width = 30
    legend.column_dimensions["B"].width = 110

    headers = ["Nr", "Bereich", "Thema", "Frage / Hintergrund", "Optionen", "So macht es der JTL-Shop", "Vorschlag IT",
               "Priorität", "Status", "Entscheidung", "Verantwortlich", "Bis wann", "Notizen"]
    widths = [8, 14, 24, 60, 42, 36, 36, 11, 13, 30, 18, 12, 30]

    def row(q):
        return [q["nr"], q["area"], q["topic"], q["question"], q["options"], q["jtl"], q["proposal"], prio(q), q["status"], "", "", "", ""]

    open_ = sorted([q for q in questions if q["status"] != "beantwortet"], key=lambda q: (order[q["status"]], q["area"], q["nr"]))
    done = [q for q in questions if q["status"] == "beantwortet"]
    ws = wb.create_sheet("Fragen")
    table(ws, headers, [row(q) for q in open_], widths, input_cols=(9, 10, 11, 12, 13), freeze="D2")
    dropdown(ws, "I", ["offen", "bestätigen", "entschieden", "später", "entfällt"])
    dropdown(ws, "H", ["Livegang", "vor Livegang wichtig", "später"])
    ws2 = wb.create_sheet("Beantwortet")
    table(ws2, headers, [row(q) for q in done], widths, input_cols=(10, 13), freeze="D2")
    for r in ws2.iter_rows(min_row=2, max_col=8):
        for c in r:
            c.fill = DONE_FILL

    # Zählung als Formel (rechnet mit, wenn im Workshop Status geändert wird)
    s = wb.create_sheet("Übersicht", 1)
    s.append(["Status", "Anzahl"])
    for c in s[1]:
        c.font, c.fill = HEAD, HEAD_FILL
    for i, st in enumerate(["offen", "bestätigen", "entschieden", "später", "entfällt"], start=2):
        s.append([st, f'=COUNTIF(Fragen!$I:$I,A{i})'])
    s.append(["Summe", "=SUM(B2:B6)"])
    s.append(["bereits beantwortet", "=COUNTA(Beantwortet!$A:$A)-1"])
    for row_ in s.iter_rows(min_row=2):
        for c in row_:
            c.font = FONT
    s["A7"].font = BOLD
    s.column_dimensions["A"].width = 22
    s.column_dimensions["B"].width = 10

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "Workshop_Offene_Fragen.xlsx"
    wb.calculation.fullCalcOnLoad = True   # Excel rechnet die Zählungen beim Öffnen
    wb.save(path)
    return path, len(open_), len(done)


# ----------------------------------------------------------------------------------------------
# 2. Wawi-Datenfehler
# ----------------------------------------------------------------------------------------------

def build_errors(data, orphans):
    wb = Workbook()
    ov = wb.active
    ov.title = "Übersicht"
    details = []

    def detail(name, headers, rows, widths):
        details.append((name, headers, rows, widths))
        return f"='{name}'!A1" if False else name

    item_cols = ["Artikel-Id", "Art.-Nr.", "Bezeichnung", "Kategorie / System"]
    item_w = [10, 22, 60, 24]
    def items(lst, extra=None):
        return [[x["id"], x.get("sku", ""), x.get("name", ""), x.get("system", x.get("cats", ""))] + ([extra(x)] if extra else []) + [""] for x in lst]

    detail("Ohne Preis", item_cols + ["Erledigt"], items(data["noPrice"]), item_w + [10])
    detail("Anlagen ohne Preis", item_cols + ["Erledigt"], items(data["noPriceConfigurator"]), item_w + [10])
    detail("Anlagen ohne Zylindertyp", item_cols + ["Erledigt"], items(data["noType"]), item_w + [10])
    detail("Code-Gruppe", item_cols + ["Befund", "Erledigt"],
           items(data["codeDiff"], lambda x: f"Code-Gruppe {x['code']}, erwartet {x['expected']} (wie die übrigen Zylinder des Systems)"), item_w + [50, 10])
    detail("Varianten-Altdaten", item_cols + ["Werte der Variation „Varianten“ (netto)", "Erledigt"],
           items(data["variantLegacy"], lambda x: f"{x['values']} | Code-Gruppe {x['code']}"), item_w + [60, 10])
    detail("Ohne Sicherheitslevel", item_cols + ["Erledigt"], items(data["secMix"]), item_w + [10])
    detail("Zylindertyp-Reihenfolge", ["Merkmalwert „Zylindertyp“", "Sortierung in der Wawi", "Artikel", "Erledigt"],
           [[x["_id"], x["sort"], x["n"], ""] for x in data["typeSort"]], [44, 18, 10, 10])
    detail("Verwaiste Kategorien", ["Kategorie-Id", "Kategorie", "Eltern-Id", "Elternkategorie (inaktiv/fehlt)", "Artikel", "Erledigt"],
           [[o["id"], o["name"], o["parentId"], o["parentName"] or "(fehlt)", o["itemCount"], ""] for o in orphans], [12, 34, 10, 40, 10, 10])
    detail("Leere Systeme", ["Kategorie-Id", "System", "Erledigt"], [[x["id"], x["name"], ""] for x in data["emptySystems"]], [12, 34, 10])
    discounts = data.get("discounts", {"onlyNet": []})
    detail("Rabatt fehlt im JTL-Shop", ["Artikel-Id", "Art.-Nr.", "Bezeichnung", "Rabatt Wawi %", "Listenpreis brutto", "Preis mit Rabatt", "Erledigt"],
           [[x["id"], x["sku"], x["name"], x["pct"], x["list"], x["price"], ""] for x in discounts["onlyNet"]], [10, 18, 56, 12, 14, 14, 10])
    images = data.get("images", {"examples": []})
    detail("Bilder anderer Systeme", item_cols + ["Gleiche Bilder wie", "Erledigt"],
           [[x["id"], x["sku"], x["name"], x["system"], x["others"], ""] for x in images["examples"]], item_w + [50, 10])

    c = data["counts"]
    # Anzahl: Formel auf das Detailblatt, sonst Zahl aus dem Lesemodell (Kommentar)
    def cnt(sheet):
        return f"=COUNTA('{sheet}'!A:A)-1"
    rows = [
        ["Preise", "Artikel im Shop sichtbar, aber ohne Preis", cnt("Ohne Preis"), "werden nicht angezeigt/bestellt (JTL-Shop: „Preis 0 anzeigen“ aus)",
         "Preis pflegen oder Shop-Kanal entfernen; ggf. „Angebot anfordern“ (F-07)", "Ohne Preis"],
        ["Konfigurator", "Anlagen-Zylinder ohne Preis (Wilka Carat S4)", cnt("Anlagen ohne Preis"), "System fehlt im Konfigurator",
         "Preise pflegen; Länge nur einmal (siehe Zeile Wilka)", "Anlagen ohne Preis"],
        ["Konfigurator", "Anlagen-Zylinder ohne Merkmal „Zylindertyp“", cnt("Anlagen ohne Zylindertyp"), "Zylinder steht unter „Weitere“ statt beim Typ",
         "Merkmal setzen", "Anlagen ohne Zylindertyp"],
        ["Sortiment", "Zylinder im Shop (mit Längen-Konfiguration) ohne Merkmal „Zylindertyp“", c["cylindersShopNoType"], "Filter/Gruppierung nach Typ unvollständig",
         "Merkmal setzen (Liste über Admin › Prüfungen)", ""],
        ["Merkmale", "Werte des Merkmals „Zylindertyp“ ohne Reihenfolge (Sortierung 0)", cnt("Zylindertyp-Reihenfolge"),
         "Reihenfolge Doppel → Halb → Knauf … (Trello #84) nur über eine Ersatztabelle im .NET-Shop", "Sortierung der Merkmalwerte in der Wawi pflegen", "Zylindertyp-Reihenfolge"],
        ["Konfigurator", "Anlagen-Zylinder mit falscher oder fehlender Code-Gruppe („Zylinder Schließfunktion“)", cnt("Code-Gruppe"),
         "falscher Anlagenzuschlag (fremdes System) bzw. Zylinder nicht als Anlage bestellbar", "Code-Gruppe des Systems zuordnen (Keso 1320, dormakaba 1504, BKS 1505, pextra Q 1506, Abus 1507)", "Code-Gruppe"],
        ["Konfigurator", "Altdaten-Variation „Varianten“ (code_d/e/f) mit anderen Beträgen als die Code-Gruppe", cnt("Varianten-Altdaten"),
         "Gefahr doppelter/abweichender Anlagenpreise (der .NET-Shop ignoriert die Variation)", "Variation entfernen, Anlagenpreis nur über die Code-Gruppe", "Varianten-Altdaten"],
        ["Merkmale", "„Sicherheitsstufe“ (8 Artikel) und „Sicherheitslevel“ (194) nebeneinander; Anlagen-Zylinder ohne Sicherheitslevel", cnt("Ohne Sicherheitslevel"),
         "Filter „Sicherheitsstufe“ im Stripe-Shop fast immer leer", "ein Merkmal festlegen, das andere zusammenführen", "Ohne Sicherheitslevel"],
        ["Kategorien", "Leere System-Kategorien im Konfigurator-Ast", cnt("Leere Systeme"), "keine", "Artikel zuordnen oder Kategorie löschen", "Leere Systeme"],
        ["Kategorien", "Konfigurator-Ast „Schließanlagen › mechanisch/mechatronisch/elektronisch“ inaktiv, 197 Anlagen-Artikel ohne Shop-Kanal (J-29)", 197,
         "Stripe-Konfigurator leer; .NET-Shop liest sie gesondert", "eigener Verkaufskanal „Konfigurator“ (Workshop K-2)", ""],
        ["Kategorien", "Aktive Kategorien unter inaktiver Elternkategorie (verwaist)", cnt("Verwaiste Kategorien"), "nicht in der Navigation erreichbar",
         "Eltern aktivieren oder Kategorien deaktivieren (F-10)", "Verwaiste Kategorien"],
        ["Kategorien", "Altlasten „*** Plugin Fehler ohne Rabatt ***“ (2300), „alter Konfigurator“ (2533)", 2, "keine (inaktiv)", "aufräumen", ""],
        ["Bilder", "Anlagen-Artikel nur mit Bildern eines anderen Systems – Keso O³ trägt alle Bilder der O²-Artikel (30 von 30), dormakaba-Systeme teilen Bilder",
         cnt("Bilder anderer Systeme"), "Omega³ sieht im Konfigurator aus wie Omega² (Systemkarte, Zylinderkarten)",
         "eigene Produktbilder zuordnen (mindestens O³); bei gleicher Bauform bewusst so lassen", "Bilder anderer Systeme"],
        ["Bilder", "Systemkategorien des Konfigurators (Stripe-Systematik, z. B. 2449 Keso 8000 O², 2531 O³, 2452 gemini pluS) ohne Kategoriebild – nur Winkhaus (leer) hat eines", 18,
         ".NET-Shop zeigt ersatzweise das Bild des ersten Zylinders; Stripe-Shop zeigte nur das Herstellerlogo",
         "je System ein Kategoriebild pflegen (wie bei den JTL-Plugin-Systemen, 260 × 260)", ""],
        ["Bilder", "JTL-Plugin-Systeme teilen Kategoriebilder: Kaba quattro/expert pluS/expert cross (Bild 3794), Abus Bravus 2000/3000/4000 (Bild 12324)", 6,
         "Systeme in der Auswahl nicht unterscheidbar", "eigene Bilder je System", ""],
        ["Preise", "Kategorie-Rabatt der Wawi fehlt im JTL-Shop (Vorberechnung tartikelkategorierabatt veraltet), z. B. 41001 Fenstergriff 15 % (Kategorie 538) – im JTL-Shop zuletzt 18.08.2025 abgeglichen",
         cnt("Rabatt fehlt im JTL-Shop"), "JTL-Shop zu teuer (41001: 107,21 € statt 91,13 €); .NET-Shop rechnet nach Wawi",
         "Artikel in der Wawi erneut an den JTL-Shop senden; Fachbereich bestätigt, dass der Wawi-Rabatt gilt", "Rabatt fehlt im JTL-Shop"],
        ["Preise", "Kategorie-Rabatt doppelt gepflegt: Kategorie 538, Kundengruppe 13 (Google Shopping) zweimal 15 %", 1, "keine (gleicher Wert)",
         "doppelte Zeile löschen", ""],
        ["Bilder", "Herstellerlogo Dormakaba ist ein breites Banner mit Zusatz „Partner“ (800 × 358) statt eines schlichten Logos", 1,
         "Systemkarten der dormakaba-Systeme zeigen das Banner", "schlichtes Logo als Herstellerbild pflegen", ""],
        ["Stammdaten", "Zwei Abus-Hersteller: „Abus Pfaffenhain“ (67) und „Abus Bremicker“ (1); alle 11 Artikel von Abus Bravus 4000 (JTL-System 1617) hängen an „Bremicker“, die übrigen Bravus-Systeme an „Pfaffenhain“", 11,
         "abweichendes Logo/Herstellerfilter für Bravus 4000", "Hersteller vereinheitlichen (Bravus = Abus Pfaffenhain?)", ""],
        ["Sortiment", "Zylinder/Schlüssel des JTL-Plugins im Shop-Kanal mit Kurzbeschreibung „nicht käuflich … Variante unseres Schließanlagen-Konfigurators“", 181,
         "im JTL-Shop sichtbar; im .NET-Shop seit 27.10. automatisch ausgeblendet (nur Konfigurator)", "Hinweistext entfernen, sobald der JTL-Shop abgelöst ist; Bäume 4 und 2181", ""],
        ["Konfigurator", "Wilka Carat S4: Länge doppelt gepflegt (Variation „Zylinderlänge“ und Konfig-Gruppen 1548/1549)", 3, "Gefahr doppelter Längenaufpreise",
         "nur Konfig-Gruppe behalten", ""],
        ["Konfigurator", "Keso 8000 O³: keine Gruppe „Schlüssel Schließfunktion“ (Schlüsselcode D/E/F), O² schon", 30, "Schlüsselcode-Zuschlag für O³ nicht möglich (F-36.2)",
         "Gruppe 1554 zuordnen, falls F-36.2 = ja", ""],
        ["Konfigurator", "Konfigurationsgruppen ohne Shop-Zuordnung (tkonfigshop): 75, 1448, 1449, 1468, 1469, Wilka 1548–1550", 8, "Gruppen fehlen im Shop",
         "Shop 5 zuordnen oder löschen", ""],
        ["JTL-Plugin", "Abus Bravus 2000 Doppelzylinder (30595): Aufpreis 70 mm außen 29,1597 €, innen 28,9076 € netto", 1, "kleine Preisabweichung je Seite",
         "Aufpreis vereinheitlichen", ""],
        ["JTL-Plugin", "Abus AZ/BMZ: Altlast-Variationen „input“, Außen-/Innenlänge „--“, Opt1/Opt2", "", "unnötige Pflichtauswahl", "Variationen entfernen", ""],
        ["JTL-Plugin", "Schlüssel-Variation heißt „Variation“ statt „Varianten“ (z. B. 30664)", 1, "Code-Wert erreicht den Schlüssel im JTL-Plugin nicht (0 €, ohne Folgen)",
         "einheitlich benennen", ""],
        ["Bestand", "Artikel 71529: Wawi erlaubt Überverkauf, JTL-Shop nicht (J-27)", 1, ".NET-Shop zeigt „Nachlieferung“, JTL-Shop „ausverkauft“",
         "Einstellung prüfen, Abgleich JTL-Shop", ""],
        ["Attribute", "Gratisgeschenk 31577: Text „250“, Zahl 200 im Funktionsattribut „gratisgeschenk ab“", 1, "Schwelle je nach Lesart 200 oder 250 €",
         "einen Wert pflegen", ""],
        ["Kunden", "Kunden mit gleicher E-Mail-Adresse (Trello #69, Beispiel: interne Testadresse doppelt)", "", "Auftrag braucht manuelle Kundenzuordnung",
         "Dubletten zusammenführen", ""],
        ["Preise", "Artikel 48518 (BKS Janus): JTL-Shop zeigte kurzzeitig anderen Preis als die Wawi", 1, "Prüfen beim nächsten Abgleich", "prüfen", ""],
        ["Texte", "Artikel im Shop ohne Beschreibung", c["noDescription"], "schwache Artikelseite, SEO", "Texte ergänzen (Liste: Admin › Prüfungen › CSV)", ""],
        ["Bilder", "Artikel im Shop ohne Bild", c["noImage"], "Platzhalterbild", "Bilder ergänzen", ""],
        ["Stammdaten", "Artikel im Shop ohne Hersteller", c["noManufacturer"], "Herstellerfilter unvollständig", "Hersteller zuordnen", ""],
        ["SEO", "Artikel ohne SEO-URL in der Wawi (Shop erzeugt eine aus dem Namen)", c["noSeo"], "nur Hinweis", "bei Bedarf pflegen", ""],
        ["Konfigurator", "Konfig-Positionen, deren Artikel weder im Shop noch im Konfigurator-Sortiment sind", data["posMissing"], "Position ohne bekannten Preis wird nicht angeboten",
         "prüfen, ob gewollt (z. B. alte Farben)", ""],
    ]
    headers = ["Nr", "Bereich", "Befund", "Anzahl", "Auswirkung im Shop", "Korrektur in der Wawi (Vorschlag)", "Detailblatt", "Verantwortlich", "Status", "Erledigt am", "Notizen"]
    table(ov, headers, [[f"W-{i:02d}"] + r for i, r in enumerate(rows, start=1)], [7, 13, 60, 9, 40, 44, 22, 18, 12, 12, 30], input_cols=(8, 9, 10, 11), freeze="D2")
    dropdown(ov, "I", ["offen", "in Arbeit", "erledigt", "gewollt / kein Fehler"])
    for r in range(2, ov.max_row + 1):
        cell = ov[f"D{r}"]
        if not (isinstance(cell.value, str) and cell.value.startswith("=")) and cell.value != "":
            cell.comment = Comment(f"Stand Lesemodell/Wawi {STAND} (Abfrage), nicht live", "IT")
    for name, h, rws, w in details:
        ws = wb.create_sheet(name[:31])
        table(ws, h, rws, w, input_cols=(len(h),), freeze="B2")
        dropdown(ws, get_column_letter(len(h)), ["ja", "nein", "gewollt"], rows=max(len(rws) + 1, 2))
    path = OUT / "Wawi_Datenfehler.xlsx"
    wb.calculation.fullCalcOnLoad = True
    wb.save(path)
    return path, len(rows)


if __name__ == "__main__":
    data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    if len(sys.argv) > 3:
        data["images"] = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
    if len(sys.argv) > 4:
        data["discounts"] = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
    orphans = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
    p1, n_open, n_done = build_questions()
    p2, n_err = build_errors(data, orphans)
    print(p1, f"{n_open} offen/bestätigen, {n_done} beantwortet")
    print(p2, f"{n_err} Befunde")
