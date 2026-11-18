# Rechnungsmail-Analyse VKORG 298 als Excel (26.10.2026): Y001-Ansprechpartner ↔ Rechnungsart (KNVV-KVGR2) ↔ YDH_SD_MAILS ↔ V2.
# Eingaben = SapRead-Ausgaben im Ordner (nur Scratchpad, Kundendaten!):
#   knvv.txt (KUNNR VTWEG SPART KVGR2 LOEVM AUFSD, VKORG 298), knvk2.txt (KNVK ABTNR Y001: KUNNR PARNR PRSNR NAMEV NAME1 PAFKT ABTPA LOEVM),
#   adr6p2.txt (ADR6 PERSNUMBER<>'': PERSNUMBER CONSNUMBER FLGDEFAULT FLG_NOUSE VALID_FROM VALID_TO DATE_FROM SMTP_ADDR),
#   ydh.txt (YDH_SD_MAILS: KUNNR PERSNUMBER NAMEV PARTNER SMTP_ADDR), v2.txt (CUSTOMERID INVOICEMETHOD INVOICEMAIL),
#   v2mail.txt (CUSTOMERID MAIL STATUS), v2name.txt (CUSTOMERID NAME1 ZIPCODE CITY STATUS), knvp_re.txt (KUNNR VTWEG SPART KUNN2, PARVW RE)
# Aufruf: /usr/bin/python3 excel_y001.py <ordner>   → <ordner>/Rechnungsmail_Y001_298_<datum>.xlsx; Konsole nur Zähler
import sys, re, collections, datetime
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

d = sys.argv[1]
def rows(f): return [[x.strip() for x in l.rstrip('\n').split('|')] for l in open(f'{d}/{f}', encoding='utf-8') if '|' in l]
def k10(k): return k.zfill(10) if k.isdigit() else k
def show(k): return k.lstrip('0') or '0'

METHOD_TEXT = {'0': 'Email-Versand', '1': 'Druck Flensburg', '2': 'Druck Rellingen', '3': 'Druck Oyten', '4': 'Druck Gütersloh',
               '5': 'Druck Greifswald', 'E': 'extern (Druckstraße)', 'X': 'X-Rechnung', 'Z': 'ZUGFeRD', '': '(leer)'}
WANT = {'0': 'MAIL', 'X': 'XR', 'Z': 'ZF'}
KIND_TEXT = {'MAIL': 'per Mail', 'XR': 'XRechnung', 'ZF': 'ZUGFeRD', 'EDI': 'per EDI', 'POST': 'per Post', 'UNKLAR': 'unklar'}

def kind(name):
    n = name.lower()
    if re.search(r'\bx[\s\-\.]*rechn|xrechn', n): return 'XR'
    if 'zugferd' in n or 'zug ferd' in n: return 'ZF'
    if re.search(r'per\s+edi\b|\bedi\b', n): return 'EDI'
    if re.search(r'per\s+post|\bpost\b', n): return 'POST'
    if re.search(r'e?-?mai|ema\b|emai', n): return 'MAIL'
    return 'UNKLAR'

def valid_mail(m): return bool(re.fullmatch(r'[^@\s;,]+@[^@\s;,]+\.[A-Za-z]{2,}', m))

# --- Daten
methods = collections.defaultdict(set); blocked = {}
for k, vt, sp, kv, loevm, aufsd in rows('knvv.txt'):
    methods[k].add(kv); blocked[k] = blocked.get(k) or loevm == 'X' or bool(aufsd)
res = collections.defaultdict(set)
for k, vt, sp, k2 in rows('knvp_re.txt'):
    if k2 != k: res[k].add(k2)
names = {}
for p in rows('v2name.txt'): names.setdefault(k10(p[0]), (p[1], f'{p[2]} {p[3]}'.strip(), p[4]))
v2inv = collections.defaultdict(set)
for k, m, inv in rows('v2.txt'):
    if inv: v2inv[k10(k)].add(inv)
v2gen = {}
for k, m, s in rows('v2mail.txt'):
    if m: v2gen.setdefault(k10(k), m)
adr = collections.defaultdict(list)          # PERSNUMBER → ADR6-Zeilen
for p in rows('adr6p2.txt'):
    if len(p) >= 8 and p[7]: adr[p[0]].append(dict(cons=p[1], dflt=p[2] == 'X', nouse=p[3] == 'X', vfrom=p[4], vto=p[5], dfrom=p[6], mail=p[7]))
