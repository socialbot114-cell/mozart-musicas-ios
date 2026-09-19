#!/usr/bin/env python3
"""Coletor v2 — Internet Archive.

Reaproveita a curadoria (categoria -> compositor/obra) de coletar_musicas.py,
mas baixa do archive.org (Musopen, Great 78 Project, audio_music), que nao
aplica o bloqueio 429 do upload.wikimedia.org.

Fontes de dominio publico:
  - collection:musopen  -> gravacoes dedicadas ao dominio publico (Musopen)
  - collection:78rpm    -> Great 78 Project (gravacoes historicas)
  - licenseurl publicdomain / CC0

Uso:
  python3 coletar_archive.py --target 15
  python3 coletar_archive.py --only piano_dormir --target 15
  python3 coletar_archive.py --report
"""
import os
import re
import time
import json
import queue
import argparse
import threading
import subprocess
import unicodedata
from datetime import date
from urllib.parse import quote

import requests

from coletar_musicas import CATS, BASE

S = requests.Session()
S.headers.update({"User-Agent": "MusicasEstudarCollector/2.0 (educational; local user)"})
IA_SEARCH = "https://archive.org/advancedsearch.php"
IA_META = "https://archive.org/metadata/"
IA_DL = "https://archive.org/download/"

AUDIO_FORMATS = ["VBR MP3", "MP3", "128Kbps MP3", "64Kbps MP3", "256Kbps MP3",
                 "Ogg Vorbis", "FLAC", "WAVE"]
FORMAT_RANK = {f: i for i, f in enumerate(AUDIO_FORMATS)}
MIN_DUR = 60
MIN_BYTES = 150_000
MP3_BITRATE = "192k"

PD_LIC_HINTS = ["publicdomain", "public-domain", "cc0", "zero/1.0",
                "public_domain", "mark/1.0"]
PD_COLLECTIONS = {"musopen", "78rpm", "georgeblood", "audio_music",
                  "opensource_audio", "audio"}

_last = [0.0]
INTERVAL = 0.8


def ia_get(url, params=None, retries=5, timeout=60):
    for i in range(retries):
        w = INTERVAL - (time.time() - _last[0])
        if w > 0:
            time.sleep(w)
        try:
            r = S.get(url, params=params, timeout=timeout)
            _last[0] = time.time()
            if r.status_code == 429:
                time.sleep(10 * (i + 1))
                continue
            if r.status_code in (500, 502, 503):
                time.sleep(5 * (i + 1))
                continue
            r.raise_for_status()
            return r
        except Exception:
            if i == retries - 1:
                return None
            time.sleep(3 * (i + 1))
    return None


def strip(s):
    return "".join(c for c in unicodedata.normalize("NFD", str(s))
                   if unicodedata.category(c) != "Mn").lower()


def slugify(s):
    return re.sub(r"[^A-Za-z0-9]+", "_", strip(s)).strip("_")


def search_items(query, rows=20):
    q = f'({query}) AND mediatype:audio'
    r = ia_get(IA_SEARCH, {"q": q, "fl[]": ["identifier", "title", "collection",
                                            "licenseurl", "year", "creator"],
                           "rows": rows, "output": "json",
                           "sort[]": "downloads desc"})
    if not r:
        return []
    try:
        return r.json().get("response", {}).get("docs", [])
    except Exception:
        return []


def item_meta(identifier):
    r = ia_get(IA_META + quote(identifier))
    if not r:
        return {}
    try:
        return r.json()
    except Exception:
        return {}


def to_seconds(v):
    if v is None:
        return 0.0
    s = str(v).strip()
    try:
        return float(s)
    except ValueError:
        pass
    parts = s.split(":")
    try:
        if len(parts) == 2:
            return int(parts[0]) * 60 + float(parts[1])
        if len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
    except ValueError:
        return 0.0
    return 0.0


def item_audio_files(meta):
    out = []
    for f in meta.get("files", []):
        fmt = f.get("format", "")
        if fmt not in FORMAT_RANK:
            continue
        name = f.get("name", "")
        if not name:
            continue
        size = int(f.get("size", 0) or 0)
        if size and size < MIN_BYTES:
            continue
        dur = to_seconds(f.get("length"))
        out.append({"format": fmt, "name": name, "size": size,
                    "dur": dur, "rank": FORMAT_RANK[fmt]})
    out.sort(key=lambda x: (x["rank"], -x["size"]))
    return out


def item_is_pd(doc, meta):
    blob = strip(" ".join([
        str(doc.get("licenseurl") or ""),
        str(meta.get("metadata", {}).get("licenseurl") or ""),
        str(meta.get("metadata", {}).get("rights") or ""),
        str(doc.get("title") or ""),
    ]))
    if any(h in blob for h in PD_LIC_HINTS):
        return True, "licenca explicita"
    coll = doc.get("collection") or meta.get("metadata", {}).get("collection") or []
    if isinstance(coll, str):
        coll = [coll]
    coll = {strip(c) for c in coll}
    for pdc in PD_COLLECTIONS:
        if pdc in coll:
            return True, f"colecao {pdc}"
    return False, ""


def match_work(fname, obra, compositor):
    t = strip(fname)
    o = strip(obra)
    tokens = [w for w in re.split(r"[^a-z0-9]+", o) if len(w) >= 4]
    if not tokens:
        return True
    hits = sum(1 for w in tokens if w in t)
    return hits >= max(1, len(tokens) - 1)


