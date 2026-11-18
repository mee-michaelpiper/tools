# Analyse Y001-Ansprechpartner ↔ Rechnungsart (KNVV-KVGR2), VKORG 298 – 26.10.2026
# Eingaben (SapRead-Ausgaben, nur im Scratchpad): knvv.txt, knvk2.txt, adr6p.txt, v2.txt, knvp_re.txt
# Aufruf: python3 analyse_y001.py <ordner>   – Konsole nur Zähler; Details als y001_befund.csv in den Ordner
import sys,collections,re,csv
d=sys.argv[1]
def rows(f): return [[x.strip() for x in l.rstrip('\n').split('|')] for l in open(f'{d}/{f}') if '|' in l]
def kind(name):
    n=name.lower()
    if re.search(r'\bx[\s\-\.]*rechn|xrechn',n): return 'XR'
    if 'zugferd' in n or 'zug ferd' in n: return 'ZF'
    if re.search(r'per\s+edi\b|\bedi\b',n): return 'EDI'
    if re.search(r'per\s+post|\bpost\b',n): return 'POST'
    if re.search(r'e?-?mai|ema\b|emai',n): return 'MAIL'
    return 'UNKLAR'
WANT={'0':'MAIL','X':'XR','Z':'ZF'}
knvv=collections.defaultdict(set)
for k,vtweg,spart,kvgr2,*_ in rows('knvv.txt'): knvv[k].add(kvgr2)
re_=collections.defaultdict(set)
for k,vt,sp,k2 in rows('knvp_re.txt'): re_[k].add(k2)
adr=collections.defaultdict(list)
for p in rows('adr6p.txt'): adr[p[0]].append(p)
def mails(prsnr):
    a=[x for x in adr.get(prsnr,[]) if x[4] and x[3]!='X']
    dflt=[x[4] for x in a if x[2]=='X']
    return dflt or [x[4] for x in a]
con=collections.defaultdict(list)
for kunnr,parnr,prsnr,namev,name1,*_ in rows('knvk2.txt'):
    con[kunnr].append(dict(parnr=parnr,kind=kind(f'{namev} {name1}'),mails=mails(prsnr)))
v2=collections.defaultdict(set)
for k,m,inv in rows('v2.txt'):
    if inv: v2[k.zfill(10) if k.isdigit() else k].add(inv)
C=collections.Counter(); out=[]
def pick(kunnr,method):
    cs=[c for c in con.get(kunnr,[]) if c['mails']]
    if not cs: return None,'kein Y001 mit Mail'
    want=WANT.get(method)
    if len(cs)==1:
        c=cs[0]
        if c['kind']==want: return c,'eindeutig (1 Kontakt, Name passt)'
        if want=='ZF' and c['kind']=='MAIL': return c,'1 Kontakt „per Mail“ bei ZUGFeRD'
        return c,f"1 Kontakt, Name {c['kind']} ≠ Rechnungsart {want}"
    m=[c for c in cs if c['kind']==want] or ([c for c in cs if c['kind']=='MAIL'] if want=='ZF' else [])
    if len(m)==1: return m[0],f'mehrere Kontakte, genau einer passt'
    if len(m)>1:
        same=len({x for c in m for x in c['mails'][:1]})==1
        return sorted(m,key=lambda c:c['parnr'])[0], 'mehrere passende, gleiche Mail' if same else 'mehrere passende, VERSCHIEDENE Mails'
    return None,f'mehrere Kontakte, keiner passt zu {want}'
for kunnr,methods in knvv.items():
    el=[m for m in methods if m in WANT]
    if not el: C['nicht elektronisch (Post/Druck/leer)']+=1; continue
    if len(methods)>1: C[f'A Rechnungsart je Vertriebsweg/Sparte verschieden: {"/".join(sorted(methods))}']+=1
    method=sorted(el)[0]
    C[f'Rechnungsart {method}']+=1
    rs=re_.get(kunnr,set())-{kunnr}
    if rs: C['B Rechnungsempfänger ist ein anderer Kunde']+=1
    if len(re_.get(kunnr,set()))>1: C['B mehrere Rechnungsempfänger je Vertriebsweg/Sparte']+=1
    c,why=pick(kunnr,method)
    C[f'C [{method}] {why}']+=1
    mine=c['mails'][0] if c else ''
    if c and len(c['mails'])>1: C['D Kontakt mit mehreren Mails (Standard genommen)']+=1
    if mine and not re.fullmatch(r'[^@\s;,]+@[^@\s;,]+\.[A-Za-z]{2,}',mine): C['E Mail formal ungültig/mehrere Adressen im Feld']+=1
    cur=v2.get(kunnr,set())
    st='gleich' if cur=={mine[:60]} and mine else 'V2 leer' if not cur else 'Regel leer' if not mine else 'V2 mehrere' if len(cur)>1 else 'abweichend'
    C[f'F heute (V2) vs. Regel: {st}']+=1
    if st!='gleich' or 'gleich' not in why and 'eindeutig' not in why:
        out.append([kunnr,'/'.join(sorted(methods)),why,st,len(con.get(kunnr,[])),' | '.join(f"{x['kind']}:{(x['mails'] or [''])[0]}" for x in con.get(kunnr,[])),' '.join(cur),' '.join(sorted(rs))])
for k,v in sorted(C.items()): print(f'{v:6}  {k}')
with open(f'{d}/y001_befund.csv','w',newline='') as f:
    w=csv.writer(f,delimiter=';'); w.writerow(['kunde','rechnungsart','befund','v2_vergleich','anzahl_y001','kontakte','v2_mail','rechnungsempfaenger']); w.writerows(out)
print('Details:',len(out),'Zeilen in y001_befund.csv')