contacts = collections.defaultdict(list)
for kunnr, parnr, prsnr, namev, name1, pafkt, abtpa, *rest in rows('knvk2.txt'):
    nm = f'{namev} {name1}'.strip()
    a = [x for x in adr.get(prsnr, []) if not x['nouse']]
    std = [x['mail'] for x in a if x['dflt']] or [x['mail'] for x in a]
    contacts[kunnr].append(dict(parnr=parnr, prsnr=prsnr, name=nm, kind=kind(nm), mails=std, adr=a))
ydh = collections.defaultdict(list)
for kunnr, pers, namev, partner, smtp in rows('ydh.txt'):
    ydh[kunnr].append(dict(pers=pers, name=f'{namev} {partner}'.strip(), mail=smtp))

# --- Regel je Kunde: Rechnungsart des Kunden (Auftraggeber), Y001-Kontakte/Adresse des Rechnungsempfängers (RE, ohne eigenen RE: Kunde selbst)
def pick(kunnr, method):
    cs = [c for c in contacts.get(kunnr, []) if c['mails']]
    want = WANT.get(method)
    if not cs: return None, 'kein Y001 mit Mail'
    if len(cs) == 1:
        c = cs[0]
        if c['kind'] == want: return c, 'eindeutig'
        if want == 'ZF' and c['kind'] == 'MAIL': return c, 'eindeutig (per Mail bei ZUGFeRD)'
        return c, f"1 Kontakt, Name „{KIND_TEXT[c['kind']]}“ passt nicht zu {METHOD_TEXT[method]}"
    m = [c for c in cs if c['kind'] == want] or ([c for c in cs if c['kind'] == 'MAIL'] if want == 'ZF' else [])
    if len(m) == 1: return m[0], 'mehrere Kontakte, genau einer passt'
    if len(m) > 1:
        # verschiedene Mails: nicht raten (FLGDEFAULT gilt nur je Kontakt, nicht zwischen Kontakten) → leer + Sync-Hinweis
        if len({c['mails'][0].lower() for c in m}) > 1: return None, 'mehrere passende, verschiedene Mails'
        return sorted(m, key=lambda c: c['parnr'])[0], 'mehrere passende, gleiche Mail'
    return None, f'mehrere Kontakte, keiner passt zu {METHOD_TEXT[method]}'

FALL = {
    'F1': ('Mehrere passende Y001 mit verschiedenen Mails', 'Keine Rechnungsmail (nicht raten) + Sync-Hinweis – überflüssigen Kontakt in SAP löschen oder umbenennen.'),
    'F2': ('Mehrere Y001, keiner passt zur Rechnungsart', 'Kontaktname an die Rechnungsart anpassen (z. B. „Rechnung per Mail“ / „XRechnung“) oder Rechnungsart prüfen.'),
    'F3': ('Ein Y001, Name passt nicht zur Rechnungsart', 'Name oder Rechnungsart prüfen (z. B. „per EDI“ bei Email-Versand, „per Mail“ bei XRechnung).'),
    'F4': ('Mehrere Y001, genau einer passt', 'Mit Regel eindeutig; heute liefert V2 alle Zeilen, im esERP gewinnt zufällig eine. Überflüssigen Kontakt prüfen.'),
    'F5': ('Rechnungskontakt mit mehreren Mailadressen', 'Nur eine Adresse je Rechnungskontakt pflegen (heute: Standardadresse genommen).'),
    'F6': ('Mailadresse formal ungültig', 'Adresse korrigieren (mehrere Adressen in einem Feld, Leerzeichen, Tippfehler).'),
    'F7': ('Elektronischer Versand, aber keine Mailadresse', 'Y001-Kontakt „Rechnung per Mail“/„XRechnung“ mit Adresse anlegen oder Rechnungsart prüfen.'),
    'F8': ('Mailadresse länger als 60 Zeichen', 'Heute in V2 abgeschnitten – nach Umstellung (direkt lesen) erledigt, nur Kontrolle.'),
    'F9': ('Rechnungsempfänger mit Auftraggebern unterschiedlicher Rechnungsart', 'Worker nimmt heute die Rechnungsart des ersten Auftraggebers dieses RE – Versandart kann falsch sein. Erledigt mit Worker-Fix (Rechnungsart je Kunde).'),
    'F10': ('Rechnungsempfänger hat andere Rechnungsart als der Kunde', 'Nur Info: es gilt die Rechnungsart des Kunden, der Kontakt am RE wird danach gewählt (bestätigt 26.10.2026). Passt am RE kein Kontakt → F2/F3/F7.'),
    'F11': ('Kunde hat eigene Rechnungsmail, RE keine', 'Nach Logik (Adresse vom RE) keine Rechnungsmail. Y001-Kontakt am RE anlegen oder RE/Rechnungsart prüfen.'),
    'F12': ('Eigene Rechnungsmail des Kunden ≠ Mail am RE', 'Nur Info zur Kontrolle: verwendet wird die Mail am RE, die am Kunden gepflegte ist dafür wirkungslos.'),
}
issues = []          # (fall, kunnr, detail, regelmail)
per_customer = {}    # kunnr → (method, befund, regel-mail, contact)
re_first = {}
for k, rs in res.items(): re_first[k] = sorted(rs)[0]
by_re = collections.defaultdict(list)
for k, r in re_first.items(): by_re[r].append(k)
mixed_re = {r for r, ks in by_re.items() if len(ks) > 1 and len({min(methods.get(x, {''})) for x in ks}) > 1}

