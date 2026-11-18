"""Überarbeitete Inhalte (out/<id>.json) in den lokalen .NET-Shop einspielen.
Entwurf speichern (die API prüft und säubert), dann: vorher veröffentlicht → wieder veröffentlichen (alte Fassung bleibt als Version),
veraltet → aus dem Shop nehmen. Schreibt pruefliste.json für die Fachabteilung."""
import json, os, ssl, sys, urllib.request, urllib.parse

KEY = os.environ["SHOP_KEY"]
BASE = "https://localhost:7074/api/v1/admin/content"
ACTOR = urllib.parse.quote("Überarbeitung (IT, Prüfung offen)")
ctx = ssl._create_unverified_context()
only = set(sys.argv[1:])
OUT = os.environ.get("OUT", "out")


def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method, data=None if body is None else json.dumps(body).encode(),
                                 headers={"X-Internal-Key": KEY, "X-Staff-Actor": ACTOR, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=60) as r:
            return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]


def count(blocks):
    return sum(1 + sum(count(c["blocks"]) for c in (b.get("columns") or [])) for b in blocks)


results = []
for name in sorted(os.listdir(OUT)):
    if not name.endswith(".json"):
        continue
    cid = name[:-5]
    if only and cid not in only:
        continue
    try:
        new = json.load(open(os.path.join(OUT, name)))
    except Exception as e:
        results.append({"id": cid, "result": f"ungültiges JSON: {e}"}); continue
    status, detail = call("GET", f"/{cid}")
    if status != 200:
        results.append({"id": cid, "result": f"nicht gefunden ({status})"}); continue
    d = detail["draft"]
    before = detail["summary"]["status"]
    for i, b in enumerate(new.get("blocks", [])):
        b.setdefault("id", f"r{i}")
        b.setdefault("props", {})
        b["props"] = {k: (v if v is None or isinstance(v, str) else str(v)) for k, v in b["props"].items()}
    save = {"title": new.get("title") or d["title"], "placement": d["placement"], "slug": d["slug"], "targetId": d["targetId"],
            "position": d["position"], "metaTitle": new.get("metaTitle", d["metaTitle"]), "metaDescription": new.get("metaDescription", d["metaDescription"]),
            "publishFromUtc": d["publishFromUtc"], "publishUntilUtc": d["publishUntilUtc"], "blocks": new.get("blocks", [])}
    s1, r1 = call("PUT", f"/{cid}", save)
    if s1 != 200:
        results.append({"id": cid, "title": save["title"], "result": f"Speichern abgelehnt ({s1}): {r1}"}); continue
    action = "Entwurf gespeichert"
    if new.get("outdated"):
        if before != "Draft":
            call("POST", f"/{cid}/unpublish"); action = "veraltet – aus dem Shop genommen"
        else:
            action = "veraltet – bleibt Entwurf"
    elif before != "Draft":
        s2, r2 = call("POST", f"/{cid}/publish")
        action = "veröffentlicht" if s2 == 200 else f"Veröffentlichen abgelehnt: {r2}"
    results.append({"id": cid, "title": save["title"], "placement": d["placement"], "position": d["position"], "target": detail["summary"]["targetName"] or d["slug"],
                    "blocksBefore": count(d["blocks"]), "blocksAfter": count(r1["draft"]["blocks"]), "result": action,
                    "outdated": bool(new.get("outdated")), "notes": new.get("notes", [])})

json.dump(results, open(OUT + "_pruefliste.json", "w"), ensure_ascii=False, indent=1)
from collections import Counter
print(len(results), "Inhalte;", Counter(r["result"].split(":")[0] for r in results))
