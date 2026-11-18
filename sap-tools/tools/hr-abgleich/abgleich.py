"""Mitarbeiterabgleich SAP HCM (Buchungskreise 298 und 290 – wie der Worker) ↔ Excel-Liste ↔ esERP-Personalstamm.

Eingaben (Ordner <data>, Personendaten nur im Scratchpad ablegen):
  pa0000.txt pa0001.txt pa0002.txt pa0105.txt t001p.txt  – SapRead (SAPSYS=HCM) „table“-Ausgaben, siehe README
  hrp1000.txt hrp1001_oo.txt hrp1001_so.txt               – Organisationsstruktur (O/S/C)
  eserp_personal_detail.json eserp_logins.json            – esERP-API /personal/{nr}, /personal/kennwoerter (ohne Kennwörter)
  excel.json (optional)                                     – Zeilen der alten Liste Mitarbeiterabgleich_298_2026-10-09.xlsx
Aufruf: python abgleich.py <data> [Stichtag JJJJMMTT]
"""
import json, sys, os, datetime as dt, collections

data = sys.argv[1]
TODAY = sys.argv[2] if len(sys.argv) > 2 else dt.date.today().strftime('%Y%m%d')

def table(name):
    rows = []
    for line in open(os.path.join(data, name), encoding='utf-8'):
        if not line.startswith('   '): continue
        rows.append([c.strip() for c in line.strip().split('|')])
    return rows

def d(s):  # JJJJMMTT -> date
    return dt.date(int(s[:4]), int(s[4:6]), int(s[6:8])) if s and s[:4] != '0000' else None

def fmt(x): return x.strftime('%d.%m.%Y') if x else ''

ENTRY_ACTIONS = {'01', '06', '12', '62', '71'}  # Ersteintritt, Übernahme EDV, Wiedereintritt, Einstellung m. Datenübernahme, korrigierter Eintritt

pa0 = collections.defaultdict(list)
for p, b, e, massn, massg, stat2 in table('pa0000.txt'): pa0[p].append((b, e, massn, stat2))
for v in pa0.values(): v.sort()
pa1 = collections.defaultdict(list)
for r in table('pa0001.txt'): pa1[r[0]].append(r)
for v in pa1.values(): v.sort(key=lambda r: r[1])
names = {p: (n, v) for p, n, v in table('pa0002.txt')}
mails = collections.defaultdict(list)
for p, b, e, m in table('pa0105.txt'): mails[p].append((b, e, m.lower()))
btrtl = {(w, b): t for w, b, t in table('t001p.txt')}
objtext = {(o, i): (s, t) for o, i, s, t in table('hrp1000.txt')}
parent = {i: s for i, c, s in table('hrp1001_oo.txt')}

def valid(rows, day, bi=1, ei=2):
    return next((r for r in rows if r[bi] <= day <= r[ei]), None)

def status_at(p, day):
    """(Status, Eintritt, Austritt, geplanter Austritt) zum Stichtag aus IT0000."""
    recs = pa0.get(p, [])
    cur = next((r for r in recs if r[0] <= day <= r[1]), None)
    stat = {'3': 'aktiv', '0': 'ausgetreten', '1': 'inaktiv', '2': 'Rentner'}.get(cur[3], '?') if cur else 'unbekannt'
    # Eintritt: letzte Eintrittsmaßnahme bis zum Stichtag
    entries = [r for r in recs if r[2] in ENTRY_ACTIONS and r[0] <= day]
    entry = d(entries[-1][0]) if entries else None
    exit_ = None
    if cur and cur[3] == '0':
        # Austritt = Tag vor Beginn des (ersten) Austritts-Satzes nach dem letzten aktiven Satz
        last_active = max((r for r in recs if r[3] == '3' and r[0] <= day), default=None)
        after = [r for r in recs if r[3] == '0' and (last_active is None or r[0] > last_active[0]) and r[0] <= day]
        if after: exit_ = d(after[0][0]) - dt.timedelta(days=1)
    planned = next((d(r[0]) - dt.timedelta(days=1) for r in recs if r[0] > day and r[3] in '012' and cur and cur[3] == '3'), None)
    return stat, entry, exit_, planned