def src_of(k): return re_first.get(k, k)     # Adressquelle: RE, sonst der Kunde selbst
own_rule = {}        # kunnr → Mail nach Regel mit den eigenen Kontakten (nur Kunden mit anderem RE, zum Vergleich)

for kunnr, ms in methods.items():
    method = sorted(m for m in ms if m in WANT)[0] if any(m in WANT for m in ms) else min(ms)
    own_re = not res.get(kunnr)
    src = src_of(kunnr)
    if method in WANT:
        c, why = pick(src, method)
        mail = c['mails'][0] if c else ''
        if not own_re:
            oc, _ = pick(kunnr, method)
            own_rule[kunnr] = oc['mails'][0] if oc else ''
            if own_rule[kunnr] and not mail and why == 'kein Y001 mit Mail': issues.append(('F11', kunnr, f'eigene Mail {own_rule[kunnr]}, RE {show(src)} ohne passenden Y001', ''))
            elif own_rule[kunnr] and mail and own_rule[kunnr].lower() != mail.lower(): issues.append(('F12', kunnr, f'eigene: {own_rule[kunnr]}', mail))
        per_customer[kunnr] = (method, why, mail, c)
        cs = contacts.get(src, [])
        desc = ' | '.join(f"{c2['parnr']} {c2['name']} [{KIND_TEXT[c2['kind']]}]" + (f": {', '.join(c2['mails'])}" if why.startswith('mehrere passende, versch') else '') for c2 in cs)
        if why == 'mehrere passende, verschiedene Mails': issues.append(('F1', kunnr, desc, mail))
        elif why.startswith('mehrere Kontakte, keiner'): issues.append(('F2', kunnr, desc, mail))
        elif why.startswith('1 Kontakt'): issues.append(('F3', kunnr, desc, mail))
        elif why == 'mehrere Kontakte, genau einer passt': issues.append(('F4', kunnr, desc, mail))
        elif why == 'kein Y001 mit Mail' and not own_rule.get(kunnr):
            issues.append(('F7', kunnr, ('' if own_re else f'RE {show(src)}; ') + ('gesperrt/gelöscht; ' if blocked.get(kunnr) else 'aktiv; ')
                           + ('allgemeine Mail vorhanden' if v2gen.get(src) else 'gar keine Mail'), ''))
        for c2 in cs:
            if len(c2['mails']) > 1 or len({x['mail'] for x in c2['adr']}) > 1:
                issues.append(('F5', kunnr, f"{c2['parnr']} {c2['name']}: {len({x['mail'] for x in c2['adr']})} Adressen", c2['mails'][0] if c2['mails'] else ''))
        if mail and not valid_mail(mail): issues.append(('F6', kunnr, f'„{mail}“', mail))
        if len(mail) > 60: issues.append(('F8', kunnr, f'{len(mail)} Zeichen, V2: {", ".join(v2inv.get(src, []))}', mail))
    if not own_re:
        r = re_first[kunnr]
        rm = sorted(methods.get(r, {''}))[0] if methods.get(r) else None
        if r in mixed_re:
            first = by_re[r][0]
            issues.append(('F9', kunnr, f'RE {show(r)} hat {len(by_re[r])} Auftraggeber; dieser {METHOD_TEXT.get(method, method)}, Worker nimmt die von {show(first)}: '
                           f'{METHOD_TEXT.get(min(methods.get(first, {""})), "?")}', ''))
        if rm is not None and rm != method:
            issues.append(('F10', kunnr, f'Auftraggeber {METHOD_TEXT.get(method, method)} ↔ RE {show(r)} {METHOD_TEXT.get(rm, rm)}', ''))
        elif rm is None:
            issues.append(('F10', kunnr, f'RE {show(r)} nicht in VKORG 298', ''))

