"""Nur lesend: Status und persEndDat aller Personal-Datensätze im esERP (Prod) → <out>/eserp_states.json.

Login-Daten (JSON aus KV-Secret c4vApiCredentials-prod) kommen über stdin, nie als Argument:
  az keyvault secret show --vault-name kv-meesenburg-prod -n c4vApiCredentials-prod --query value -o tsv \
    | /usr/bin/python3 eserp_states.py <out>
Die Liste /personal enthält weder Status noch Ende, daher Einzelabruf /personal/{nr} (leere Felder fehlen in der Antwort).
"""
import json, sys, urllib.request
from concurrent.futures import ThreadPoolExecutor

BASE = 'https://esapi.meesenburg.de'
out = sys.argv[1]

def call(path, body=None, token=None):
    req = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(),
                                 headers={'Content-Type': 'application/json', **({'Authorization': f'Bearer {token}'} if token else {})})
    with urllib.request.urlopen(req, timeout=60) as r: return json.load(r)

token = call('/login', json.loads(sys.stdin.read()))['token']
nrs, page = [], 1
while True:
    res = call(f'/personal?pageNumber={page}&pageSize=100', token=token)
    nrs += [i['personalNr'] for i in res['items']]
    if len(res['items']) < 100 or len(nrs) >= res['totalCount']: break
    page += 1
fields = ('personalNr', 'vorname', 'firma1', 'email', 'kostenstelle', 'status', 'persEndDat', 'neudat', 'aenderdat')
with ThreadPoolExecutor(6) as ex:
    detail = list(ex.map(lambda n: {k: v for k, v in call(f'/personal/{n}', token=token).items() if k in fields}, nrs))
json.dump(detail, open(f'{out}/eserp_states.json', 'w'), ensure_ascii=False, indent=1)
print(f'{len(detail)} Datensätze')
