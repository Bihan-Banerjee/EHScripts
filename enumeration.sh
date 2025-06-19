TARGET=$1

echo "[*] Running Nmap Enumeration on $TARGET"
nmap -sC -sV -O -T4 -oA ${TARGET}_nmap $TARGET

echo "[*] Checking for SMB shares..."
smbclient -L //$TARGET -N

echo "[*] Enum4linux run..."
enum4linux -a $TARGET > ${TARGET}_enum4linux.txt

echo "[*] Nikto web server enumeration..."
nikto -host http://$TARGET -output ${TARGET}_nikto.txt

mkdir -p ${TARGET}_enum && mv ${TARGET}_* ${TARGET}_enum/
