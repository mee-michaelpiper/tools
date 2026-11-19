#!/usr/bin/env python3
"""
Liste „Problemverfolgung“ im Teams-Kanal (eCommers SiSe → Shopentwicklung) für den Feedback-Knopf des Shops einrichten bzw. prüfen.
Zugang: App „SiSe-Shop (Test)“ mit Sites.Selected (write nur auf der Kanal-Website), Geheimnis aus dem Key Vault.

    SECRET=$(az keyvault secret show --vault-name kv-meesenburg-prod --name SiseShop-Feedback-Graph-Secret --query value -o tsv) \\
        python3 feedback_liste.py spalten        # zeigt die Spalten
    ... python3 feedback_liste.py anlegen        # legt fehlende Spalten an (Art, Seite, GemeldetVon, Nummer, Screenshot, GitHubIssue)

Angelegt am 19.11.2026. Gibt nie das Geheimnis oder Tokens aus.
"""
import json, os, sys, urllib.error, urllib.parse, urllib.request

TENANT = "a7473855-450e-4993-befa-62446ec6444b"
CLIENT = "5778bd95-d2c5-4126-a1f8-b018a799b84f"
SITE = os.environ.get("SITE", "meesenburggroup.sharepoint.com,db2b789b-73ea-42db-b6d1-218d01b9241f,c85b925a-d554-40f4-be54-e412f3826a16")
LIST = os.environ.get("LIST", "Problemverfolgung")

COLUMNS = [
    {"name": "Art", "displayName": "Art", "choice": {"choices": ["Fehler", "Wunsch", "Frage"], "displayAs": "dropDownMenu"}},
    {"name": "Seite", "displayName": "Seite", "hyperlinkOrPicture": {"isPicture": False}},
    {"name": "GemeldetVon", "displayName": "Gemeldet von", "text": {}},
    {"name": "Nummer", "displayName": "Nummer", "text": {}, "indexed": True},
    {"name": "Screenshot", "displayName": "Screenshot", "hyperlinkOrPicture": {"isPicture": False}},
    {"name": "GitHubIssue", "displayName": "GitHub-Issue", "hyperlinkOrPicture": {"isPicture": False}},
]


def token():
    data = urllib.parse.urlencode({"client_id": CLIENT, "client_secret": os.environ["SECRET"],
                                   "scope": "https://graph.microsoft.com/.default", "grant_type": "client_credentials"}).encode()
    return json.load(urllib.request.urlopen(f"https://login.microsoftonline.com/{TENANT}/oauth2/v2.0/token", data))["access_token"]


TOKEN = token()


def call(method, path, body=None):
    req = urllib.request.Request("https://graph.microsoft.com/v1.0/" + path, method=method,
                                 data=None if body is None else json.dumps(body).encode(),
                                 headers={"Authorization": "Bearer " + TOKEN, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]


def columns():
    status, l = call("GET", f"sites/{SITE}/lists/{LIST}?$expand=columns")
    if status != 200: sys.exit(f"Liste nicht lesbar: {status} {l}")
    return l["id"], {c["name"]: c for c in l["columns"]}


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "spalten"
    list_id, existing = columns()
    if cmd == "anlegen":
        for col in COLUMNS:
            if col["name"] in existing: print("vorhanden:", col["displayName"]); continue
            status, res = call("POST", f"sites/{SITE}/lists/{list_id}/columns", col)
            print("angelegt:" if status == 201 else f"FEHLER {status}:", col["displayName"], "" if status == 201 else res)
        list_id, existing = columns()
    print("Liste", LIST, list_id)
    for c in existing.values():
        if c.get("hidden") or c.get("readOnly"): continue
        kind = [k for k in ("choice", "text", "personOrGroup", "hyperlinkOrPicture", "dateTime", "boolean", "number", "lookup") if k in c]
        print(" -", c["name"], "|", c["displayName"], "|", kind)
