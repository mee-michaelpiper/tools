"""Enddatum im esERP (persEndDat, fiktiv 1999-12-31) ↔ Entscheidung des letzten Mitarbeiter-Abgleichs (Worker).

Eingaben im Ordner <data> (Personendaten nur im Scratchpad):
  preview.jsonl      – MongoRead Prod-ES-Worker Employee-SyncPreview
  eserp_detail.json  – esERP-API GET /personal/{nr} für alle Nummern aus GET /personal und der Vorschau
                       (Login: POST https://esapi.meesenburg.de/login mit KV-Secret c4vApiCredentials-prod;
                       die Liste /personal enthält kein persEndDat, nur der Einzelabruf; Nullfelder fehlen in der Antwort)
Aufruf: python eserp_enddatum.py <data>   → <data>/enddatum_abgleich.xlsx
"""
import json, sys, re, collections, datetime as dt
from openpyxl import Workbook
from openpyxl.styles import Font
from openpyxl.utils import get_column_letter

data = sys.argv[1]
today = dt.date.today().isoformat()
prev = {str(p['_id']).lstrip('0'): p for p in map(json.loads, open(f'{data}/preview.jsonl'))}
es = {str(x['personalNr']): x for x in json.load(open(f'{data}/eserp_detail.json'))}

def sap_exit(p):
    if p.get('ExitDate'): return p['ExitDate']
    m = re.search(r'Austritt (\d\d)\.(\d\d)\.(\d{4})', p.get('Reason') or '')
    return f'{m[3]}-{m[2]}-{m[1]}' if m else None

def category(p, e):
    if e is None: return 'nur SAP (nicht im esERP)'
    if p is None: return 'nur esERP (nicht im SAP-Abgleich)'
    end = (e.get('persEndDat') or '')[:10]
    ex, absent = sap_exit(p), p.get('Absence')
    if end:
        if not p['Transferred']: return 'Ende gesetzt, passt: nicht übertragen'
        if absent: return 'Ende gesetzt, passt: langzeit-abwesend'
        if ex and ex <= today: return 'Ende gesetzt, passt: ausgetreten'
        return 'Ende gesetzt, aber laut SAP aktiv und übertragen'
    if not p['Transferred']: return 'kein Ende, aber nicht mehr übertragen'
    if absent: return 'kein Ende, aber langzeit-abwesend'
    if ex and ex <= today: return 'kein Ende, aber ausgetreten'
    if ex: return 'kein Ende, Austritt geplant'
    return 'passt: aktiv in beiden'

rows = []
for k in sorted(set(prev) | set(es), key=lambda s: s.zfill(10)):
    p, e = prev.get(k), es.get(k)
    rows.append({
        'Kategorie': category(p, e), 'PersNr': k,
        'Name': (p or {}).get('Name') or f"{(e or {}).get('vorname', '')} {(e or {}).get('firma1', '')}".strip(),
        'esERP Ende': ((e or {}).get('persEndDat') or '')[:10], 'esERP Status': (e or {}).get('status'),
        'esERP KST': (e or {}).get('kostenstelle'), 'esERP Mail': 'ja' if (e or {}).get('email') else '',
        'SAP übertragen': None if p is None else ('ja' if p['Transferred'] else 'nein'), 'SAP Grund': (p or {}).get('Reason'),
        'SAP Austritt': sap_exit(p) if p else None, 'SAP Abwesenheit': (p or {}).get('Absence'),
        'SAP KST': (p or {}).get('CostCenter'), 'Standort': (p or {}).get('Site'), 'Stelle': (p or {}).get('Job'),
    })

counts = collections.Counter(r['Kategorie'] for r in rows)
wb = Workbook()
ws = wb.active; ws.title = 'Übersicht'
ws.append(['Kategorie', 'Anzahl']); ws['A1'].font = ws['B1'].font = Font(bold=True)
for k, v in sorted(counts.items()): ws.append([k, v])
ws.column_dimensions['A'].width = 50
ws2 = wb.create_sheet('Abgleich')
ws2.append(list(rows[0])); [setattr(c, 'font', Font(bold=True)) for c in ws2[1]]
for r in sorted(rows, key=lambda r: (r['Kategorie'], r['Name'])): ws2.append(list(r.values()))
for i, w in enumerate([45, 11, 30, 11, 8, 8, 8, 9, 50, 11, 30, 8, 20, 28], 1): ws2.column_dimensions[get_column_letter(i)].width = w
ws2.auto_filter.ref = ws2.dimensions; ws2.freeze_panes = 'A2'
wb.save(f'{data}/enddatum_abgleich.xlsx')
for k, v in sorted(counts.items()): print(f'{v:4}  {k}')