# --- YDH-Logik bei mehreren Adressen: Kennzeichen der ADR6-Zeilen je Kontakt mit >1 Adresse
multi = []
for kunnr, cs in contacts.items():
    if kunnr not in methods: continue
    for c in cs:
        if len({x['mail'] for x in adr.get(c['prsnr'], [])}) > 1: multi.append((kunnr, c))

# --- Excel
wb = openpyxl.Workbook()
HEAD = Font(bold=True, color='FFFFFF'); FILL = PatternFill('solid', fgColor='1F4E78'); MARK = PatternFill('solid', fgColor='E2EFDA')
def sheet(title, header, data, widths):
    ws = wb.create_sheet(title)
    ws.append(header)
    for c in ws[1]: c.font = HEAD; c.fill = FILL; c.alignment = Alignment(vertical='top', wrap_text=True)
    for r in data: ws.append(r)
    for i, w in enumerate(widths, 1): ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = 'A2'; ws.auto_filter.ref = ws.dimensions
    return ws
def cname(k): n = names.get(k, ('', '', '')); return n[0], n[1]

ov = wb.active; ov.title = 'Übersicht'
ov.append(['Rechnungsmail VKORG 298 – Y001-Ansprechpartner je Rechnungsart', '', f'Stand {datetime.date.today():%d.%m.%Y}, Quelle SAP MEP'])
ov['A1'].font = Font(bold=True, size=13)
ov.append([])
ov.append(['Regel (Vorschlag)', 'Rechnungsart (KNVV-KVGR2) des Kunden → Y001-Kontakt des Rechnungsempfängers (ohne eigenen RE: des Kunden), dessen Name passt: 0 Email-Versand → „…mail…“, X → „xrechnung“, '
           'Z ZUGFeRD → „zugferd“, sonst „…mail…“. Mehrere passende Kontakte mit verschiedenen Mails → keine Mail + Sync-Hinweis (F1). Adresse = ADR6-Standardadresse (nicht „nicht verwenden“). Heute (V2/V1): keine Namenslogik, je Kontakt/Adresse eine Zeile.'])
ov.append([])
ov.append(['Fall', 'Fallstrick', 'Kunden', 'Was tun'])
for c in ov[5]: c.font = HEAD; c.fill = FILL
cnt = collections.Counter(f for f, *_ in issues)
for f, (t, todo) in FALL.items(): ov.append([f, t, len({k for ff, k, *_ in issues if ff == f}), todo])
ov.append([])
ov.append(['Rechnungsarten (elektronisch)', ', '.join(f'{METHOD_TEXT[m]}: {sum(1 for v in per_customer.values() if v[0] == m)}' for m in WANT)])
ov.append(['Befund je Kunde', '; '.join(f'{k}: {v}' for k, v in collections.Counter(v[1] for v in per_customer.values()).most_common())])
ov.append(['Heute (V2 des RE bzw. Kunden) = Regel', sum(1 for k, v in per_customer.items() if v[2] and v2inv.get(src_of(k)) == {v[2][:60]})])
ov.append(['Kunden mit anderem RE (elektronisch)', f'{len(own_rule)}: Adresse vom RE, Rechnungsart vom Kunden. Eigene Mail = RE-Mail: '
           f'{sum(1 for k, m in own_rule.items() if m and m.lower() == per_customer[k][2].lower())}, verschieden (F12): {len({k for f, k, *_ in issues if f == "F12"})}, '
           f'nur eigene (F11): {len({k for f, k, *_ in issues if f == "F11"})}, nur RE: {sum(1 for k, m in own_rule.items() if not m and per_customer[k][2])}, '
           f'keine: {sum(1 for k, m in own_rule.items() if not m and not per_customer[k][2])}'])
ov.append([])
ov.append(['Mehrere Adressen je Kontakt (YDH)', f'{len(multi)} Kontakte. Standardkennzeichen gesetzt bei {sum(1 for _, c in multi if any(x["dflt"] for x in adr[c["prsnr"]]))}; '
           f'Gültigkeit (VALID_TO) gepflegt bei {sum(1 for _, c in multi if any(x["vto"] not in ("", "00000000") for x in adr[c["prsnr"]]))}. '
           'YDH_SD_MAILS liefert alle Adressen ohne Kennzeichen – Logik nur über FLGDEFAULT (Blatt „Mehrere Adressen“).'])
