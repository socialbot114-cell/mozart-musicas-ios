#!/usr/bin/env python3
"""Coleta musicas em dominio publico/CC0 para o app Musicas para Estudar.

Pipeline por faixa:
  1. Busca no Wikimedia Commons (filetype:audio) por "Compositor Obra".
  2. Filtra: duracao >= MIN_DUR, licenca PD/CC0, extensao de audio.
  3. Baixa original, converte p/ MP3 192k com tags ID3 (ffmpeg).
  4. Salva em musicas/<categoria>/ + registra em CATALOGO.json.

Uso:
  python3 coletar_musicas.py --target 15            # todas as categorias
  python3 coletar_musicas.py --only barroco --target 15
  python3 coletar_musicas.py --report               # so mostra faltas
"""
import os
import re
import sys
import time
import json
import argparse
import subprocess
import unicodedata
from datetime import date

import requests

BASE = os.environ.get(
    "MUSICAS_OUTPUT_DIR",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "musicas"),
)
UA = "MusicasEstudarCollector/1.0 (educational; local user) python-requests"
API = "https://commons.wikimedia.org/w/api.php"
S = requests.Session()
S.headers.update({"User-Agent": UA})

MIN_DUR = 60          # segundos
MIN_BYTES = 200_000   # ignora midis/previews minusculos
TARGET_BITRATE = "192k"

PD_LICENSES = {
    "public domain", "cc0", "cc-0",
    "pd-old", "pd-us", "pd-us-expired", "pd-art",
    "pd-score", "pd-sheet-music", "pd-music",
    "cc-pd-mark", "copyrighted free use",
}

AUDIO_EXT = (".ogg", ".oga", ".opus", ".flac", ".wav", ".mp3", ".webm")

SKIP_WORDS = ["midi", ".mid", "30secondes", "30 secondes", "sample",
              "preview", "excerpt", "trailer", "talk", "speech",
              "pronunciation", "pronuncia"]