def org_path(orgeh):
    path, seen = [], set()
    while orgeh and orgeh != '00000000' and orgeh not in seen:
        seen.add(orgeh)
        path.append(objtext.get(('O', orgeh), ('', orgeh))[1])
        orgeh = parent.get(orgeh)
    return ' › '.join(reversed(path))

# Heutiger Buchungskreis aller Personen (pa0001_now.txt: PA0001 ohne Buchungskreis-Filter, gültig am Stichtag) –
# wer in einen anderen Buchungskreis gewechselt ist (z. B. 290 → 100), zählt nicht als „aktiv in 298/290“
now_bukrs = {r[0]: (r[1], r[2].lstrip('0')) for r in table('pa0001_now.txt')} if os.path.exists(os.path.join(data, 'pa0001_now.txt')) else {}

hcm = {}
for p, rows in pa1.items():
    cur1 = valid(rows, TODAY) or rows[-1]
    stat, entry, exit_, planned = status_at(p, TODAY)
    if not valid(rows, TODAY) and stat == 'aktiv':
        b, k = now_bukrs.get(p, ('?', ''))
        stat = f'gewechselt nach BK {b}' + (f' (KST {k})' if k else '')
    mail = next((m for b, e, m in mails.get(p, []) if b <= TODAY <= e), None)
    hcm[p] = dict(
        pernr=p, name=f"{names.get(p, ('', ''))[0]}, {names.get(p, ('', ''))[1]}", status=stat, entry=entry, exit=exit_, planned_exit=planned,
        bukrs_now=cur1[3] if valid(rows, TODAY) else '(nicht mehr 298/290)', site=btrtl.get((cur1[4], cur1[5]), cur1[5]),
        persg=cur1[6], persk=cur1[7], kostl=cur1[8].lstrip('0'), orgeh=cur1[9],
        org=objtext.get(('O', cur1[9]), ('', ''))[1], org_path=org_path(cur1[9]),
        position=objtext.get(('S', cur1[10]), ('', ''))[1], job=objtext.get(('C', cur1[11]), ('', ''))[1], mail=mail)

# esERP-Personalnummern sind von der SAP-API verschlüsselte (pseudonymisierte) HCM-Nummern (Key Vault SAP-PersonalId-Key).
# Nicht entschlüsseln – Zuordnung über E-Mail bzw. Name: sap_employees.json (GET /sap/employees) liefert verschlüsselte Nr. + Name + E-Mail.
import unicodedata
def norm(s): return ''.join(c for c in unicodedata.normalize('NFKD', (s or '').lower()) if c.isalnum())
by_mail = collections.defaultdict(list)
for p, h in hcm.items():
    if h['mail']: by_mail[h['mail']].append(p)
# Verschlüsselte Nr. → (Buchungskreis, KST) aus der SAP-API: entscheidet, wenn eine E-Mail zu mehreren HCM-Nummern gehört
sap_api = {int(e['employeeId']): (e['companyCode'], e['costCenter'].lstrip('0')) for e in json.load(open(os.path.join(data, 'sap_employees.json')))} \
    if os.path.exists(os.path.join(data, 'sap_employees.json')) else {}
by_name = collections.defaultdict(list)
for p, h in hcm.items():
    n, v = names.get(p, ('', ''))
    by_name[norm(n) + '|' + norm(v)].append(p)
def match(mail, nach, vor, es_nr=None):
    cands = by_mail.get((mail or '').lower(), [])
    if len(cands) == 1: return cands[0], 'E-Mail'
    if len(cands) > 1:
        bk, kst = sap_api.get(es_nr, (None, None))
        hit = [p for p in cands if hcm[p]['status'] == 'aktiv' and hcm[p]['bukrs_now'] == bk and hcm[p]['kostl'] == kst]
        if len(hit) == 1: return hit[0], 'E-Mail + KST'
    c = by_name.get(norm(nach) + '|' + norm(vor), [])
    if len(c) == 1: return c[0], 'Name'
    # aktive bevorzugen, wenn der Name mehrfach vorkommt
    act = [p for p in c if hcm[p]['status'] == 'aktiv']
    return (act[0], 'Name (mehrdeutig)') if len(act) == 1 else (None, 'nicht gefunden' if not c else 'Name mehrdeutig')