ov.column_dimensions['A'].width = 30; ov.column_dimensions['B'].width = 70; ov.column_dimensions['C'].width = 12; ov.column_dimensions['D'].width = 100
for row in ov.iter_rows(): [setattr(c, 'alignment', Alignment(wrap_text=True, vertical='top')) for c in row]

# Blatt: unstimmige Kunden
data = []
for f, k, detail, mail in sorted(issues, key=lambda x: (int(x[0][1:]), x[1])):
    n, ort = cname(k); m = per_customer.get(k, (sorted(methods.get(k, {''}))[0],))[0]
    data.append([f, FALL[f][0], show(k), n, ort, METHOD_TEXT.get(m, m), ', '.join(show(r) for r in sorted(res.get(k, []))), detail, mail,
                 ', '.join(sorted(v2inv.get(src_of(k), []))), FALL[f][1]])
sheet('Unstimmige Kunden', ['Fall', 'Fallstrick', 'Kunde', 'Name', 'PLZ Ort', 'Rechnungsart', 'Rechnungsempfänger', 'Detail / Y001-Kontakte',
                            'Mail nach Regel', 'Mail heute (V2)', 'Was tun'], data, [6, 38, 11, 34, 24, 18, 14, 70, 36, 36, 60])

# Blatt: Y001 + YDH je Kontakt/Adresse (Kunden mit Befund ≠ eindeutig oder Abweichung zu V2)
focus = {k for f, k, *_ in issues if f in ('F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F8')} | {k for k, v in per_customer.items() if len(v2inv.get(src_of(k), set())) > 1}
data = []; marks = []
for k in sorted(focus):
    method, why, rule, chosen = per_customer.get(k, ('', '', '', None))
    n, ort = cname(k)
    src = src_of(k)
    yrows = ydh.get(src, [])
    for c in contacts.get(src, []) or [None]:
        alist = (c['adr'] if c else []) or [None]
        for a in alist:
            yd = [y for y in yrows if c and y['pers'] == c['prsnr'] and a and y['mail'] == a['mail']]
            data.append([show(k), n, ort, METHOD_TEXT.get(method, method), why, rule, ', '.join(sorted(v2inv.get(src, []))),
                         c['parnr'] if c else '', c['name'] if c else '', KIND_TEXT[c['kind']] if c else '',
                         a['mail'] if a else '', a['cons'] if a else '', 'X' if a and a['dflt'] else '', a['vfrom'] if a else '', a['vto'] if a else '',
                         'ja' if yd else ('–' if not a else 'nein'), len(yrows), len(contacts.get(src, [])), ', '.join(show(r) for r in sorted(res.get(k, []))),
                         'X' if a and rule and a['mail'] == rule and c is chosen else ''])
            marks.append(bool(a and rule and a['mail'] == rule and c is chosen))
ws = sheet('Y001 und YDH je Adresse', ['Kunde', 'Name', 'PLZ Ort', 'Rechnungsart', 'Befund', 'Mail nach Regel', 'Mail heute (V2)', 'Kontakt (PARNR)', 'Kontaktname',
                                        'Namensart', 'Adresse (ADR6)', 'CONSNUMBER', 'Standard', 'gültig ab', 'gültig bis', 'in YDH_SD_MAILS',
                                        'YDH-Zeilen Kunde', 'Y001 Kunde', 'Rechnungsempfänger', 'gewählt'],
           data, [11, 30, 22, 16, 34, 34, 34, 12, 34, 12, 36, 11, 9, 11, 11, 10, 9, 9, 14, 8])
for i, m in enumerate(marks, 2):
    if m:
        for c in ws[i]: c.fill = MARK

