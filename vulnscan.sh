TARGET=$1

echo "[*] Launching OpenVAS (GVM) scan..."
gvm-start
gvm-cli socket --gmp-username admin --gmp-password 'YourPass' \
  --xml "<create_target><name>Test</name><hosts>$TARGET</hosts></create_target>"

echo "[*] Nessus alternative scan with Nuclei..."
nuclei -l targets.txt -t cves,misconfiguration -o nuclei_results.txt
