"""Nur lesend: Wo im esERP kommen bestimmte Personalnummern vor? (z. B. vor dem Löschen von Personal)
Durchsucht in einer Datenbank (Standard esdata_live = Prod)
  - alle int/bigint-Spalten, deren Name nach Personal klingt (PERS…, …PERSNR, BEARBEITER, VERTRETER …), in allen Tabellen,
  - alle übrigen int/bigint-Spalten in Tabellen bis --max-rows Zeilen (Standard 2 Mio.).
_REV/_DET-Tabellen (Änderungsprotokoll) werden mit durchsucht, aber getrennt ausgewiesen – sie hindern das Löschen nicht.
Aufruf (aus diesem Ordner, Zugang wie run.sh):
  /usr/bin/python3 refscan.py [--db esdata_live] [--max-rows 2000000] 12767916 67410868 …
"""
import re, subprocess, sys, os
from collections import defaultdict

args = sys.argv[1:]
def opt(name, default):
    if name in args:
        i = args.index(name); v = args[i + 1]; del args[i:i + 2]; return v
    return default
DB = opt('--db', 'esdata_live'); MAX_ROWS = int(opt('--max-rows', '2000000'))
if not re.fullmatch(r'\w+', DB): sys.exit('ungültiger DB-Name')
NRS = [int(a) for a in args]
if not NRS: sys.exit('Personalnummern fehlen')
HERE = os.path.dirname(os.path.abspath(__file__))
SECRET = subprocess.run(['az', 'keyvault', 'secret', 'show', '--vault-name', 'kv-meesenburg-prod', '-n', 'esErpSqlReadonly',
                         '--query', 'value', '-o', 'tsv'], capture_output=True, text=True, check=True).stdout

def sql(*queries):
    out = subprocess.run(['dotnet', 'run', '--no-build', '--project', HERE, '--', *queries], input=SECRET,
                         capture_output=True, text=True)
    if out.returncode: sys.exit(out.stderr[-2000:])
    rows = []
    for line in out.stdout.splitlines():
        if line.startswith('   ') and not line.strip().startswith('('): rows.append([c.strip() for c in line.strip().split(' | ')])
    return rows

PERS = re.compile(r'pers|bearbeiter|vertreter|mitarb|^vk$|verkaeufer|aussendienst|innendienst|sachb|erstell|aender|benutzer|user', re.I)
cols = sql(f"""SELECT t.name, c.name, SUM(p.rows) FROM {DB}.sys.tables t
JOIN {DB}.sys.columns c ON c.object_id = t.object_id JOIN {DB}.sys.types ty ON ty.user_type_id = c.user_type_id
JOIN {DB}.sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE ty.name IN ('int', 'bigint') GROUP BY t.name, c.name""")
targets = [(t, c) for t, c, n in cols if int(n) > 0 and (PERS.search(c) or int(n) <= MAX_ROWS)]
skipped = sorted({t for t, c, n in cols if int(n) > MAX_ROWS} - {t for t, _ in targets})
print(f'{DB}: {len(targets)} Spalten werden durchsucht', file=sys.stderr)

inlist = ','.join(map(str, NRS))
queries = []
for i in range(0, len(targets), 40):
    parts = [f"SELECT '{t}' tab, '{c}' col, [{c}] nr, COUNT(*) n FROM {DB}.dbo.[{t}] WHERE [{c}] IN ({inlist}) GROUP BY [{c}]"
             for t, c in targets[i:i + 40]]
    queries.append(' UNION ALL '.join(parts))
hits = []
for i in range(0, len(queries), 5):
    hits += sql(*queries[i:i + 5])
    print(f'  {min(i + 5, len(queries))}/{len(queries)} Blöcke', file=sys.stderr)

per = defaultdict(lambda: ([], []))
for tab, col, nr, n in hits:
    log = bool(re.search(r'_(REV|DET)$', tab, re.I))
    per[int(nr)][log].append(f'{tab}.{col}={n}')
for nr in NRS:
    main, log = per.get(nr, ([], []))
    print(f'{nr}: ' + (', '.join(main) or 'keine Treffer') + (f'  | Protokoll: {", ".join(log)}' if log else ''))
if skipped: print(f'nicht durchsucht (> {MAX_ROWS} Zeilen, ohne Personal-Spalte): {", ".join(skipped)}')
