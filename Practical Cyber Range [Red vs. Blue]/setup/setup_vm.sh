#!/bin/bash

# 1. Error Handling (Memastikan skrip dijalankan sebagai root)
if [ "$EUID" -ne 0 ]; then
  echo "[!] Tolong jalankan skrip ini sebagai root (gunakan sudo)"
  exit
fi

echo "[*] Memulai Provisioning VM untuk Lab CTF..."

# 2. Install Dependencies (Docker & SSH Server)
apt-get update -y
apt-get install -y docker.io docker-compose openssh-server

# 3. Create Blue Team SSH User & Configure Custom Port (Metode Aman Skrip 1)
useradd -m -s /bin/bash analyst
echo "analyst:blue_team_rocks" | chpasswd

if ! grep -q "^Port 2275" /etc/ssh/sshd_config; then
    echo "Port 2275" >> /etc/ssh/sshd_config
    systemctl restart sshd
fi

# 4. Create Log Forensics Directory
mkdir -p /opt/admin/logs
chmod 755 /opt/admin/logs

# 5. Generate Mock Telemetry & Log Forensics (Metode Here-Doc Skrip 2 + Base64 Valid)
# -- NGINX-Style Access Logs --
cat << 'EOF' > /opt/admin/logs/access.log
192.168.1.100 - - [02/Jul/2026:18:45:00 +0700] "GET / HTTP/1.1" 200 - "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "-"
10.10.14.50 - - [01/Jul/2026:18:48:10 +0700] "GET /robots.txt HTTP/1.1" 200 - "Mozilla/5.0" "-"
10.10.14.50 - - [01/Jul/2026:18:50:15 +0700] "POST /submit HTTP/1.1" 403 - "Mozilla/5.0" "-"
10.10.14.50 - - [01/Jul/2026:18:51:55 +0700] "GET /dashboard HTTP/1.1" 200 - "Mozilla/5.0" "X-Forwarded-For: UEhBTlRPTUdSSUR7QkxVRV9MMGdfSHVudDNyX000c3Qzcn0="
EOF

# -- Application Error Logs (Threat Hunting & IR) --
cat << 'EOF' > /opt/admin/logs/error.log
[01/Jul/2026:18:50:15 +0700] [error] [client 10.10.14.50] WAF Blocked <script> tag detected in payload.
[01/Jul/2026:18:53:10 +0700] [CRITICAL] Authentication bypass anomaly: User session accessed /dashboard without hitting /api/verify-mfa.
EOF

# 6. Manajemen Hak Akses File (Read-Only untuk Analyst)
chmod 644 /opt/admin/logs/access.log
chmod 644 /opt/admin/logs/error.log

# 7. Start the CTF Environment (Error Handling Docker Skrip 1)
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
    echo "[*] Lab CTF berhasil dijalankan!"
else
    echo "[!] File docker-compose.yml tidak ditemukan di direktori ini. Lewati step Docker."
fi
