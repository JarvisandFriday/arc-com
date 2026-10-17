#!/usr/bin/env bash
# Read-only public mirror of www.arcsuspension.in for an unpublished static preview.
# No robots bypass; no administration, form submissions or dynamic commerce endpoints.
set -euo pipefail
UA="ARC-static-preview/1.0 (+https://arcsuspension.com; public GET only)"
mkdir -p work
cd work
curl --fail --silent --show-error --location -A "$UA" -o robots-source.txt https://www.arcsuspension.in/robots.txt
curl --fail --silent --show-error --location -A "$UA" -o sitemap.xml https://www.arcsuspension.in/sitemap.xml
python3 - <<'PY'
import re,urllib.parse,urllib.robotparser,xml.etree.ElementTree as ET
ua='ARC-static-preview'
rp=urllib.robotparser.RobotFileParser()
rp.set_url('https://www.arcsuspension.in/robots.txt')
rp.read()
root=ET.parse('sitemap.xml').getroot()
urls=[]
for elem in root.iter():
    if elem.tag.split('}')[-1]!='loc' or not elem.text: continue
    u=elem.text.strip()
    x=urllib.parse.urlsplit(u)
    if x.hostname not in ('www.arcsuspension.in','arcsuspension.in'): continue
    p=x.path.lower().rstrip('/')
    if re.search(r'/(login|register|logout|cartview|cart|checkout|account|wishlist|search|admin|vendors|includes|payment|captcha|ajax)(/|$)',p) or p.endswith('.php'): continue
    if not rp.can_fetch(ua,u): continue
    urls.append(u)
with open('urls.txt','w') as f: f.write('\n'.join(dict.fromkeys(urls))+'\n')
print('Approved sitemap URLs:',len(set(urls)))
PY
mkdir -p mirror
cd mirror
# Wget respects robots by default; explicitly enable it and avoid POST/form endpoints.
wget -i ../urls.txt -p -k -E -H \
  -D www.arcsuspension.in,arcsuspension.in,fonts.googleapis.com,fonts.gstatic.com,cdn.jsdelivr.net \
  --wait=1 --random-wait --execute robots=on --execute robots=1 \
  -Q 2000m --reject-regex '(login|register|logout|cartview|cart|checkout|account|wishlist|admin|vendors|includes|payment|captcha|/ajax/|searchdatalist|\.php([?]|$))' \
  -U "$UA" --restrict-file-names=windows -nv -o ../wget.log || true
cd ../..
python3 postprocess.py work/mirror _site
du -sh _site
find _site -type f | wc -l