es_raw = [x for x in json.load(open(os.path.join(data, 'eserp_personal_detail.json'))) if x and x.get('personalNr')]
logins_raw = {x['personalNr']: x for x in json.load(open(os.path.join(data, 'eserp_logins.json')))}
es, unmatched_es = {}, []
for x in es_raw:
    p, how = match(x.get('email'), x.get('firma1'), x.get('vorname'), x['personalNr'])
    x['_match'] = how; x['_login'] = logins_raw.get(x['personalNr'])
    if p: es[p] = x
    else: unmatched_es.append(x)
logins = {p: x['_login'] for p, x in es.items() if x['_login']}
json.dump({'hcm': hcm, 'today': TODAY}, open(os.path.join(data, 'hcm_model.json'), 'w'), default=str, ensure_ascii=False)
print('Zuordnung esERP→HCM:', collections.Counter(x['_match'] for x in es_raw))
print(f"HCM 298 (je Zeitraum): {len(hcm)} | heute in 298: {sum(1 for h in hcm.values() if h['bukrs_now']=='298')} | esERP: {len(es)} | esERP-Anmeldungen: {len(logins)}")
print('Status heute:', collections.Counter(h['status'] for h in hcm.values()))

# ---------------------------------------------------------------- 1) alte Excel-Liste gegen HCM (Stand der Liste und heute)
diffs_excel = []
xl_path = os.path.join(data, 'excel.json')
if os.path.exists(xl_path):
    xl = {str(r['Personalnr.']).zfill(8): r for r in json.load(open(xl_path))}
    for p, r in xl.items():
        h = hcm.get(p)
        if not h: diffs_excel.append((p, r['Nachname'], 'nicht in HCM 298', '', '')); continue
        s09, e09, x09, pl09 = status_at(p, '20261009')
        xl_exit = d(r['Austritt']) if r['Austritt'] else None
        xl_entry = d(r['Eintritt']) if r['Eintritt'] else None
        if r['Status laut SAP'] != s09: diffs_excel.append((p, h['name'], 'Status (Liste falsch)', r['Status laut SAP'], s09))
        if xl_exit != x09 and s09 == 'ausgetreten': diffs_excel.append((p, h['name'], 'Austritt (Liste falsch)', fmt(xl_exit), fmt(x09)))
        if s09 == 'aktiv' and xl_exit: diffs_excel.append((p, h['name'], 'Austritt bei Aktivem (Liste falsch)', fmt(xl_exit), ''))
        if pl09 and not xl_exit: diffs_excel.append((p, h['name'], 'geplanter Austritt fehlt in Liste', '', fmt(pl09)))
        if xl_entry != e09: diffs_excel.append((p, h['name'], 'Eintritt (Liste weicht ab)', fmt(xl_entry), fmt(e09)))
        if (r['Kostenstelle'] or '').lstrip('0') != h['kostl'] : diffs_excel.append((p, h['name'], 'Kostenstelle heute anders', r['Kostenstelle'], h['kostl']))
        if h['status'] != s09: diffs_excel.append((p, h['name'], 'Status seit 09.10. geändert', s09, h['status']))
    for p, h in hcm.items():
        if p not in xl: diffs_excel.append((p, h['name'], 'fehlt in Liste', '', h['status']))
    print('\n== 1) Excel-Liste vs. HCM:', collections.Counter(x[2] for x in diffs_excel))
    for x in sorted(diffs_excel, key=lambda x: x[2]): print('   ', ' | '.join(str(v) for v in x))

