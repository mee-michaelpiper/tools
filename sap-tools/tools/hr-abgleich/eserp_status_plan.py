"""Probelauf der Status-/Austrittsregeln vom 27.10.2026 (wie EmployeeService.PlanStates im Worker) + Löschliste.

Eingaben in <data>: preview.jsonl (MongoRead Prod-ES-Worker Employee-SyncPreview), eserp_states.json (eserp_states.py).
Optional: --keep 85084191,... (Datensätze mit Ende, die bleiben sollen).
Aufruf: /usr/bin/python3 eserp_status_plan.py <data> [--keep nr,nr]  → <data>/status_plan.xlsx
"""
import json, sys, re, datetime as dt, collections
from openpyxl import Workbook
from openpyxl.styles import Font
from openpyxl.utils import get_column_letter

data = sys.argv[1]
keep = set(sys.argv[sys.argv.index('--keep') + 1].split(',')) if '--keep' in sys.argv else set()
today = dt.date.today()
INACTIVE_END = dt.date(1999, 12, 31)
prev = {str(p['_id']).lstrip('0'): p for p in map(json.loads, open(f'{data}/preview.jsonl'))}
es = {str(x['personalNr']): x for x in json.load(open(f'{data}/eserp_states.json'))}

def d(s): return dt.date.fromisoformat(s[:10]) if s else None
def de(s): return dt.datetime.strptime(s, '%d.%m.%Y').date()
def fmt(x): return x.strftime('%d.%m.%Y') if x else '–'

def target(p):
    if not p['Transferred']: return 10, INACTIVE_END
    if p.get('Absence'):
        m = re.search(r'(\d\d\.\d\d\.\d{4})–(\d\d\.\d\d\.\d{4})?', p['Absence'])
        if m and de(m[1]) <= today and (not m[2] or de(m[2]) >= today): return 3, de(m[1]) - dt.timedelta(days=1)
    ex = d(p.get('ExitDate'))
    if not ex:
        m = re.search(r'Austritt (\d\d\.\d\d\.\d{4})', p.get('Reason') or '')
        ex = de(m[1]) if m else None
    if ex: return (2 if ex < today else 1), ex
    return 1, None

def plan(records):
    rows = []
    for nr, e in sorted(records.items(), key=lambda kv: int(kv[0])):
        cur = (e.get('status'), d(e.get('persEndDat')))
        p = prev.get(nr)
        name = f"{e.get('firma1', '')}, {e.get('vorname', '')}"
        if p:
            t = target(p)
            if cur != t: rows.append([nr, name, 'in SAP', p['Reason'], cur[0], fmt(cur[1]), t[0], fmt(t[1])])
        elif cur[0] not in (2, 10) and cur[1] and cur[1] != INACTIVE_END and cur[1] < today:
            rows.append([nr, name, 'nicht in SAP', 'Austritt vorbei', cur[0], fmt(cur[1]), 2, fmt(cur[1])])
    return rows

delete = {nr: e for nr, e in es.items() if nr not in keep and (
    e.get('persEndDat') or (nr in prev and 'Ausnahme: nie' in prev[nr]['Reason']))}
after = {nr: e for nr, e in es.items() if nr not in delete}
del_rows = [[nr, f"{e.get('firma1', '')}, {e.get('vorname', '')}", e.get('status'), fmt(d(e.get('persEndDat'))),
             (prev[nr]['Reason'] if nr in prev else 'nicht in SAP'), e.get('email', '')] for nr, e in sorted(delete.items(), key=lambda kv: int(kv[0]))]

wb = Workbook(); wb.remove(wb.active)
def sheet(title, header, rows, widths):
    ws = wb.create_sheet(title); ws.append(header); [setattr(c, 'font', Font(bold=True)) for c in ws[1]]
    for r in rows: ws.append(r)
    for i, w in enumerate(widths, 1): ws.column_dimensions[get_column_letter(i)].width = w
    ws.auto_filter.ref = ws.dimensions; ws.freeze_panes = 'A2'
sheet('Löschliste', ['PersNr', 'Name', 'Status', 'Ende', 'SAP-Abgleich', 'E-Mail'], del_rows, [11, 28, 7, 11, 60, 32])
H = ['PersNr', 'Name', 'Quelle', 'Grund', 'Status jetzt', 'Ende jetzt', 'Status neu', 'Ende neu']
W = [11, 28, 13, 60, 11, 11, 10, 11]
p_after, p_now = plan(after), plan(es)
sheet('Plan nach Löschung', H, p_after, W)
sheet('Plan ohne Löschung', H, p_now, W)
wb.save(f'{data}/status_plan.xlsx')
print(f'esERP {len(es)}, Löschliste {len(delete)}, Plan nach Löschung {len(p_after)}, ohne Löschung {len(p_now)}')
for title, rows in (('nach Löschung', p_after),):
    print(title, collections.Counter(f"{r[2]}: {r[4]}/{r[5] != '–'} → {r[6]}" for r in rows))
