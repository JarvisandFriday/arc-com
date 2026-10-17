#!/usr/bin/env python3
"""Non-destructive offline audit of a generated ARC static preview."""
import argparse, collections, pathlib, re, sys
p=argparse.ArgumentParser()
p.add_argument("site",type=pathlib.Path)
p.add_argument("--expected-pages",type=int,default=581)
a=p.parse_args()
root=a.site
files=[f for f in root.rglob("*") if f.is_file()]
html=[f for f in files if f.suffix.lower()==".html" and f.name!="404.html"]
phones=collections.Counter()
bad=[]
for f in files:
    if f.suffix.lower() not in (".html",".js",".json",".css",".xml",".txt"):continue
    t=f.read_text(encoding="utf-8",errors="replace")
    phones.update(re.findall(r"(?<!\d)[6-9]\d{9}(?!\d)",t))
    if "9922099292" in t:bad.append(str(f.relative_to(root)))
print("HTML pages (excl. 404):",len(html),"target:",a.expected_pages)
print("File count:",len(files),"bytes:",sum(f.stat().st_size for f in files))
print("Phone candidates:",dict(phones))
print("Legacy number files:",bad)
missing_noindex=[str(f.relative_to(root)) for f in html if 'noindex' not in f.read_text(encoding="utf-8",errors="replace").lower()]
print("Missing noindex:",missing_noindex[:30],"count:",len(missing_noindex))
robots=root/"robots.txt"
safe=robots.exists() and "Disallow: /" in robots.read_text()
print("Robots disallow all:",safe)
if bad or missing_noindex or not safe or any(n not in {"9595940959","9422047019"} for n in phones):sys.exit(1)