# ---------------------------------------------------------------- 2) esERP-Personalstamm gegen HCM
def esd(s): return dt.date.fromisoformat(s[:10]) if s else None
today = d(TODAY)
diffs_es = []
for p, e in es.items():
    h = hcm.get(p)
    end = esd(e.get('persEndDat')); start = esd(e.get('persStartDat'))
    es_active = end is None or end >= today
    login = logins.get(p)
    who = f"{e.get('firma1') or ''}, {e.get('vorname') or ''}"
    if not h:
        diffs_es.append((p, who, 'im esERP, nicht in HCM 298', fmt(end), 'Anmeldung' if login else '')); continue
    if h['status'] == 'aktiv' and not es_active:
        kind = 'HCM aktiv, esERP beendet' + (' (fiktiv? Austritt in der Zukunft geplant nein)' if not h['planned_exit'] else '')
        diffs_es.append((p, h['name'], 'HCM aktiv, esERP Austritt gesetzt', fmt(end), f"KST {h['kostl']} · {h['job'] or h['position']}"))
    if h['status'] != 'aktiv' and es_active:
        diffs_es.append((p, h['name'], 'HCM ausgetreten, esERP aktiv', fmt(end), f"HCM-Austritt {fmt(h['exit'])}" + (' · hat Anmeldung' if login else '')))
    if h['status'] != 'aktiv' and not es_active and h['exit'] and end != h['exit']:
        diffs_es.append((p, h['name'], 'Austrittsdatum abweichend', fmt(end), fmt(h['exit'])))
    if h['planned_exit'] and (end is None or end > h['planned_exit']):
        diffs_es.append((p, h['name'], 'geplanter Austritt fehlt im esERP', fmt(end), fmt(h['planned_exit'])))
    if (e.get('email') or '').lower() != (h['mail'] or '') and h['status'] == 'aktiv':
        diffs_es.append((p, h['name'], 'E-Mail abweichend', e.get('email') or '', h['mail'] or ''))
for x in unmatched_es:
    diffs_es.append((str(x['personalNr']), f"{x.get('firma1') or ''}, {x.get('vorname') or ''}", 'im esERP, in HCM 298 nicht gefunden', fmt(esd(x.get('persEndDat'))), ('Anmeldung ' + str(x['_login'].get('lizenzArt'))) if x['_login'] else ''))
for p, h in hcm.items():
    if p not in es and h['status'] == 'aktiv':
        diffs_es.append((p, h['name'], 'HCM aktiv, fehlt im esERP', '', f"KST {h['kostl']} · {h['site']} · {h['job'] or h['position']}"))
# Mehrfach aktiv: gleiche Person (Name) mit mehreren aktiven HCM-Nummern – oft vergessener Austritt beim Wechsel 290 ↔ 298
dup = collections.defaultdict(list)
for p, h in hcm.items():
    if h['status'] == 'aktiv': dup[norm(h['name'])].append(p)
for k, ps in dup.items():
    if len(ps) > 1:
        desc = ' / '.join(f"{q} BK {hcm[q]['bukrs_now']} KST {hcm[q]['kostl']} seit {fmt(hcm[q]['entry'])}" + (' (esERP)' if q in es else '') for q in sorted(ps))
        for q in ps: diffs_es.append((q, hcm[q]['name'], 'mehrfach aktiv in HCM', '', desc))
print('\n== 2) esERP vs. HCM:', collections.Counter(x[2] for x in diffs_es))
for x in sorted(diffs_es, key=lambda x: x[2]): print('   ', ' | '.join(str(v) for v in x))
json.dump({'excel': diffs_excel, 'eserp': diffs_es}, open(os.path.join(data, 'diffs.json'), 'w'), ensure_ascii=False, default=str)