# (compositor, morte, pais, obra de busca, titulo exibicao)
BARROCO = [
    ("J. S. Bach", 1750, "Alemanha", "Bach Goldberg Variations", "Goldberg Variations"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Well-Tempered Clavier prelude", "Prelúdio do Cravo Bem Temperado"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Cello Suite", "Suíte para Violoncelo"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Air on G string", "Ária na corda Sol"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Brandenburg Concerto", "Concerto de Brandemburgo"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Partita violin", "Partita para Violino"),
    ("J. S. Bach", 1750, "Alemanha", "Bach French Suite", "Suíte Francesa"),
    ("J. S. Bach", 1750, "Alemanha", "Bach English Suite", "Suíte Inglesa"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Invention piano", "Invenção a duas vozes"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Toccata organ", "Tocata para Órgão"),
    ("Antonio Vivaldi", 1741, "Itália", "Vivaldi Four Seasons Spring", "As Quatro Estações: Primavera"),
    ("Antonio Vivaldi", 1741, "Itália", "Vivaldi Four Seasons Summer", "As Quatro Estações: Verão"),
    ("Antonio Vivaldi", 1741, "Itália", "Vivaldi Four Seasons Autumn", "As Quatro Estações: Outono"),
    ("Antonio Vivaldi", 1741, "Itália", "Vivaldi Four Seasons Winter", "As Quatro Estações: Inverno"),
    ("Antonio Vivaldi", 1741, "Itália", "Vivaldi Gloria", "Gloria"),
    ("George F. Handel", 1759, "Alemanha/Inglaterra", "Handel Water Music", "Water Music"),
    ("George F. Handel", 1759, "Alemanha/Inglaterra", "Handel Messiah", "Messias (trecho instrumental)"),
    ("George F. Handel", 1759, "Alemanha/Inglaterra", "Handel Harpsichord Suite", "Suíte para Cravo"),
    ("Domenico Scarlatti", 1757, "Itália", "Scarlatti Sonata keyboard", "Sonata para Teclado"),
    ("Henry Purcell", 1695, "Inglaterra", "Purcell Trumpet Tune", "Trumpet Tune"),
    ("Arcangelo Corelli", 1713, "Itália", "Corelli Concerto Grosso Christmas", "Concerto Grosso de Natal"),
    ("Jean-Philippe Rameau", 1764, "França", "Rameau Suite harpsichord", "Suíte para Cravo"),
]

PIANO_ESTUDAR = [
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Nocturne piano", "Noturno"),
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Prelude piano", "Prelúdio"),
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Etude piano", "Estudo"),
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Waltz piano", "Valsa"),
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Mazurka piano", "Mazurca"),
    ("Franz Schubert", 1828, "Áustria", "Schubert Impromptu piano", "Impromptu"),
    ("Franz Schubert", 1828, "Áustria", "Schubert Moment Musical piano", "Momento Musical"),
    ("Franz Schubert", 1828, "Áustria", "Schubert Sonata piano", "Sonata para Piano"),
    ("Johannes Brahms", 1897, "Alemanha", "Brahms Intermezzo piano", "Intermezzo"),
    ("Gabriel Fauré", 1924, "França", "Faure Nocturne piano", "Noturno"),
    ("Gabriel Fauré", 1924, "França", "Faure Pavane", "Pavana"),
    ("Robert Schumann", 1856, "Alemanha", "Schumann Kinderszenen piano", "Cenas Infantis"),
    ("Robert Schumann", 1856, "Alemanha", "Schumann Traumerai piano", "Träumerei"),
    ("Franz Liszt", 1886, "Hungria", "Liszt Consolation piano", "Consolação"),
    ("Franz Liszt", 1886, "Hungria", "Liszt Liebestraum piano", "Liebestraum"),
    ("Felix Mendelssohn", 1847, "Alemanha", "Mendelssohn Songs Without Words piano", "Canção sem Palavras"),
]

PIANO_DORMIR = [
    ("Erik Satie", 1925, "França", "Satie Gymnopedie piano", "Gymnopédie"),
    ("Erik Satie", 1925, "França", "Satie Gnossienne piano", "Gnossienne"),
    ("Claude Debussy", 1918, "França", "Debussy Clair de Lune piano", "Clair de Lune"),
    ("Claude Debussy", 1918, "França", "Debussy Arabesque piano", "Arabesque"),
    ("Claude Debussy", 1918, "França", "Debussy Reverie piano", "Rêverie"),
    ("Claude Debussy", 1918, "França", "Debussy Prelude piano", "Prelúdio"),
    ("Maurice Ravel", 1937, "França", "Ravel Pavane piano", "Pavana para uma Infanta Defunta"),
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Nocturne Op 9 piano", "Noturno Op. 9"),
    ("Franz Schubert", 1828, "Áustria", "Schubert Ave Maria piano", "Ave Maria"),
    ("Johannes Brahms", 1897, "Alemanha", "Brahms Lullaby piano", "Canção de Ninar"),
    ("Robert Schumann", 1856, "Alemanha", "Schumann Album for the Young piano", "Álbum para a Juventude"),
    ("Felix Mendelssohn", 1847, "Alemanha", "Mendelssohn On Wings of Song piano", "Sobre Asas da Canção"),
    ("Franz Liszt", 1886, "Hungria", "Liszt Consolation No 3 piano", "Consolação nº 3"),
    ("Gabriel Fauré", 1924, "França", "Faure Sicilienne piano", "Siciliana"),
    ("Ludwig van Beethoven", 1827, "Alemanha", "Beethoven Moonlight Sonata piano", "Sonata ao Luar"),
]

CLASSICA_LEITURA = [
    ("Wolfgang A. Mozart", 1791, "Áustria", "Mozart Piano Sonata", "Sonata para Piano"),
    ("Wolfgang A. Mozart", 1791, "Áustria", "Mozart Eine kleine Nachtmusik", "Uma Pequena Serenata"),
    ("Wolfgang A. Mozart", 1791, "Áustria", "Mozart Clarinet Concerto adagio", "Concerto para Clarinete (adágio)"),
    ("Wolfgang A. Mozart", 1791, "Áustria", "Mozart Divertimento strings", "Divertimento para Cordas"),
    ("Joseph Haydn", 1809, "Áustria", "Haydn String Quartet Emperor", "Quarteto Imperador"),
    ("Joseph Haydn", 1809, "Áustria", "Haydn Surprise Symphony", "Sinfonia Surpresa"),
    ("Joseph Haydn", 1809, "Áustria", "Haydn Piano Sonata", "Sonata para Piano"),
    ("Ludwig van Beethoven", 1827, "Alemanha", "Beethoven Fur Elise piano", "Für Elise"),
    ("Ludwig van Beethoven", 1827, "Alemanha", "Beethoven Pathetique Sonata adagio", "Sonata Patética (adágio)"),
    ("Ludwig van Beethoven", 1827, "Alemanha", "Beethoven Romance violin", "Romanza para Violino"),
    ("Felix Mendelssohn", 1847, "Alemanha", "Mendelssohn Midsummer Night Dream", "Sonho de uma Noite de Verão"),
    ("Edvard Grieg", 1907, "Noruega", "Grieg Peer Gynt Morning", "Peer Gynt: Manhã"),
    ("Edvard Grieg", 1907, "Noruega", "Grieg Holberg Suite", "Suíte Holberg"),
    ("Edward Elgar", 1934, "Inglaterra", "Elgar Salut d Amour", "Salut d'Amour"),
    ("Camille Saint-Saëns", 1921, "França", "Saint-Saens Swan cello", "O Cisne"),
]

BRASIL = [
    ("Ernesto Nazareth", 1934, "Brasil", "Nazareth Odeon piano", "Odeon"),
    ("Ernesto Nazareth", 1934, "Brasil", "Nazareth Brejeiro piano", "Brejeiro"),
    ("Ernesto Nazareth", 1934, "Brasil", "Nazareth Apanhei-te cavaquinho", "Apanhei-te, Cavaquinho"),
    ("Chiquinha Gonzaga", 1935, "Brasil", "Chiquinha Gonzaga O Abre Alas", "Ó Abre Alas"),
    ("Chiquinha Gonzaga", 1935, "Brasil", "Chiquinha Gonzaga choro piano", "Choro"),
    ("Zequinha de Abreu", 1935, "Brasil", "Zequinha Abreu Tico-Tico no Fuba", "Tico-Tico no Fubá"),
    ("Joaquim Callado", 1880, "Brasil", "Callado choro flute", "Choro (Callado)"),
    ("Anacleto de Medeiros", 1907, "Brasil", "Anacleto Medeiros choro", "Choro (Anacleto)"),
    ("Carlos Gomes", 1896, "Brasil", "Carlos Gomes Guarani", "O Guarani"),
    ("Alberto Nepomuceno", 1920, "Brasil", "Nepomuceno piano", "Piano (Nepomuceno)"),
    ("Alexandre Levy", 1892, "Brasil", "Alexandre Levy piano", "Piano (Levy)"),
    ("Leopoldo Miguez", 1902, "Brasil", "Miguez symphony", "Sinfonia (Miguez)"),
    ("Francisco Braga", 1945, "Brasil", "Francisco Braga symphony", "Sinfonia (Braga)"),
    ("Glauco Velasquez", 1914, "Brasil", "Velasquez chamber music", "Música de Câmara"),
    ("Luciano Gallet", 1931, "Brasil", "Gallet piano", "Piano (Gallet)"),
    ("Henrique Oswald", 1931, "Brasil", "Oswald piano", "Piano (Oswald)"),
]

FOCO_PROFUNDO = [
    ("J. S. Bach", 1750, "Alemanha", "Bach Goldberg Variations aria", "Goldberg: Ária"),
    ("J. S. Bach", 1750, "Alemanha", "Bach Cello Suite prelude", "Suíte p/ Violoncelo: Prelúdio"),
    ("Erik Satie", 1925, "França", "Satie Gymnopedie No 1 piano", "Gymnopédie nº 1"),
    ("Claude Debussy", 1918, "França", "Debussy Clair de Lune piano", "Clair de Lune"),
    ("Frédéric Chopin", 1849, "Polônia", "Chopin Nocturne Op 9 No 2 piano", "Noturno Op. 9 nº 2"),
    ("Ludwig van Beethoven", 1827, "Alemanha", "Beethoven Moonlight Sonata first movement", "Sonata ao Luar (1º mov.)"),
    ("Wolfgang A. Mozart", 1791, "Áustria", "Mozart Piano Concerto 21 andante", "Concerto nº 21 (andante)"),
    ("Johann Pachelbel", 1706, "Alemanha", "Pachelbel Canon", "Cânone em Ré"),
    ("Antonio Vivaldi", 1741, "Itália", "Vivaldi Guitar Concerto largo", "Concerto p/ Violão (largo)"),
    ("Franz Schubert", 1828, "Áustria", "Schubert Ave Maria", "Ave Maria"),
    ("Johannes Brahms", 1897, "Alemanha", "Brahms Intermezzo Op 118 piano", "Intermezzo Op. 118"),
    ("Gabriel Fauré", 1924, "França", "Faure Pavane orchestra", "Pavana"),
    ("Maurice Ravel", 1937, "França", "Ravel Pavane infante defunte", "Pavana p/ Infanta Defunta"),
    ("Edvard Grieg", 1907, "Noruega", "Grieg Peer Gynt Solveig song", "Canção de Solveig"),
    ("Camille Saint-Saëns", 1921, "França", "Saint-Saens Aquarium Carnival Animals", "Aquário (Carnaval dos Animais)"),
]

CATS = {
    "barroco": BARROCO,
    "piano_estudar": PIANO_ESTUDAR,
    "piano_dormir": PIANO_DORMIR,
    "classica_leitura": CLASSICA_LEITURA,
    "brasil": BRASIL,
    "foco_profundo": FOCO_PROFUNDO,
}

_last = [0.0]
INTERVAL = 2.5


def api(params, retries=6):
    for i in range(retries):
        w = INTERVAL - (time.time() - _last[0])
        if w > 0:
            time.sleep(w)
        try:
            r = S.get(API, params=params, timeout=40)
            _last[0] = time.time()
            if r.status_code == 429:
                ra = r.headers.get("Retry-After")
                time.sleep(min(float(ra), 30) if ra else 8)
                continue
            if r.status_code in (500, 502, 503):
                time.sleep(4 * (i + 1))
                continue
            r.raise_for_status()
            return r.json()
        except Exception:
            if i == retries - 1:
                return {}
            time.sleep(2 * (i + 1))
    return {}


def strip(s):
    return "".join(c for c in unicodedata.normalize("NFD", s)
                   if unicodedata.category(c) != "Mn").lower()


def slugify(s):
    return re.sub(r"[^A-Za-z0-9]+", "_", strip(s)).strip("_")


def is_pd(lic, licurl):
    label = strip(lic).replace("_", " ").strip()
    if label in {strip(item) for item in PD_LICENSES}:
        return True
    url = licurl.lower().rstrip("/")
    return any(marker in url for marker in (
        "creativecommons.org/publicdomain/zero/",
        "creativecommons.org/publicdomain/mark/",
    ))


def search_audio(query, limit=15):
    d = api({"action": "query", "format": "json", "generator": "search",
             "gsrsearch": f"{query} filetype:audio", "gsrnamespace": 6,
             "gsrlimit": limit, "prop": "imageinfo",
             "iiprop": "url|size|mime|extmetadata|metadata"})
    out = []
    for p in d.get("query", {}).get("pages", {}).values():
        ii = (p.get("imageinfo") or [{}])[0]
        url = ii.get("url", "")
        if not url:
            continue
        ext = os.path.splitext(url.split("?")[0])[1].lower()
        if ext not in AUDIO_EXT:
            continue
        title = p.get("title", "")
        tl = strip(title)
        if any(w in tl for w in SKIP_WORDS):
            continue
        meta = ii.get("extmetadata", {})
        lic = meta.get("LicenseShortName", {}).get("value", "")
        licurl = meta.get("LicenseUrl", {}).get("value", "")
        dur = 0
        for m in ii.get("metadata", []) or []:
            if m.get("name") in ("length", "duration", "playtime_seconds"):
                try:
                    dur = float(m.get("value", 0))
                except (TypeError, ValueError):
                    pass
        artist = re.sub(r"<[^>]+>", "", meta.get("Artist", {}).get("value", "")).strip()
        out.append({"title": title, "url": url, "ext": ext,
                    "size": ii.get("size", 0), "dur": dur,
                    "license": lic, "licurl": licurl, "artist": artist,
                    "descurl": ii.get("descriptionurl", ""),
                    "pd": is_pd(lic, licurl)})
    return out


def pick(cands):
    pd_ok = [c for c in cands if c["pd"] and c["size"] >= MIN_BYTES and c["dur"] >= MIN_DUR]
    pd_ok.sort(key=lambda c: c["dur"], reverse=True)
    if pd_ok:
        return pd_ok[0], None
    if cands:
        return None, f"sem licenca PD/CC0 ({len(cands)} achados, ex.: {cands[0]['title'][:60]})"
    return None, "nada encontrado"


def download(url, dest, retries=5):
    last = RuntimeError("falha no download")
    for i in range(retries):
        try:
            with S.get(url, timeout=300, stream=True) as r:
                if r.status_code == 429:
                    ra = r.headers.get("Retry-After")
                    time.sleep(min(float(ra), 120) if ra else 30)
                    continue
                r.raise_for_status()
                with open(dest, "wb") as f:
                    for chunk in r.iter_content(256 * 1024):
                        if chunk:
                            f.write(chunk)
            return
        except Exception as e:
            last = e
            if os.path.exists(dest):
                os.remove(dest)
            time.sleep(10 * (i + 1))
    raise last


def to_mp3(src, dst, title, artist, album):
    cmd = ["ffmpeg", "-y", "-v", "error", "-i", src,
           "-codec:a", "libmp3lame", "-b:a", TARGET_BITRATE,
           "-metadata", f"title={title}",
           "-metadata", f"artist={artist}",
           "-metadata", f"album={album}",
           dst]
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
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return {"faixas": [], "faltas": []}


def save_catalog(cat):
    with open(os.path.join(BASE, "CATALOGO.json"), "w", encoding="utf-8") as f:
        json.dump(cat, f, ensure_ascii=False, indent=2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", type=int, default=15)
    ap.add_argument("--only", default=None)
    ap.add_argument("--report", action="store_true")
    args = ap.parse_args()

    os.makedirs(BASE, exist_ok=True)
    catalog = load_catalog()
    have_keys = {(t["categoria"], t["slug"]) for t in catalog["faixas"]}
    cats = [args.only] if args.only else list(CATS)

    if args.report:
        print(f"Faltas registradas: {len(catalog['faltas'])}")
        for f in catalog["faltas"]:
            print(f"  [{f['categoria']}] {f['compositor']} — {f['obra']}: {f['motivo']}")
        return

    for cat in cats:
        outdir = os.path.join(BASE, cat)
        os.makedirs(outdir, exist_ok=True)
        items = CATS[cat][:args.target]
        print(f"\n=== {cat} ({len(items)} obras) ===", flush=True)
        for comp, morte, pais, query, obra in items:
            slug = slugify(f"{comp}_{obra}")
            if (cat, slug) in have_keys:
                continue
            cands = search_audio(query)
            cand, falta = pick(cands)
            if not cand:
                catalog["faltas"].append({"categoria": cat, "compositor": comp,
                                         "obra": obra, "query": query,
                                         "motivo": falta or "nada encontrado",
                                         "verificado_em": date.today().isoformat()})
                print(f"  -- FALTA: {comp} — {obra} ({falta})", flush=True)
                save_catalog(catalog)
                continue
            # Keep the source separate even when the remote file is already MP3.
            tmp = os.path.join(outdir, "." + slug + ".source" + cand["ext"])
            dst = os.path.join(outdir, slug + ".mp3")
            if os.path.exists(dst) and os.path.getsize(dst) >= MIN_BYTES:
                have_keys.add((cat, slug))
                continue
            try:
                if not os.path.exists(tmp):
                    download(cand["url"], tmp)
                    time.sleep(20)
                dur = to_mp3(tmp, dst, f"{comp} — {obra}", comp, cat)
                if dur < MIN_DUR:
                    raise ValueError(f"faixa curta demais ({dur:.0f}s < {MIN_DUR}s)")
                if os.path.exists(tmp) and tmp != dst:
                    os.remove(tmp)
            except Exception as e:
                print(f"  -- ERRO: {comp} — {obra} ({str(e)[:120]})", flush=True)
                catalog["faltas"].append({"categoria": cat, "compositor": comp,
                                         "obra": obra, "query": query,
                                         "motivo": f"erro: {str(e)[:200]}",
                                         "verificado_em": date.today().isoformat()})
                save_catalog(catalog)
                for junk in (dst,):
                    if os.path.exists(junk):
                        os.remove(junk)
                continue
            catalog["faixas"].append({
                "categoria": cat, "compositor": comp, "morte": morte, "pais": pais,
                "obra": obra, "slug": slug, "arquivo": f"{cat}/{slug}.mp3",
                "duracao_s": round(dur, 1), "duracao_min": round(dur / 60, 1),
                "interprete": cand["artist"] or "desconhecido",
                "licenca": cand["license"], "licenca_url": cand["licurl"],
                "fonte_arquivo": cand["title"], "fonte_url": cand["descurl"],
                "verificado_em": date.today().isoformat()})
            have_keys.add((cat, slug))
            save_catalog(catalog)
            print(f"  [+] {slug}.mp3  {dur/60:.1f}min  PD:{cand['license']}", flush=True)

    print("\n=== RESUMO ===")
    for cat in cats:
        n = sum(1 for t in catalog["faixas"] if t["categoria"] == cat)
        print(f"  {cat}: {n} faixas")


if __name__ == "__main__":
    main()
