#!/usr/bin/env python3
"""
Ratgeber- und Infoseiten sowie die FAQ aus dem Strapi des Stripe-Shops als ENTWÜRFE in den .NET-Shop übernehmen (Bericht 26, 19.11.2026).
Nur lesend aus Strapi (Tunnel zu node1, Port 18443). Im Shop: Seiten anlegen bzw. eigene frühere Übernahmen aktualisieren, nie veröffentlichen.
Seiten, die es mit derselben Adresse schon gibt und die NICHT aus dieser Übernahme stammen (z. B. JTL-Import, vom Team angelegt), bleiben unberührt;
die Strapi-Fassung kommt dann als Vergleichsentwurf unter /{slug}-strapi („[Strapi] …“) daneben – das Team wählt je Thema eine Fassung.

Strapi → .NET-Bausteine:
  shared.text-section        → Text (HTML; Überschriften als Baustein „Überschrift“, Bilder im Text als Baustein „Bild“)
  shared.image-text-section  → Spalten [Bild | Überschrift + Text + Knopf] (Seite links/rechts wie in Strapi)
  FAQ (Sammlung)             → Seite „faq“ mit Akkordeon (je Frage ein Abschnitt)
Bilder werden aus Strapi geladen und in die Medienbibliothek hochgeladen (gleicher Dateiname → wiederverwendet).
Adresse (Slug) = Strapi-Name wie im Stripe-Shop (/{slug}) → die Adressen vom 15.06.–14.10. bleiben gültig.

Aufruf (Tunnel muss stehen):
    SHOP_KEY=… SHOP_API=https://localhost:<port>/api/v1 python3 strapi_inhalte.py            # Probelauf: zeigt, was passieren würde
    SHOP_KEY=… SHOP_API=… python3 strapi_inhalte.py --apply                                  # Entwürfe anlegen/aktualisieren
"""
import html, json, os, ssl, sys, urllib.error, urllib.parse, urllib.request, uuid

APPLY = "--apply" in sys.argv
KEY = os.environ["SHOP_KEY"]
API = os.environ.get("SHOP_API", "https://localhost:7074/api/v1").rstrip("/")
STRAPI_HOST = "cms.sicherheit.meesenburg.com"
STRAPI = "https://127.0.0.1:18443"
ACTOR = "Übernahme Strapi (Stripe-Shop)"
ctx = ssl._create_unverified_context()

# Rechtstexte sind schon übernommen (rechtstexte_strapi.py); Kontakt hat ein eigenes Formular; Startseite/Global/Einstellungen haben Sonderbausteine
SKIP = {"agb", "datenschutz", "impressum", "widerrufsrecht", "zahlung-und-versand", "batteriegesetzhinweis", "kontakt", "home", "global",
        "settings", "payment-method", "configurator-contextual-help", "trusted-shops-siegel", "news-article", "news-category", "faq", "glossar"}
PAGES = ["assa-abloy-keso-vds-zertifizierter-partner", "der-erste-eigene-schluessel-dormakaba-gemini-plus-quattro-plus-expert-plus-expert-cross-penta",
         "ersatzsicherungskarte-verlustmeldung-kaba-keso", "gebrauchsanleitung-fuer-schliesszylinder", "hier-finden-sie-uns",
         "mehrfachverriegelung-messen-hauptschloss-erneuern-anleitung-video", "neue-farbkappen-fuer-keso-schliesssyteme",
         "ruecksendungen-reklamationen-neue-adresse", "schliessanlagen-information", "schliessanlagen-konfigurator-anleitung",
         "schliessplan-erstellen-vorlage-keso-dormakaba-gege-abus-bks", "schliesszylinder-kuerzen-verlaengern", "schliesszylinder-richtig-messen",
         "systembeschreibung-keso-4000s", "systembeschreibung-keso-6000-fp2", "systembeschreibung-keso-8000-omega", "tuer-din-richtung",
         "tuer-schloss-messen", "upload-formular", "verpackungverordnung", "video-produkt-information",
         "zugriffssteuerung-programmieren-dormakaba-tuerkomponente-evolo", "zutrittsteuerung-per-dormakaba-exivo", "wir-ueber-uns"]


# ---------- Strapi (nur lesen) ----------
def strapi_get(path):
    req = urllib.request.Request(STRAPI + path, headers={"Host": STRAPI_HOST})
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=60) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        if e.code == 404: return None
        raise


def strapi_file(url):
    """Pfad (/uploads/…) oder absolute Adresse; Adressen des eigenen CMS laufen über den Tunnel"""
    if url.startswith("http"):
        u = urllib.parse.urlparse(url)
        if u.hostname == STRAPI_HOST: url = u.path + (f"?{u.query}" if u.query else "")
        else:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=60) as r:
                return r.read(), r.headers.get_content_type()
    req = urllib.request.Request(STRAPI + url, headers={"Host": STRAPI_HOST})
    with urllib.request.urlopen(req, context=ctx, timeout=60) as r:
        return r.read(), r.headers.get_content_type()


