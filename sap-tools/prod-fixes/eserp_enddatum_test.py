"""Test in esERP (Standard DEV/esapi-test; Prod nur mit --prod und ausdrücklicher Freigabe für genau diesen Datensatz): Löscht "persEndDat": null über /personal/upsert ein Austrittsdatum?
Gleicher Weg wie esdata EmployeeStateService: Datensatz roh lesen, status/persEndDat ändern, ganz zurückschreiben.
Stellt den Ausgangszustand wieder her und prüft, dass keine anderen Felder sich ändern.
  az keyvault secret show --vault-name kv-meesenburg-prod -n c4vApiCredentials --query value -o tsv \
    | /usr/bin/python3 eserp_null_test.py [personalNr]
Prod (27.10.2026, Freigabe Nutzer): --prod 12767916 (Michael Piper, wird nicht genutzt).
"""
import json, sys, urllib.request

PROD = '--prod' in sys.argv
args = [a for a in sys.argv[1:] if a != '--prod']
if PROD and not args: sys.exit('Prod nur mit ausdrücklicher Personalnummer')
BASE = 'https://esapi.meesenburg.de' if PROD else 'https://esapi-test.meesenburg.de'
def call(path, body=None, token=None):
    req = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(),
                                 headers={'Content-Type': 'application/json', **({'Authorization': f'Bearer {token}'} if token else {})})
    with urllib.request.urlopen(req, timeout=60) as r: return json.load(r)

token = call('/login', json.loads(sys.stdin.read()))['token']
if args: nr = int(args[0])
else:
    items = call('/personal?pageNumber=1&pageSize=100', token=token)['items']
    nr = next(call(f'/personal/{i["personalNr"]}', token=token) for i in items
              if 'persEndDat' not in call(f'/personal/{i["personalNr"]}', token=token))['personalNr']
get = lambda: call(f'/personal/{nr}', token=token)
def put(status, end):
    raw = get(); raw['status'] = status; raw['persEndDat'] = end
    call('/personal/upsert', [raw], token=token)
    after = get(); return after.get('status'), after.get('persEndDat', '<fehlt>')
orig = get()
print('Datensatz', nr, '| Ausgang: status', orig.get('status'), '| persEndDat', orig.get('persEndDat', '<fehlt>'))
print('1) Ende setzen  →', put(3, '2026-12-31T00:00:00'))
print('2) null senden  →', put(1, None))
r = get(); r['status'] = orig.get('status'); r['persEndDat'] = orig.get('persEndDat')
call('/personal/upsert', [r], token=token)
final = get()
diff = {k: (orig.get(k), final.get(k)) for k in set(orig) | set(final) if orig.get(k) != final.get(k) and k not in ('aenderdat',)}
print('3) zurück       →', final.get('status'), final.get('persEndDat', '<fehlt>'), '| andere Felder geändert:', diff or 'keine')
