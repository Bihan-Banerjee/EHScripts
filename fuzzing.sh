TARGET=$1

echo "[*] Running Gobuster for directory enumeration..."
gobuster dir -u http://$TARGET -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -t 100 -o gobuster_dirs.txt

echo "[*] Parameter fuzzing with ffuf..."
ffuf -u http://$TARGET/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt -mc all -o ffuf_results.txt
