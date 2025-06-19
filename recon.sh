TARGET=$1

echo "[*] Running Passive Recon on $TARGET"
theHarvester -d $TARGET -b all -f ${TARGET}_harvest.html
subfinder -d $TARGET -silent > ${TARGET}_subs.txt
amass enum -passive -d $TARGET >> ${TARGET}_subs.txt

echo "[*] Fetching historical URLs..."
cat ${TARGET}_subs.txt | waybackurls > ${TARGET}_wayback.txt

echo "[*] DNS Reconnaissance..."
dnsenum $TARGET -o ${TARGET}_dnsenum.xml

echo "[*] Output saved to: ${TARGET}_recon/"
mkdir -p ${TARGET}_recon && mv ${TARGET}_* ${TARGET}_recon/
