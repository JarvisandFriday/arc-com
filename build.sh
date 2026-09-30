#!/usr/bin/env bash
# Read-only, polite mirror of the public pages of www.arcsuspension.in (GET only, 1s between requests,
# no login/cart/checkout/account/admin URLs), then turn it into a static TEST COPY in ./_site
set -euo pipefail
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36 ARC-test-copy"
mkdir -p work && cd work
curl -fsS -A "$UA" -o sitemap.xml https://www.arcsuspension.in/sitemap.xml
grep -o '<loc>[^<]*</loc>' sitemap.xml | sed 's/<[^>]*>//g' | grep -vE '/(login|register)$' > urls.txt
echo "URLs: $(wc -l < urls.txt)"
mkdir -p mirror && cd mirror
wget -i ../urls.txt -p -k -E -H \
  -D www.arcsuspension.in,arcsuspension.in,fonts.googleapis.com,fonts.gstatic.com,cdn.jsdelivr.net \
  --wait=1 -Q 2000m -e robots=off \
  --reject-regex '(login|register|logout|cart|checkout|account|wishlist|admin|vendors|captcha)' \
  -U "$UA" --restrict-file-names=windows -nv -o ../wget.log || true
cd ../..
python3 postprocess.py work/mirror _site
du -sh _site; find _site -type f | wc -l
