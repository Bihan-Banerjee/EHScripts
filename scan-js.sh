#!/bin/bash

input=$1  # file containing domains or subdomains (1 per line)
mkdir -p js_scan_output secrets

echo "[*] Extracting JavaScript URLs from $input ..."
while read domain; do
    echo "[*] Fetching JS files from: $domain"
    waybackurls "$domain" | grep '\.js$' >> js_scan_output/wayback-js.txt
    hakrawler -subs -u "https://$domain" -d 2 | grep '\.js' >> js_scan_output/hakrawler-js.txt
done < "$input"

sort -u js_scan_output/*.txt > js_scan_output/all-js-urls.txt
echo "[+] Collected $(wc -l < js_scan_output/all-js-urls.txt) unique JS URLs."

# Run gf patterns
echo "[*] Running GF patterns (tokens, xss, idor, interestingparams)..."
cat js_scan_output/all-js-urls.txt | gf tokens > secrets/tokens.txt
cat js_scan_output/all-js-urls.txt | gf xss > secrets/xss.txt
cat js_scan_output/all-js-urls.txt | gf idor > secrets/idor.txt
cat js_scan_output/all-js-urls.txt | gf interestingparams > secrets/params.txt

# SecretFinder
echo "[*] Running SecretFinder on live JS files..."
for js in $(cat js_scan_output/all-js-urls.txt); do
    python3 SecretFinder/SecretFinder.py -i "$js" -o cli >> secrets/secretfinder-output.txt
done

# TruffleHog
echo "[*] Scanning JS URLs with TruffleHog..."
for js_url in $(cat js_scan_output/all-js-urls.txt); do
    curl -s "$js_url" -o temp.js
    trufflehog filesystem temp.js --no-update > "secrets/truffle_$(basename $js_url | tr '/' '_').txt"
done
rm -f temp.js

echo "[✔] JavaScript scan complete. Results in ./secrets/"
