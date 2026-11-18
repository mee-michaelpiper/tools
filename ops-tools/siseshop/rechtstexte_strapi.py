"""Rechtstexte (AGB, Datenschutz, Impressum, Widerrufsrecht, Zahlung und Versand, Batteriegesetz) aus dem Strapi des Stripe-Shops
in die gleichnamigen Seiten des .NET-Shops übernehmen (nur lesend aus Strapi; Wortlaut unverändert, nur Markup).

Strapi liefert Rich-Text-Blöcke (paragraph, heading, list, link, fett/kursiv). Daraus wird HTML; ganz fette kurze Absätze werden
Zwischenüberschriften („I. …“ → h2, sonst h3). Die Seite bekommt einen Entwurf und wird veröffentlicht – die alte Fassung bleibt als Version.

Aufruf (Tunnel zu node1 muss stehen, Port 18443):
    SHOP_KEY=… python3 tools/rechtstexte_strapi.py            # holt die Texte aus Strapi
    SHOP_KEY=… STRAPI_DIR=ordner python3 tools/rechtstexte_strapi.py   # nimmt gespeicherte <slug>.json
"""
import html, json, os, re, ssl, sys, urllib.parse, urllib.request

KEY = os.environ["SHOP_KEY"]
BASE = os.environ.get("SHOP_API", "https://localhost:7074/api/v1/admin/content")
STRAPI = os.environ.get("STRAPI_URL", "https://cms.sicherheit.meesenburg.com:18443/api")
STRAPI_DIR = os.environ.get("STRAPI_DIR")
ACTOR = urllib.parse.quote("Übernahme Rechtstexte aus Strapi")
SLUGS = ["agb", "datenschutz", "impressum", "widerrufsrecht", "zahlung-und-versand", "batteriegesetzhinweis"]
ctx = ssl._create_unverified_context()


def call(method, path, body=None):
    req = urllib.request.Request(BASE + path, method=method, data=None if body is None else json.dumps(body).encode(),
                                 headers={"X-Internal-Key": KEY, "X-Staff-Actor": ACTOR, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, context=ctx, timeout=60) as r:
        return json.loads(r.read() or b"null")


def strapi(slug):
    if STRAPI_DIR:
        return json.load(open(os.path.join(STRAPI_DIR, slug + ".json"), encoding="utf-8"))["data"]
    url = f"{STRAPI}/{slug}?populate=*&locale=de"
    host = urllib.parse.urlparse(url).hostname
    # Tunnel: Name des CMS für TLS/Traefik, Verbindung auf localhost
    req = urllib.request.Request(url.replace(host, "127.0.0.1"), headers={"Host": host})
    with urllib.request.urlopen(req, context=ctx, timeout=60) as r:
        return json.loads(r.read())["data"]


def inline(nodes):
    out = []
    for n in nodes:
        if n.get("type") == "link":
            out.append(f'<a href="{html.escape(n.get("url", ""), quote=True)}">{inline(n.get("children", []))}</a>')
            continue
        t = html.escape(n.get("text", "")).replace("\n", "<br>")
        if not t:
            continue
        if n.get("bold"): t = f"<strong>{t}</strong>"
        if n.get("italic"): t = f"<em>{t}</em>"
        if n.get("underline"): t = f"<u>{t}</u>"
        out.append(t)
    return "".join(out)


def plain(nodes):
    return "".join(n.get("text", "") if n.get("type") != "link" else plain(n.get("children", [])) for n in nodes).strip()


def all_bold(nodes):
    texts = [n for n in nodes if n.get("type") == "text" and n.get("text", "").strip()]
    return bool(texts) and all(n.get("bold") for n in texts)


HEADING_ROMAN = re.compile(r"^[IVX]+\.\s+\S")
HEADING_SECTION = re.compile(r"^§\s*\d+[a-z]?\s+\S")
HEADING_NUMBERED = re.compile(r"^\d{1,2}(\.\d{1,2})*\.?\s+[A-ZÄÖÜ]")
PARAGRAPH_START = re.compile(r"^(\(\d+\)|\d+(\.\d+)+\.?\s|[-–•]\s)")
SENTENCE_END = re.compile(r"[.:;!?]$")
WRAPPED = 60  # Zeilen ab dieser Länge ohne Satzende gelten als umbrochen (wie LegalTextFormat im Shop)


def heading_level(text, bold):
    if len(text) > 120 or SENTENCE_END.search(text):
        return 0
    if HEADING_ROMAN.match(text): return 2
    if HEADING_SECTION.match(text) or bold or (HEADING_NUMBERED.match(text) and len(text) <= 60): return 3
    return 0


def to_html(data):
    """Strapi-Blöcke → HTML. Absätze sind oft einzelne, mitten im Satz umbrochene Zeilen: diese werden wieder zusammengefügt,
    Überschriften erkannt (wie LegalTextFormat für die JTL-Texte). Wortlaut bleibt gleich."""
    parts, para, prev = [], [], None

    def flush():
        if para: parts.append("<p>" + "".join(para) + "</p>")
        para.clear()

    for section in data.get("blocks") or []:
        for b in section.get("description") or []:
            t, kids = b.get("type"), b.get("children", [])
            if t == "heading":
                if b.get("level") == 1: continue  # Seitentitel zeigt der Shop selbst
                flush(); prev = None
                level = min(max(int(b.get("level", 2)), 2), 4)
                parts.append(f"<h{level}>{html.escape(plain(kids))}</h{level}>"); continue
            if t in ("list", "quote"):
                flush(); prev = None
                if t == "list":
                    tag = "ol" if b.get("format") == "ordered" else "ul"
                    parts.append(f"<{tag}>" + "".join(f"<li>{inline(i.get('children', []))}</li>" for i in kids) + f"</{tag}>")
                else:
                    parts.append(f"<blockquote>{inline(kids)}</blockquote>")
                continue
            text = plain(kids)
            if not text:  # Leerzeile = Absatzende
                flush(); prev = None; continue
            level = heading_level(text, all_bold(kids))
            if level:
                flush(); prev = None
                parts.append(f"<h{level}>{html.escape(text)}</h{level}>"); continue
            h = inline(kids)
            if PARAGRAPH_START.match(text): flush()
            elif para and prev is not None and len(prev) >= WRAPPED and not SENTENCE_END.search(prev):
                para[-1] += " " + h; prev = text; continue
            elif para: para[-1] += "<br>"
            para.append(h); prev = text
    flush()
    return "\n".join(parts)


pages = {p["slug"]: p for p in call("GET", "") if p.get("placement") == "Page" and p.get("slug")}
for slug in SLUGS:
    data = strapi(slug)
    body = to_html(data)
    page = pages.get(slug)
    if page is None:
        print(f"{slug}: Seite fehlt im .NET-Shop – übersprungen"); continue
    detail = call("GET", f"/{page['id']}")
    draft = detail["draft"]
    draft["blocks"] = [{"id": "rechtstext", "type": "text", "props": {"html": body}}]
    draft["title"] = data.get("title") or draft["title"]
    call("PUT", f"/{page['id']}", draft)
    call("POST", f"/{page['id']}/publish")
    print(f"{slug}: übernommen (Strapi-Stand {data.get('updatedAt', '?')[:10]}, {len(body)} Zeichen HTML)")