# ---------------------------------------------------------------- 3) Einordnung: was sagt HCM, was ist im esERP gepflegt
if os.environ.get('KREUZ'):
    act = {p: h for p, h in hcm.items() if h['status'] == 'aktiv'}
    print('\n== 3a) Aktive nach Stelle (HCM) × esERP-Personalart × Lizenzart')
    ct = collections.Counter()
    for p, h in act.items():
        e = es.get(p)
        ct[(h['job'] or h['position'] or '(keine Stelle)', e.get('personalArt') if e else 'nicht im esERP', (e['_login'] or {}).get('lizenzArt', '-') if e else '-')] += 1
    for k, v in sorted(ct.items(), key=lambda kv: (kv[0][0], str(kv[0][1]))): print(f'   {v:3} | {k[0]:<28} | Art {k[1]} | Lizenz {k[2]}')
    print('\n== 3b) Aktive nach Kostenstelle × Organisationseinheit')
    ct = collections.Counter((h['kostl'], h['org']) for h in act.values())
    for k, v in sorted(ct.items()): print(f'   {v:3} | KST {k[0]:<4} | {k[1]}')
    print('\n== 3c) Organisationspfade (oberste Ebenen)')
    ct = collections.Counter(' › '.join(h['org_path'].split(' › ')[:3]) for h in act.values())
    for k, v in ct.most_common(40): print(f'   {v:3} | {k}')
    print('\n== 3d) Aktive je Bereich × Stelle: im esERP / mit Anmeldung (Lizenz 1 = Techniker, 0 = Innendienst)')
    ct = collections.defaultdict(lambda: [0, 0, 0, 0])
    for p, h in act.items():
        area = 'Objektgeschäft Bauelemente' if 'Objektgeschäft' in h['org_path'] else 'Objekt & Service' if 'Objekt & Service' in h['org_path'] else (h['site'] or '?')
        e = es.get(p); lic = (e['_login'] or {}).get('lizenzArt') if e else None
        c = ct[(area, h['job'] or '-')]; c[0] += 1; c[1] += bool(e); c[2] += lic == 0; c[3] += lic == 1
    for k, v in sorted(ct.items()): print(f'   {k[0]:<27} | {k[1]:<26} | aktiv {v[0]:2} | esERP {v[1]:2} | Lizenz0 {v[2]:2} | Lizenz1 {v[3]:2}')

# ---------------------------------------------------------------- 4) alte Liste „Wird ins esERP übertragen“ gegen tatsächlichen esERP-Stand
if os.path.exists(xl_path):
    wrong = []
    for p, r in xl.items():
        says = r.get('Wird ins esERP übertragen') == 'Ja'
        real = p in es
        if says != real: wrong.append((p, hcm.get(p, {}).get('name', r['Nachname']), 'Ja' if says else 'Nein', 'im esERP' if real else 'nicht im esERP', hcm.get(p, {}).get('kostl', ''), hcm.get(p, {}).get('status', '')))
    print('\n== 4) Spalte „Wird ins esERP übertragen“ falsch:', len(wrong), collections.Counter((w[2], w[3], w[4]) for w in wrong))
    diffs_excel += [(w[0], w[1], 'Spalte „ins esERP“ falsch', w[2], f"{w[3]} (KST {w[4]}, {w[5]})") for w in wrong]
    json.dump({'excel': diffs_excel, 'eserp': diffs_es}, open(os.path.join(data, 'diffs.json'), 'w'), ensure_ascii=False, default=str)

# ---------------------------------------------------------------- 5) Einordnung (Vorschlag) und Arbeitsmappe
NO_ESERP_KST = {'790', '791'}  # wie der Worker (EmployeeService): Fachmarkt/Online Flensburg und Objektgeschäft Bauelemente

def classify(h):
    """(Bereich, esERP-Rolle, Begründung) – Vorschlag aus HCM, Regeln siehe Blatt „Regeln“."""
    job, pos, kst = h['job'] or '', h['position'] or '', h['kostl']
    if kst == '791': return 'Objektgeschäft Bauelemente (SAP)', 'kein esERP', 'KST 791 – vom Worker ausgeschlossen'
    if kst == '790': return 'Fachmarkt/Online (SAP)', 'kein esERP', 'KST 790 – vom Worker ausgeschlossen'
    if any(w in pos for w in ('Fachmarkt', 'Onlinevertr', 'eCommerce', 'Aluminiumprofile')) or job == 'Kundenmanager FM':
        return 'Fachmarkt/Handel (SAP)', 'prüfen: eher kein esERP', f'Stelle/Planstelle „{pos or job}“'
    if 'Techniker' in job or 'Techniker' in pos:
        return 'Projekt/Service (esERP)', 'Techniker (Lizenz 1)', f'Stelle „{job}“'
    if job == 'Geringfügig Beschäftigter' or job == 'Fahrer' or not job:
        return 'Standort/Verwaltung', 'kein esERP', f'Stelle „{job or "–"}“, Planstelle „{pos}“'
    if job == 'Auszubildender':
        return 'Ausbildung', 'prüfen', 'Auszubildende – je nach Abteilung'
    return 'Projekt/Service (esERP)', 'Innendienst (Lizenz 0)', f'Stelle „{job}“, Planstelle „{pos}“'

