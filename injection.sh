TARGET=$1

echo "[*] Scanning $TARGET for injection points with SQLMap..."
sqlmap -u "$TARGET" --batch --level=5 --risk=3 --crawl=3 --random-agent --output-dir=sqlmap_results

echo "[*] Testing command injection with commix..."
commix --url="$TARGET" --batch --all

echo "[*] Finished injection scan on $TARGET"
