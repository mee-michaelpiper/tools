#!/usr/bin/env python3
"""
Prüft, was ein Crawler OHNE JavaScript vom Shop sieht (Prüfliste „Serverseitige HTML-Auslieferung“, C. Feller, 17.11.2026).
Ruft jede Adresse mit dem User-Agent des GPTBot ab und meldet je Seite: Status, Antwortzeit, Title, Description, Canonical,
Robots (Meta + Header), lang/charset/viewport, Open Graph, H1/H2/H3, Breadcrumb, JSON-LD-Typen, Bilder ohne alt/src,
Pseudo-Links (#, javascript:) und data-src. Optional: Stichprobe der Sitemap (Status 200, Canonical auf sich selbst, kein noindex).

Nur lesend, nur Standardbibliothek.
Aufruf:  python3 seo_html_check.py https://shop/ https://shop/kategorie …
         python3 seo_html_check.py --sitemap https://shop/sitemap.xml --sample 200
"""
import argparse, json, random, re, sys, time, urllib.error, urllib.request
from html.parser import HTMLParser

UA = "Mozilla/5.0 (compatible; GPTBot/1.1; +https://openai.com/gptbot)"


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k): return None


def fetch(url, follow=False):
    opener = urllib.request.build_opener() if follow else urllib.request.build_opener(NoRedirect)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    t = time.perf_counter()
    try:
        r = opener.open(req, timeout=30)
        body = r.read().decode("utf-8", "replace"); status = r.status; headers = r.headers
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace"); status = e.code; headers = e.headers
    return status, headers, body, time.perf_counter() - t


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.lang = self.charset = self.viewport = self.title = self.description = None
        self.canonicals, self.robots, self.og, self.h, self.ldjson = [], [], {}, [], []
        self.img_no_alt = self.img_no_src = self.data_src_only = self.img_lazy = self.imgs = 0
        self.pseudo_links = self.links = 0
        self.breadcrumb_links = 0
        self._in = None; self._buf = ""; self._bc_depth = 0; self._depth = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs); self._depth += 1
        if tag == "html": self.lang = a.get("lang")
        elif tag == "meta":
            if "charset" in a: self.charset = a["charset"]
            n = (a.get("name") or "").lower(); p = (a.get("property") or "").lower()
            if n == "viewport": self.viewport = a.get("content")
            if n == "description": self.description = a.get("content")
            if n == "robots": self.robots.append(a.get("content"))
            if p.startswith("og:"): self.og[p] = a.get("content")
        elif tag == "link" and (a.get("rel") or "").lower() == "canonical": self.canonicals.append(a.get("href"))
        elif tag in ("title", "h1", "h2", "h3") or (tag == "script" and a.get("type") == "application/ld+json"):
            self._in = "ld" if tag == "script" else tag; self._buf = ""
        elif tag == "img":
            self.imgs += 1
            if not a.get("src"): self.img_no_src += 1
            if a.get("data-src") and not a.get("src"): self.data_src_only += 1
            if a.get("alt") is None: self.img_no_alt += 1
            if a.get("loading") == "lazy": self.img_lazy += 1
        elif tag == "a":
            href = a.get("href")
            if href is None or href.strip() in ("#", "") or href.strip().lower().startswith("javascript:"): self.pseudo_links += 1
            else: self.links += 1
            if self._bc_depth: self.breadcrumb_links += 1
        if tag in ("nav", "ol", "ul", "div") and ("breadcrumb" in (a.get("class") or "").lower() or "breadcrumb" in (a.get("aria-label") or "").lower()):
            self._bc_depth = self._bc_depth or self._depth

    def handle_endtag(self, tag):
        if self._bc_depth and self._depth <= self._bc_depth: self._bc_depth = 0
        self._depth -= 1
        if self._in and (tag == self._in or (self._in == "ld" and tag == "script")):
            text = re.sub(r"\s+", " ", self._buf).strip()
            if self._in == "title": self.title = text
            elif self._in == "ld": self.ldjson.append(text)
            else: self.h.append((self._in, text))
            self._in = None

    def handle_data(self, data):
        if self._in: self._buf += data


def ld_types(blocks):
    types = []
    for b in blocks:
        try: d = json.loads(b)
        except json.JSONDecodeError: types.append("UNGÜLTIG"); continue
        for item in (d if isinstance(d, list) else d.get("@graph", [d])):
            types.append(item.get("@type", "?") if isinstance(item, dict) else "?")
    return types


def check(url):
    status, headers, body, secs = fetch(url)
    print(f"\n=== {url}\n  Status {status}  ({secs*1000:.0f} ms)  X-Robots-Tag: {headers.get('X-Robots-Tag')}  Location: {headers.get('Location')}")
    if status >= 300: print(f"  Retry-After: {headers.get('Retry-After')}") if status == 503 else None; return
    p = Page(); p.feed(body)
    h1 = [t for k, t in p.h if k == "h1"]
    print(f"  lang={p.lang} charset={p.charset} viewport={'ja' if p.viewport else 'NEIN'}")
    print(f"  title: {p.title}")
    print(f"  description: {(p.description or 'FEHLT')[:110]}")
    print(f"  canonical ({len(p.canonicals)}x): {p.canonicals}")
    print(f"  robots: {p.robots or '(kein Meta = index)'}")
    print(f"  og: {sorted(p.og)}")
    print(f"  H1 ({len(h1)}x): {h1}  H2: {sum(1 for k,_ in p.h if k=='h2')}  H3: {sum(1 for k,_ in p.h if k=='h3')}")
    print(f"  Reihenfolge: {' '.join(k for k,_ in p.h)[:120]}")
    print(f"  Breadcrumb-Links: {p.breadcrumb_links}  Links: {p.links}  Pseudo-Links: {p.pseudo_links}")
    print(f"  Bilder: {p.imgs}  ohne alt: {p.img_no_alt}  ohne src: {p.img_no_src}  nur data-src: {p.data_src_only}  lazy: {p.img_lazy}")
    print(f"  JSON-LD: {ld_types(p.ldjson)}")
    text = re.sub(r"<[^>]+>", " ", re.sub(r"<script.*?</script>|<style.*?</style>", " ", body, flags=re.S))
    print(f"  Textlänge ohne JS: {len(re.sub(r'\s+', ' ', text))} Zeichen")


def sitemap(url, sample):
    _, _, body, _ = fetch(url, follow=True)
    locs = re.findall(r"<loc>([^<]+)</loc>", body)
    picked = random.sample(locs, min(sample, len(locs)))
    bad = []
    for u in picked:
        status, headers, page, _ = fetch(u)
        p = Page(); p.feed(page) if status == 200 else None
        problems = []
        if status != 200: problems.append(f"Status {status}")
        elif p.canonicals != [u]: problems.append(f"Canonical {p.canonicals}")
        if any("noindex" in (r or "") for r in p.robots) or "noindex" in (headers.get("X-Robots-Tag") or ""): problems.append("noindex")
        if problems: bad.append((u, problems))
    print(f"\nSitemap: {len(locs)} URLs, Stichprobe {len(picked)}, fehlerhaft {len(bad)} ({100*len(bad)/max(1,len(picked)):.1f} %)")
    for u, pr in bad[:30]: print(f"  {u}: {', '.join(pr)}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("urls", nargs="*"); ap.add_argument("--sitemap"); ap.add_argument("--sample", type=int, default=200)
    a = ap.parse_args()
    for u in a.urls: check(u)
    if a.sitemap: sitemap(a.sitemap, a.sample)