if os.environ.get('XLSX'):
    import openpyxl
    from openpyxl.styles import Font, PatternFill, Alignment
    wb = openpyxl.Workbook()
    def sheet(title, header, rows, widths=None):
        ws = wb.create_sheet(title)
        ws.append(header)
        for c in ws[1]: c.font = Font(bold=True, color='FFFFFF'); c.fill = PatternFill('solid', fgColor='1F3A5F'); c.alignment = Alignment(wrap_text=True, vertical='top')
        for r in rows: ws.append(list(r))
        ws.freeze_panes = 'B2'; ws.auto_filter.ref = ws.dimensions
        for i, w in enumerate(widths or [], 1): ws.column_dimensions[openpyxl.utils.get_column_letter(i)].width = w
        return ws
    lic_name = {0: 'Innendienst (0)', 1: 'Techniker (1)'}
    rows = []
    issues = collections.defaultdict(list)
    for x in diffs_es: issues[x[0]].append(x[2] + (f' ({x[3]} → {x[4]})' if x[3] or x[4] else ''))
    for x in diffs_excel: issues[x[0]].append('alte Liste: ' + x[2])
    for p, h in sorted(hcm.items(), key=lambda kv: kv[1]['name']):
        e = es.get(p); lic = (e['_login'] or {}).get('lizenzArt') if e else None
        area, role, why = classify(h) if h['status'] == 'aktiv' else ('', 'kein esERP (ausgetreten)', '')
        now = 'kein esERP' if not e or not e['_login'] else lic_name.get(lic, str(lic))
        hint = ''
        if h['status'] == 'aktiv':
            if role.startswith('Techniker') and lic != 1: hint = 'Lizenz prüfen (Vorschlag Techniker)'
            elif role.startswith('Innendienst') and lic != 0: hint = 'Lizenz prüfen (Vorschlag Innendienst)'
            elif role.startswith('kein esERP') and e and e['_login']: hint = 'hat esERP-Anmeldung – nötig?'
        rows.append((p, h['name'], h['bukrs_now'], h['status'], fmt(h['entry']), fmt(h['exit']), fmt(h['planned_exit']), h['site'], h['kostl'],
                     h['org'], h['org_path'], h['job'], h['position'], h['mail'] or '',
                     e['personalNr'] if e else '', e.get('personalArt') if e else '', now, area, role, why, hint, '; '.join(issues.get(p, []))))
    for x in unmatched_es:
        rows.append(('', f"{x.get('firma1') or ''}, {x.get('vorname') or ''}", 'nicht 298/290', '', '', '', '', '', x.get('kostenstelle') or '', '', '', '', '', x.get('email') or '',
                     x['personalNr'], x.get('personalArt'), lic_name.get((x['_login'] or {}).get('lizenzArt'), 'kein esERP') if x['_login'] else 'kein esERP',
                     'Subunternehmer/Dienstkonto/anderer Buchungskreis', '', '', '', 'nur im esERP'))
    sheet('Abgleich', ['HCM-Nr.', 'Name', 'Buchungskreis', 'Status HCM', 'Eintritt', 'Austritt', 'geplanter Austritt', 'Standort', 'KST', 'Org.-Einheit',
                       'Organigramm-Pfad', 'Stelle', 'Planstelle', 'E-Mail HCM', 'esERP-Nr.', 'esERP Personalart', 'esERP-Anmeldung heute',
                       'Bereich (Vorschlag)', 'esERP-Rolle (Vorschlag)', 'Begründung', 'Hinweis', 'Abweichungen'], rows,
          [10, 28, 10, 11, 11, 11, 11, 12, 6, 24, 50, 22, 26, 30, 11, 9, 16, 28, 22, 34, 30, 60])
    sheet('Unterschiede esERP', ['Nr.', 'Name', 'Unterschied', 'esERP', 'HCM'], diffs_es, [11, 30, 38, 14, 50])
    sheet('Unterschiede alte Liste', ['HCM-Nr.', 'Name', 'Unterschied', 'alte Liste', 'HCM'], diffs_excel, [11, 30, 38, 14, 40])
    mail_rows = []
    for x in es_raw:
        if not x['_login'] or not x.get('email') or str(x['personalNr']).startswith('1001009') or x['personalNr'] in (999999, 100100100): continue
        p = next((k for k, v in es.items() if v is x), None)
        st = hcm[p]['status'] if p else 'nicht in HCM 298/290'
        mail_rows.append((x.get('email').lower(), f"{x.get('vorname') or ''} {x.get('firma1') or ''}".strip(), lic_name.get(x['_login'].get('lizenzArt'), ''), st))
    mail_rows.sort()
    sheet('Verteiler esERP-Nutzer', ['E-Mail', 'Name', 'Lizenz', 'Status HCM'], mail_rows, [36, 30, 16, 20])
    ws = wb.create_sheet('Regeln', 0)
    for line in [
        f'Mitarbeiterabgleich SAP HCM (Buchungskreise 298 und 290) ↔ esERP – Stand {fmt(today)}',
        '',
        'Quellen: SAP HCM (IT0000 Maßnahmen, IT0001 Org.-Zuordnung, IT0002 Name, IT0105 E-Mail, Organigramm HRP1000/1001), esERP-API /personal und /personal/kennwoerter (Lizenzart, ohne Kennwörter).',
        'Zuordnung esERP ↔ HCM über E-Mail (die esERP-Personalnummer ist eine von der SAP-API verschlüsselte HCM-Nummer).',
        'Austritt = Tag vor Beginn der Austrittsmaßnahme (IT0000 Status 0). Geplanter Austritt = Austrittsmaßnahme in der Zukunft.',
        '',
        'Vorschlag Einordnung (aus HCM, Reihenfolge):',
        '1. KST 791 → Objektgeschäft Bauelemente (SAP), kein esERP – schließt der Worker heute schon aus.',
        '2. KST 790 → Fachmarkt/Online Flensburg (SAP), kein esERP – schließt der Worker heute schon aus.',
        '3. Stelle „Kundenmanager FM“ oder Planstelle mit Fachmarkt/Onlinevertrieb/eCommerce/Aluminiumprofile → Fachmarkt/Handel, prüfen (eher kein esERP).',
        '4. Stelle/Planstelle „Service-Techniker“ → Projekt/Service, esERP-Techniker (Lizenz 1).',
        '5. Geringfügig Beschäftigte (Kaufm. Ang. Standort), Fahrer, ohne Stelle → kein esERP.',
        '6. Auszubildende → prüfen.',
        '7. Alle anderen (Kundenmanager ID/AD, Kaufm. Angestellte, Teamleitung, Standortleitung, BL/RVL, Projektsteuerung) → Projekt/Service, esERP-Innendienst (Lizenz 0).',
        '',
        'Spalte „Hinweis“: Vorschlag und heutige esERP-Lizenz passen nicht zusammen. Spalte „Abweichungen“: Unterschiede HCM ↔ esERP und Fehler der alten Liste vom 09.10.',
    ]: ws.append([line])
    ws.column_dimensions['A'].width = 140; ws['A1'].font = Font(bold=True, size=13)
    del wb['Sheet']
    wb.save(os.environ['XLSX'])
    print('gespeichert:', os.environ['XLSX'], '| Verteiler:', len(mail_rows))
    act = [r for r in rows if r[3] == 'aktiv']
    print('Vorschlag (aktive):', collections.Counter(r[18] for r in act))
    print('Hinweise:', collections.Counter(r[20] for r in act if r[20]))