def download(url, dest, retries=4):
    last = RuntimeError("falha no download")
    for i in range(retries):
        try:
            with S.get(url, timeout=300, stream=True) as r:
                if r.status_code == 429:
                    time.sleep(10 * (i + 1))
                    continue
                r.raise_for_status()
                with open(dest, "wb") as fh:
                    for chunk in r.iter_content(256 * 1024):
                        if chunk:
                            fh.write(chunk)
            if os.path.getsize(dest) < MIN_BYTES:
                raise RuntimeError("arquivo pequeno demais")
            return
        except Exception as e:
            last = e
            if os.path.exists(dest):
                os.remove(dest)
            time.sleep(5 * (i + 1))
    raise last


def convert(src, dst, title, artist, album):
    ext = os.path.splitext(src)[1].lower()
    base = ["ffmpeg", "-y", "-v", "error", "-i", src]
    if ext == ".mp3":
        codec = ["-c:a", "copy"]
    else:
        codec = ["-codec:a", "libmp3lame", "-b:a", MP3_BITRATE]
    cmd = base + codec + ["-metadata", f"title={title}",
                          "-metadata", f"artist={artist}",
                          "-metadata", f"album={album}", "-metadata",
                          f"comment=Fonte: Internet Archive (dominio publico)", dst]
    subprocess.run(cmd, check=True, timeout=300)
    pr = subprocess.run(["ffprobe", "-v", "error", "-show_entries",
                         "format=duration", "-of", "csv=p=0", dst],
                        capture_output=True, text=True, timeout=60)
    try:
        return float(pr.stdout.strip())
    except ValueError:
        return 0.0


def load_catalog():
    path = os.path.join(BASE, "CATALOGO.json")
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as f:
                d = json.load(f)
            d.setdefault("faixas", [])
            d.setdefault("faltas", [])
            return d
        except Exception:
            pass
    return {"faixas": [], "faltas": []}


_cat_lock = threading.Lock()


def save_catalog(cat):
    with _cat_lock:
        with open(os.path.join(BASE, "CATALOGO.json"), "w", encoding="utf-8") as f:
            json.dump(cat, f, ensure_ascii=False, indent=2)


def collect_one(cat, comp, morte, pais, query, obra, catalog):
    slug = slugify(f"{comp}_{obra}")
    outdir = os.path.join(BASE, cat)
    os.makedirs(outdir, exist_ok=True)
    dst = os.path.join(outdir, slug + ".mp3")
    if os.path.exists(dst) and os.path.getsize(dst) >= MIN_BYTES:
        return "existe"

    docs = search_items(f'{comp} {obra}') or search_items(query)
    for doc in docs[:12]:
        ident = doc.get("identifier")
        if not ident:
            continue
        meta = item_meta(ident)
        pd, why = item_is_pd(doc, meta)
        if not pd:
            continue
        files = item_audio_files(meta)
        if not files:
            continue
        for f in files:
            if f["dur"] and f["dur"] < MIN_DUR:
                continue
            if not match_work(f["name"], obra, comp):
                continue
            url = IA_DL + quote(ident) + "/" + quote(f["name"])
            tmp = os.path.join(outdir, "." + slug + os.path.splitext(f["name"])[1])
            try:
                download(url, tmp)
                dur = convert(tmp, dst, f"{comp} — {obra}", comp, cat)
                if dur < MIN_DUR:
                    raise RuntimeError(f"curta ({dur:.0f}s)")
                if os.path.exists(tmp):
                    os.remove(tmp)
            except Exception as e:
                if os.path.exists(dst):
                    os.remove(dst)
                continue
            with _cat_lock:
                catalog["faixas"].append({
                    "categoria": cat, "compositor": comp, "morte": morte, "pais": pais,
                    "obra": obra, "slug": slug, "arquivo": f"{cat}/{slug}.mp3",
                    "duracao_s": round(dur, 1), "duracao_min": round(dur / 60, 1),
                    "interprete": str(meta.get("metadata", {}).get("creator") or "desconhecido"),
                    "licenca": "Dominio publico",
                    "licenca_origem": why,
                    "fonte_arquivo": f"{ident}/{f['name']}",
                    "fonte_url": f"https://archive.org/details/{ident}",
                    "verificado_em": date.today().isoformat()})
            return f"[+] {slug}.mp3 {dur/60:.1f}min ({why})"
    with _cat_lock:
        catalog["faltas"].append({"categoria": cat, "compositor": comp, "obra": obra,
                                  "query": query, "motivo": "sem item PD com faixa valida",
                                  "verificado_em": date.today().isoformat()})
    return f"-- FALTA: {comp} — {obra}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=int, default=15)
    ap.add_argument("--only", default=None)
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()

    os.makedirs(BASE, exist_ok=True)
    catalog = load_catalog()

    if args.report:
        print(f"Faltas: {len(catalog['faltas'])}")
        for f in catalog["faltas"]:
            print(f"  [{f['categoria']}] {f['compositor']} — {f['obra']}: {f['motivo']}")
        return

    cats = [args.only] if args.only else list(CATS)
    for cat in cats:
        items = CATS[cat][:args.target]
        print(f"\n=== {cat} ({len(items)} obras) ===", flush=True)
        jobs = queue.Queue()
        for it in items:
            jobs.put(it)
        results = []

        def worker():
            while True:
                try:
                    it = jobs.get_nowait()
                except queue.Empty:
                    return
                comp, morte, pais, query, obra = it
                try:
                    msg = collect_one(cat, comp, morte, pais, query, obra, catalog)
                except Exception as e:
                    msg = f"-- ERRO: {comp} — {obra} ({str(e)[:80]})"
                results.append(msg)
                print("  " + msg, flush=True)
                save_catalog(catalog)
                jobs.task_done()

        threads = [threading.Thread(target=worker) for _ in range(max(1, args.workers))]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        save_catalog(catalog)

    print("\n=== RESUMO ===")
    for cat in cats:
        n = sum(1 for t in catalog["faixas"] if t["categoria"] == cat)
        print(f"  {cat}: {n} faixas")


if __name__ == "__main__":
    main()
