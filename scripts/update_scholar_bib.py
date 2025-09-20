#!/usr/bin/env python3
import sys, time, re, yaml
from pathlib import Path

# Unofficial Google Scholar scraper
from scholarly import scholarly

ROOT = Path(__file__).resolve().parents[1]
BIB_PATH = ROOT / "publications.bib"
DESC_PATH = ROOT / "pub-descriptions.yml"

SCHOLAR_USER_ID = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
if not SCHOLAR_USER_ID:
    print("Usage: update_scholar_bib.py <SCHOLAR_USER_ID>")
    sys.exit(1)

def slugify(s):
    return re.sub(r'[^a-z0-9]+', '', s.lower())

def bibkey_from_pub(pub):
    b = pub.get("bib", {})
    authors = b.get("author", "")
    first_last = authors.split(" and ")[0].split()[-1] if authors else "unknown"
    year = b.get("pub_year", "n.d.")
    title = b.get("title", "")[:40]
    return f"{slugify(first_last)}{year}{slugify(title)}"

def to_bibtex(pub, annote=None):
    b = pub.get("bib", {})
    typ = b.get("pub_type", "article").lower()
    if typ not in {"article","inproceedings","book","phdthesis","mastersthesis"}:
        typ = "article"
    key = bibkey_from_pub(pub)
    fields = {
        "author": b.get("author"),
        "title": b.get("title"),
        "journal": b.get("venue"),             # journal / proceedings / venue
        "year": b.get("pub_year"),
        "volume": b.get("volume"),
        "number": b.get("number"),
        "pages": b.get("pages"),
        "doi": b.get("doi"),
        "url": pub.get("pub_url"),
        "eprint": b.get("eprint"),
    }
    lines = [f"@{typ}{{{key},"]
    for k, v in fields.items():
        if v:
            lines.append(f"  {k} = {{{v}}},")
    if annote:
        lines.append(f"  annote = {{{annote}}},")
    lines.append("}")
    return key, "\n".join(lines)

def main():
    try:
        desc = yaml.safe_load(DESC_PATH.read_text(encoding="utf-8")) if DESC_PATH.exists() else {}
    except Exception:
        desc = {}

    author = scholarly.search_author_id(SCHOLAR_USER_ID)
    author = scholarly.fill(author, sections=['publications'])

    entries = []
    for p in author['publications']:
        pub = scholarly.fill(p)
        key = bibkey_from_pub(pub)
        annote = desc.get(key)
        _, entry = to_bibtex(pub, annote)
        entries.append(entry)
        time.sleep(0.5)  # be gentle to the site

    BIB_PATH.write_text("\n\n".join(entries) + "\n", encoding="utf-8")
    print(f"Wrote {len(entries)} entries to {BIB_PATH}")

if __name__ == "__main__":
    main()