# ---------- Shop-API ----------
def shop(method, path, body=None, raw=None, content_type="application/json"):
    data = raw if raw is not None else (None if body is None else json.dumps(body).encode())
    req = urllib.request.Request(API + path, method=method, data=data,
                                 headers={"X-Internal-Key": KEY, "X-Staff-Actor": urllib.parse.quote(ACTOR), "Content-Type": content_type})
    with urllib.request.urlopen(req, context=ctx, timeout=120) as r:
        return json.loads(r.read() or b"null")


def upload(name, content, ctype):
    boundary = uuid.uuid4().hex
    body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{name}\"\r\nContent-Type: {ctype}\r\n\r\n").encode() \
           + content + f"\r\n--{boundary}--\r\n".encode()
    return shop("POST", "/admin/media", raw=body, content_type=f"multipart/form-data; boundary={boundary}")


MEDIA = {}          # Dateiname → /medien/{id}
UPLOADS = []


def image_src(img):
    """Strapi-Bild → /medien/{id} (einmal hochladen, gleicher Dateiname wird wiederverwendet)"""
    if not img or not img.get("url"): return None
    name = "strapi_" + urllib.parse.urlparse(img["url"]).path.rsplit("/", 1)[-1]
    if name not in MEDIA:
        if not APPLY:
            MEDIA[name] = f"/medien/<neu:{name}>"; UPLOADS.append(name)
        else:
            content, ctype = strapi_file(img["url"])
            MEDIA[name] = f"/medien/{upload(name, content, ctype)['id']}"; UPLOADS.append(name)
    return MEDIA[name]


# ---------- Rich-Text (Strapi „blocks“) → Bausteine ----------
def inline(nodes):
    out = []
    for n in nodes:
        if n.get("type") == "link":
            out.append(f'<a href="{html.escape(n.get("url", ""), quote=True)}">{inline(n.get("children", []))}</a>'); continue
        t = html.escape(n.get("text", "")).replace("\n", "<br>")
        if not t: continue
        if n.get("bold"): t = f"<strong>{t}</strong>"
        if n.get("italic"): t = f"<em>{t}</em>"
        if n.get("underline"): t = f"<u>{t}</u>"
        if n.get("code"): t = f"<code>{t}</code>"
        out.append(t)
    return "".join(out)


def plain(nodes):
    return "".join(n.get("text", "") if n.get("type") != "link" else plain(n.get("children", [])) for n in nodes).strip()


def rich_blocks(nodes, unknown):
    """Liste von .NET-Bausteinen; aufeinanderfolgender Text wird zu EINEM Text-Baustein zusammengefasst"""
    blocks, buf = [], []

    def flush():
        if buf: blocks.append({"id": uuid.uuid4().hex[:12], "type": "text", "props": {"html": "\n".join(buf)}}); buf.clear()

    for b in nodes or []:
        t, kids = b.get("type"), b.get("children", [])
        if t == "heading":
            flush()
            blocks.append({"id": uuid.uuid4().hex[:12], "type": "heading", "props": {"text": plain(kids)[:200], "level": "3" if b.get("level", 2) >= 3 else "2"}})
        elif t == "paragraph":
            h = inline(kids)
            if h: buf.append(f"<p>{h}</p>")
        elif t == "list":
            tag = "ol" if b.get("format") == "ordered" else "ul"
            buf.append(f"<{tag}>" + "".join(f"<li>{inline(i.get('children', []))}</li>" for i in kids) + f"</{tag}>")
        elif t == "quote":
            buf.append(f"<blockquote>{inline(kids)}</blockquote>")
        elif t == "code":
            buf.append(f"<pre>{html.escape(plain(kids))}</pre>")
        elif t == "image":
            flush()
            img = b.get("image") or {}
            blocks.append({"id": uuid.uuid4().hex[:12], "type": "image", "props": {"src": image_src(img), "alt": (img.get("alternativeText") or "")[:200]}})
        else:
            unknown.add(t)
    flush()
    return blocks


