#!/usr/bin/env python3
"""Schreibtest SEO-Felder über die JTL-Wawi-REST-API (Spez. 1.1, J-41).

23.11.2026, mit OK von M. Piper: Prüft an EINEM Artikel, ob
  PATCH v1/items/{id}/descriptions/{kanal}/{sprache}
nur das gesendete Feld ändert (die anderen bleiben unverändert) und ob der alte Wert sauber zurückgeschrieben werden kann.
Geändert wird nur SeoMetaKeywords (Meta-Schlüsselwörter, für Google ohne Bedeutung); am Ende steht wieder der Originalwert.

Aufruf: python3 jtl_rest_seo_writetest.py <artikel-id> [kanal=2-2-5] [sprache=de]
Zugang: AppHost-User-Secrets des Shops (Parameters:jtl-base-url / jtl-api-token / jtl-app-id), Tunnel wie JtlSqlRead/run.sh.
Gibt keine Secrets aus.
"""
import json, sys, urllib.request, urllib.error, pathlib, datetime

SECRETS = pathlib.Path.home() / ".microsoft/usersecrets/5d0b606c-6faf-43b8-89cb-506956cef40b/secrets.json"
FIELDS = ["Name", "Description", "ShortDescription", "SeoPath", "SeoMetaDescription", "SeoTitleTag", "SeoMetaKeywords"]

cfg = json.loads(SECRETS.read_text(encoding="utf-8-sig"))
base = cfg["Parameters:jtl-base-url"].rstrip("/") + "/api/eazybusiness/v1/"
headers = {"Authorization": cfg["Parameters:jtl-api-token"], "X-AppId": cfg["Parameters:jtl-app-id"],
           "X-AppVersion": "1.0.0", "Accept": "application/json", "Content-Type": "application/json"}

item = int(sys.argv[1])
channel = sys.argv[2] if len(sys.argv) > 2 else "2-2-5"
lang = sys.argv[3] if len(sys.argv) > 3 else "de"


def call(method, path, body=None):
    req = urllib.request.Request(base + path, method=method, headers=headers,
                                 data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            text = r.read().decode("utf-8-sig")
            return r.status, json.loads(text) if text.strip() else None
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")[:300]


def description():
    status, body = call("GET", f"items/{item}/descriptions")
    if status != 200:
        sys.exit(f"GET descriptions: HTTP {status} {body}")
    rows = body if isinstance(body, list) else body.get("Items", body)
    for d in rows:
        if d.get("SalesChannelId") == channel and (d.get("LanguageIso") or "").lower() == lang:
            return {f: d.get(f) for f in FIELDS}
    sys.exit(f"Keine Beschreibung für Kanal {channel}/{lang}; vorhanden: {[(d.get('SalesChannelId'), d.get('LanguageIso')) for d in rows]}")


def short(v):
    return None if v is None else (v if len(v) <= 60 else f"{v[:57]}… ({len(v)} Zeichen)")


before = description()
print("Vorher:", {f: short(v) for f, v in before.items()})

marker = (before["SeoMetaKeywords"] or "") + f" [Schreibtest {datetime.datetime.now():%H:%M:%S}]"
path = f"items/{item}/descriptions/{channel}/{lang}"
status, body = call("PATCH", path, {"SeoMetaKeywords": marker})
print(f"PATCH nur SeoMetaKeywords: HTTP {status}", "" if status < 300 else body)

after = description()
changed = [f for f in FIELDS if after[f] != before[f]]
print("Geänderte Felder:", changed, "| Schlüsselwörter jetzt:", short(after["SeoMetaKeywords"]))
ok_partial = changed == ["SeoMetaKeywords"] and after["SeoMetaKeywords"] == marker

status2, body2 = call("PATCH", path, {"SeoMetaKeywords": before["SeoMetaKeywords"] or ""})
print(f"PATCH zurück auf Original: HTTP {status2}", "" if status2 < 300 else body2)
restored = description()
diff = [f for f in FIELDS if (restored[f] or "") != (before[f] or "")]
print("Abweichung zum Original nach Rückschreiben:", diff or "keine")

print("ERGEBNIS:", "OK – nur das gesendete Feld ändert sich, Rückschreiben sauber" if ok_partial and not diff
      else "PRÜFEN – siehe oben")
sys.exit(0 if ok_partial and not diff else 1)
