"""SEO-Adressen der Merkmalwerte aus dem JTL-Shop (Tabelle tseo, cKey = kMerkmalWert) in den .NET-Shop übernehmen (TODO-SEO P5a, 23.11.2026).

Liest nur (SELECT über lesen.php auf dem Timme-Server, SSH-Alias „timme-shop“), schreibt in die Shop-API (POST /admin/seo/jtl-import,
nur Pfade, keine Weiterleitungen). Die Adressen greifen beim nächsten Stammdaten-Abgleich (Admin → Abgleich). Wiederholbar.

    SHOP_KEY=… python3 merkmal_seo_uebernehmen.py            # lokal (Standard: http://localhost:5072)
    SHOP_KEY=… SHOP_API=https://…/api/v1/admin/seo/jtl-import python3 merkmal_seo_uebernehmen.py
"""
import json, os, ssl, subprocess, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ["SHOP_KEY"]
API = os.environ.get("SHOP_API", "http://localhost:5072/api/v1/admin/seo/jtl-import")
ACTOR = urllib.parse.quote("Übernahme Merkmal-Adressen JTL-Shop")

query = {"m": "SELECT cSeo, kKey FROM tseo WHERE cKey='kMerkmalWert' AND kSprache=1"}
subprocess.run(["scp", "-q", os.path.join(HERE, "lesen.php"), "timme-shop:q.php"], check=True)
out = subprocess.run(["ssh", "timme-shop", "php q.php 2>/dev/null; rm -f q.php"], input=json.dumps(query).encode(), capture_output=True, check=True).stdout
rows = json.loads(out)["m"]
if isinstance(rows, str):
    raise SystemExit(rows)

body = {"seo": [{"path": r["cSeo"], "type": "kMerkmalWert", "id": str(r["kKey"])} for r in rows if r.get("cSeo")], "redirects": []}
req = urllib.request.Request(API, method="POST", data=json.dumps(body).encode(),
                             headers={"X-Internal-Key": KEY, "X-Staff-Actor": ACTOR, "Content-Type": "application/json"})
with urllib.request.urlopen(req, context=ssl._create_unverified_context(), timeout=120) as r:
    result = json.loads(r.read())
print(f"{len(rows)} Merkmal-Adressen gelesen, {result['paths']} übernommen – greifen beim nächsten Stammdaten-Abgleich")
for n in result.get("notes", []):
    print(" -", n)