def convert(data, unknown):
    out = []
    for s in data.get("blocks") or []:
        comp = s.get("__component")
        if comp == "shared.text-section":
            out += rich_blocks(s.get("description"), unknown)
        elif comp == "shared.image-text-section":
            text_col = []
            if s.get("title"): text_col.append({"id": uuid.uuid4().hex[:12], "type": "heading", "props": {"text": s["title"].strip().rstrip(":").strip()[:200], "level": "3"}})
            text_col += [b for b in rich_blocks(s.get("description"), unknown) if b["type"] in ("text", "heading", "image")]
            btn = s.get("button")
            for bt in (btn if isinstance(btn, list) else [btn] if btn else []):
                if bt and (bt.get("url") or bt.get("href")):
                    text_col.append({"id": uuid.uuid4().hex[:12], "type": "button",
                                     "props": {"label": (bt.get("text") or bt.get("label") or "Mehr")[:80], "href": bt.get("url") or bt.get("href"), "style": "primary"}})
            img = s.get("image")
            img_col = [{"id": uuid.uuid4().hex[:12], "type": "image", "props": {"src": image_src(img), "alt": ((img or {}).get("alternativeText") or s.get("title") or "")[:200]}}] if img else []
            cols = [img_col, text_col] if s.get("alignment", "left") == "left" else [text_col, img_col]
            if not img_col: out += text_col; continue
            out.append({"id": uuid.uuid4().hex[:12], "type": "columns", "props": {}, "columns": [{"blocks": c} for c in cols]})
        else:
            unknown.add(comp)
    return out


def save(slug, title, blocks, existing, report):
    draft = {"title": title, "placement": "Page", "slug": slug, "targetId": None, "position": "Top", "metaTitle": title, "metaDescription": None,
             "publishFromUtc": None, "publishUntilUtc": None, "blocks": blocks}
    page = existing.get(slug)
    if page and page.get("updatedBy") != ACTOR:
        # Seite gibt es schon (JTL-Import, vom Team) → nicht überschreiben, Strapi-Fassung als Vergleichsentwurf daneben (unveröffentlicht)
        if slug.endswith("-strapi"):
            report.append(f"ÜBERSPRUNGEN  /{slug}: gibt es schon und stammt nicht aus dieser Übernahme"); return
        report.append(f"VORHANDEN    /{slug}: {page.get('source')} bleibt unverändert →")
        return save(slug + "-strapi", "[Strapi] " + title, blocks, existing, report)
    action = "aktualisiert" if page else "angelegt"
    if APPLY:
        if page: shop("PUT", f"/admin/content/{page['id']}", draft)
        else: shop("POST", "/admin/content", draft)
    report.append(f"{'ENTWURF ' + action if APPLY else 'Probelauf: würde ' + action}  /{slug}  „{title}“, {count(blocks)} Bausteine")


def count(blocks):
    return sum(1 + sum(count(c["blocks"]) for c in b.get("columns") or []) for b in blocks)


if __name__ == "__main__":
    existing = {p["slug"]: p for p in shop("GET", "/admin/content") if p.get("placement") == "Page" and p.get("slug")}
    # Schon hochgeladene Bilder wiederverwenden (zweiter Lauf erzeugt keine Dubletten)
    MEDIA.update({m["fileName"]: f"/medien/{m['id']}" for m in shop("GET", "/admin/media") if m.get("fileName", "").startswith("strapi_")})
    report, unknown = [], set()
    for slug in PAGES:
        d = strapi_get(f"/api/{slug}?populate[blocks][populate]=*")
        if not d or not d.get("data"):
            report.append(f"LEER         /{slug}: in Strapi ohne Inhalt – übersprungen"); continue
        data = d["data"]
        blocks = convert(data, unknown)
        # Erste Überschrift = Seitentitel (zeigt der Shop als H1) → nicht doppelt, sonst zwei gleiche Überschriften (SEO: genau eine H1)
        title = (data.get("title") or slug).strip()
        if blocks and blocks[0]["type"] == "heading" and blocks[0]["props"]["text"].strip().lower() == title.lower(): blocks = blocks[1:]
        if not blocks:
            report.append(f"LEER         /{slug}: keine übernehmbaren Bausteine"); continue
        save(slug, (data.get("title") or slug).strip(), blocks, existing, report)

    # FAQ: eine Seite, je Frage ein Akkordeon-Abschnitt (wie im Stripe-Shop unter /faq)
    faqs = (strapi_get("/api/faqs?pagination[pageSize]=100&sort=id") or {}).get("data") or []
    if faqs:
        titles = [f["title"].strip()[:200] for f in faqs]
        columns = [{"blocks": rich_blocks(f.get("content"), unknown)} for f in faqs]
        acc = {"id": uuid.uuid4().hex[:12], "type": "accordion", "props": {"titles": "\n".join(titles)}, "columns": columns}
        save("faq", "Häufige Fragen", [acc], existing, report)

    print("\n".join(report))
    print(f"\nBilder {'hochgeladen' if APPLY else 'zum Hochladen'}: {len(UPLOADS)}")
    if unknown: print("Nicht übernommene Strapi-Bausteine/Typen:", ", ".join(sorted(str(u) for u in unknown)))
    if not APPLY: print("\nProbelauf – nichts geschrieben. Mit --apply als Entwürfe anlegen.")