# Blatt: alle Kunden – die drei Quellen nebeneinander (V2 = YDD_CUSTOMERS_V2, ADR6 direkt über KNVK Y001, YDH_SD_MAILS),
# jeweils von der Adressquelle (RE, ohne eigenen RE der Kunde selbst); eigene Y001 des Kunden zum Vergleich
def direct_txt(k): return [f"{c['name']}: {a['mail']}{' (Standard)' if a['dflt'] and len(c['adr']) > 1 else ''}" for c in contacts.get(k, []) for a in c['adr']]
data = []; flags = []
for k in sorted(methods):
    method, why, rule, chosen = per_customer.get(k, (sorted(methods[k])[0], '', '', None))
    src = src_of(k); other = src != k
    v2 = sorted(v2inv.get(src, []))
    direct = direct_txt(src)
    yd = ydh.get(src, [])
    yd_txt = [f"{y['name']}: {y['mail']}" for y in yd]
    own = direct_txt(k) if other else []
    if not (v2 or direct or yd_txt or own or method in WANT): continue
    n, ort = cname(k)
    v2_ok = 'ja' if rule and v2 == [rule[:60]] else ('mehrere' if len(v2) > 1 else 'nein' if v2 or rule else '')
    cut = 'ja' if any(len(y['mail']) > 60 and y['mail'][:60] in v2 for y in yd) else ''
    om = own_rule.get(k, '')
    cmp_own = '' if not other or method not in WANT else ('beide leer' if not om and not rule else 'nur RE' if not om else 'nur eigene' if not rule
                                                           else 'gleich' if om.lower() == rule.lower() else 'verschieden')
    data.append([show(k), n, ort, METHOD_TEXT.get(method, method), show(src) if other else '', 'RE' if other else 'Kunde',
                 len(v2), '\n'.join(v2), len(direct), '\n'.join(direct), len(yd_txt), '\n'.join(yd_txt),
                 rule, why, v2_ok, 'ja' if rule and any(y['mail'] == rule for y in yd) else ('' if not rule else 'nein'), cut,
                 '\n'.join(own), om, cmp_own])
    flags.append(v2_ok != 'ja' and method in WANT)
ws = sheet('Alle Kunden – 3 Quellen', ['Kunde', 'Name', 'PLZ Ort', 'Rechnungsart (Kunde)', 'Rechnungsempfänger', 'Adresse von',
                                       'V2 Anzahl', 'YDD_CUSTOMERS_V2 INVOICEMAIL', 'ADR6 Anzahl', 'ADR6 direkt (KNVK Y001 → ADR6): Kontakt: Adresse',
                                       'YDH Anzahl', 'YDH_SD_MAILS: Name: Adresse', 'Mail nach Regel', 'Befund', 'V2 = Regel', 'YDH enthält Regel', 'V2 gekürzt',
                                       'Vergleich: eigene Y001 des Kunden (ADR6)', 'Vergleich: Regel mit eigenen Kontakten', 'eigene ↔ RE'],
           data, [11, 30, 22, 16, 14, 9, 7, 38, 7, 55, 7, 55, 36, 34, 10, 10, 9, 50, 36, 11])
for row in ws.iter_rows(min_row=2):
    for c in (row[7], row[9], row[11], row[17]): c.alignment = Alignment(wrap_text=True, vertical='top')
print('Blatt Alle Kunden:', len(data), 'Zeilen, davon elektronisch mit V2 ≠ Regel:', sum(flags))

# Blatt: mehrere Adressen je Kontakt
data = []
for k, c in multi:
    n, ort = cname(k)
    for a in sorted(adr[c['prsnr']], key=lambda x: x['cons']):
        data.append([show(k), n, METHOD_TEXT.get(per_customer.get(k, ('',))[0], ''), c['parnr'], c['name'], a['cons'], 'X' if a['dflt'] else '',
                     'X' if a['nouse'] else '', a['vfrom'], a['vto'], a['dfrom'], a['mail'], ', '.join(sorted(v2inv.get(k, [])))])
sheet('Mehrere Adressen', ['Kunde', 'Name', 'Rechnungsart', 'Kontakt (PARNR)', 'Kontaktname', 'CONSNUMBER', 'Standard', 'nicht verwenden', 'gültig ab',
                           'gültig bis', 'angelegt', 'Adresse', 'Mail heute (V2)'], data, [11, 30, 16, 12, 34, 11, 9, 9, 11, 11, 11, 40, 40])

out = f'{d}/Rechnungsmail_Y001_298_{datetime.date.today():%Y-%m-%d}.xlsx'
wb.save(out)
print('Fälle:', dict(sorted(cnt.items(), key=lambda x: int(x[0][1:]))))
print('Kunden je Fall:', {f: len({k for ff, k, *_ in issues if ff == f}) for f in FALL})
print('Kontakte mit mehreren Adressen:', len(multi), ' Zeilen Blatt Y001/YDH:', len(marks))
print('gespeichert:', out)
