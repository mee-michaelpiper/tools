"""Aktive Kupons aus dem JTL-Shop (Tabelle tkupon) in den .NET-Shop übernehmen (Bericht 21 B-2).

Liest nur (SELECT über tools/jtl-shop/lesen.php auf dem Timme-Server, SSH-Alias „timme-shop“), schreibt in die lokale Shop-API.
Codes werden nie ausgegeben – nur Name und Ergebnis. Wiederholbar: gleiche kKupon werden aktualisiert.

    SHOP_KEY=… python3 tools/jtl-shop/gutscheine_uebernehmen.py
"""
import json, os, ssl, subprocess, urllib.parse, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ["SHOP_KEY"]
API = os.environ.get("SHOP_API", "https://localhost:7074/api/v1/admin/coupons/import/jtl")
ACTOR = urllib.parse.quote("Übernahme Kupons JTL-Shop")

query = {"k": "SELECT kKupon, cName, cCode, cWertTyp, fWert, fMindestbestellwert, dGueltigAb, dGueltigBis, nVerwendungen, nVerwendungenBisher, "
              "nVerwendungenProKunde, kKundengruppe, cHersteller, cKategorien, cArtikel, nGanzenWKRabattieren, cAktiv FROM tkupon WHERE cAktiv='Y'"}
subprocess.run(["scp", "-q", os.path.join(HERE, "lesen.php"), "timme-shop:q.php"], check=True)
out = subprocess.run(["ssh", "timme-shop", "php q.php 2>/dev/null; rm -f q.php"], input=json.dumps(query).encode(), capture_output=True, check=True).stdout
rows = json.loads(out)["k"]
if isinstance(rows, str):
    raise SystemExit(rows)

def num(v, t=float):
    return t(v) if v not in (None, "") else t(0)

body = [{
    "kKupon": int(r["kKupon"]), "cName": r["cName"], "cCode": r["cCode"], "cWertTyp": r["cWertTyp"], "fWert": num(r["fWert"]),
    "fMindestbestellwert": num(r["fMindestbestellwert"]), "dGueltigAb": r["dGueltigAb"], "dGueltigBis": r["dGueltigBis"],
    "nVerwendungen": num(r["nVerwendungen"], int), "nVerwendungenBisher": num(r["nVerwendungenBisher"], int),
    "nVerwendungenProKunde": num(r["nVerwendungenProKunde"], int), "kKundengruppe": num(r["kKundengruppe"], int),
    "cHersteller": r["cHersteller"], "cKategorien": r["cKategorien"], "cArtikel": r["cArtikel"],
    "nGanzenWKRabattieren": num(r["nGanzenWKRabattieren"], int), "cAktiv": r["cAktiv"]} for r in rows]

req = urllib.request.Request(API, method="POST", data=json.dumps(body).encode(),
                             headers={"X-Internal-Key": KEY, "X-Staff-Actor": ACTOR, "Content-Type": "application/json"})
with urllib.request.urlopen(req, context=ssl._create_unverified_context(), timeout=60) as r:
    result = json.loads(r.read())
print(f"{len(rows)} aktive Kupons gelesen: {result['created']} neu, {result['updated']} aktualisiert")
for n in result["notes"]:
    print(" -", n)
