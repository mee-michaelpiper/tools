#!/usr/bin/env python3
"""Neue App-Registrierung für den .NET-Shop an der JTL-Wawi-REST-API (Spez. 1.1, Wawi 1.11).

23.11.2026. Ersetzt die App `icsWebshop/v1` des Alt-Dienstleisters (Token kompromittiert, ohne Artikel-Schreibrechte, J-43).

Ablauf (laut JTL-Spezifikation):
  1. In der JTL-Wawi (neue Oberfläche) unter „Admin → App-Registrierung“ die Registrierung starten (Wawi wartet dann auf eine App).
  2. Dieses Skript starten: es sendet POST /authentication mit App-Daten und Rechten (Scopes).
  3. In der Wawi erscheint die Anfrage → Rechte prüfen und bestätigen.
  4. Das Skript fragt GET /authentication/{id} ab, bis der API-Schlüssel kommt (wird nur EINMAL ausgeliefert!)
     und schreibt ihn direkt in die AppHost-User-Secrets des Shops (Parameters:jtl-api-token / jtl-app-id).
     Der Schlüssel wird nie ausgegeben. Die alte Datei wird vorher als secrets.json.bak-<zeit> gesichert.

Aufruf: python3 jtl_app_register.py [--dry-run]
  --dry-run: zeigt nur App-Daten und Scopes, sendet nichts.
Basis-URL: Parameters:jtl-base-url aus den User-Secrets (Tunnel wie JtlSqlRead/run.sh, Port 50443).
"""
import json, sys, time, secrets as rnd, pathlib, shutil, datetime, urllib.request, urllib.error

SECRETS = pathlib.Path.home() / ".microsoft/usersecrets/5d0b606c-6faf-43b8-89cb-506956cef40b/secrets.json"
SPEC = pathlib.Path.home() / "repos/sise-docs/shop/referenz/jtl-wawi-api/jtl-wawi-api-1.1_wawi-1.11.0.0_openapi.json"

APP_ID = "MeesenburgShop/v1"
# Lesen: alles. Schreiben: nur, was der Shop braucht (Aufträge, Kunden) + SEO-Rückschreiben (TODO-SEO P1/P5a/P6a)
MANDATORY = [
    "all.read",
    "customer.createcustomer",
    "salesorder.createsalesorder", "salesorder.createsalesorderlineitem", "salesorder.createsalesordernote",
    "salesorder.cancelsalesorder",
    "item.updateitemdescription", "item.createitemdescription",
    "category.updatecategorydescription", "category.createcategorydescription",
    "property.updatepropertyvaluedescription", "property.createpropertyvaluedescription",
]
OPTIONAL = ["item.updateitemimage"]

cfg = json.loads(SECRETS.read_text(encoding="utf-8-sig"))
base = cfg["Parameters:jtl-base-url"].rstrip("/") + "/api/eazybusiness/v1/"

known = json.loads(SPEC.read_text())["components"]["securitySchemes"]["oauth2-authorization-code"]["flows"]["authorizationCode"]["scopes"]
unknown = [s for s in MANDATORY + OPTIONAL if s not in known]
if unknown:
    sys.exit(f"Unbekannte Scopes laut Spezifikation: {unknown}")

body = {
    "AppId": APP_ID,
    "DisplayName": "Meesenburg Shop",
    "Description": "Onlineshop sicherheit.meesenburg.com (.NET): Katalog lesen, Aufträge und Kunden anlegen, SEO-Texte pflegen",
    "Version": "1.0.0",
    "ProviderName": "Meesenburg GmbH",
    "ProviderWebsite": "https://sicherheit.meesenburg.com",
    "MandatoryApiScopes": MANDATORY,
    "OptionalApiScopes": OPTIONAL,
}
print("App:", APP_ID, "| Pflicht-Scopes:", len(MANDATORY), "| optional:", OPTIONAL)
if "--dry-run" in sys.argv:
    print(json.dumps(body, indent=2, ensure_ascii=False))
    sys.exit(0)

challenge = rnd.token_hex(16)  # frei gewählt, muss bei beiden Aufrufen gleich sein
headers = {"Content-Type": "application/json", "Accept": "application/json",
           "X-ChallengeCode": challenge, "X-Tenant-Id": cfg.get("Parameters:jtl-tenant-id", "")}


def call(method, path, payload=None):
    req = urllib.request.Request(base + path, method=method, headers=headers,
                                 data=json.dumps(payload).encode() if payload is not None else None)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            text = r.read().decode("utf-8-sig")
            return r.status, json.loads(text) if text.strip() else None
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")[:400]


status, res = call("POST", "authentication", body)
if status not in (200, 201):
    sys.exit(f"Registrierung abgelehnt: HTTP {status} {res}\n→ Wurde in der Wawi „Admin → App-Registrierung“ gestartet?")
reg_id = res["RegistrationRequestId"]
print(f"Anfrage gesendet (Status {res.get('Status')}). Jetzt in der Wawi bestätigen – ich warte bis zu 10 Minuten …")

deadline = time.time() + 600
while time.time() < deadline:
    time.sleep(5)
    status, info = call("GET", f"authentication/{reg_id}")
    if status == 200 and isinstance(info, dict) and (info.get("Token") or {}).get("ApiKey"):
        key = info["Token"]["ApiKey"]
        backup = SECRETS.with_name(f"secrets.json.bak-{datetime.datetime.now():%Y%m%d-%H%M%S}")
        shutil.copy2(SECRETS, backup)
        cfg["Parameters:jtl-api-token"] = key if key.startswith("Wawi ") else f"Wawi {key}"
        cfg["Parameters:jtl-app-id"] = APP_ID
        SECRETS.write_text(json.dumps(cfg, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Fertig. Schlüssel in den User-Secrets gespeichert (Länge {len(key)}), Sicherung: {backup.name}")
        print("Erteilte Scopes:", sorted(info.get("GrantedScopes") or []))
        sys.exit(0)
    if status in (402, 404, 410):
        sys.exit(f"Abbruch: HTTP {status} {info}")
    print(".", end="", flush=True)
sys.exit("\nZeitüberschreitung – in der Wawi nicht bestätigt? Skript neu starten.")
